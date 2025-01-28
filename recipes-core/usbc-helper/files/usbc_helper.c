/*****************************************************************************/
/**
 * @file: usb_helper.c
 *
 * Kludgy script to handle Oxygen USB-C mux and controller.
 *
 * Parts of this are stripped directly from newer versions of the gpiod
 * library (look at the function comments) which is licensed as LGPL, so
 * this file is marked as GPLv3.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <gpiod.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>
#include <poll.h>
#include <signal.h>
#include <sys/signalfd.h>


#include <linux/i2c-dev.h>
#include <i2c/smbus.h>


#define CONFIG_FILE "/etc/usbc-helper.conf"
#define SYSFS_OVERLAY_DIR "/sys/kernel/config/device-tree/overlays/usb"
#define GPIO_CHIP "1"
#define GPIO_CONSUMER "usbc-helper"
#define GPIO_PIN_ID 27
#define I2C_BUS 1
#define I2C_ADDR_USB3_PORT_CTL 0x47

#define MODE_HOST 0
#define MODE_DEVICE 1
#define MODE_OTG_HOST 2
#define MODE_OTG_DEV 3

static int mode;
static struct gpiod_chip *gpio_chip;
static struct gpiod_line_bulk gpio_bulk_vbus;

/******************************************************************************
 * @brief Print usage for the application.
 *
 * @param prg Program name.
 *****************************************************************************/
static void
print_usage(char *prg)
{
    fprintf(stderr, "Handles USB-C for Oxygen board\n\n");
    fprintf(stderr, "Usage: %s -m mode\n", prg);
    fprintf(stderr, "\n");
    fprintf(stderr, "Optional Parameters:\n");
    fprintf(stderr, "  -m <mode>    Mode to run USB-C. This can be one of "
            "the following:\n");
    fprintf(stderr, "      host     : Host mode only\n");
    fprintf(stderr, "      device   : Device Mode only\n");
    fprintf(stderr, "      otg_host : OTG with host preference (Default)\n");
    fprintf(stderr, "      otg_dev  : OTG with device preference\n");
}


/******************************************************************************
 * @brief Loads the devicetree overlay specified.
 *
 * @param devicetree String containing the devictree to overlay.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
load_devicetree(char *devicetree)
{
    FILE *fp;

    rmdir(SYSFS_OVERLAY_DIR);
    mkdir(SYSFS_OVERLAY_DIR, 0755);

    fp = fopen(SYSFS_OVERLAY_DIR "/path", "w");
    if (!fp) {
        fprintf(stderr, "Could not load host devicetree\n");
        return -1;
    }

    fprintf(fp, "%s", devicetree);
    fclose(fp);
    return 0;
}


/******************************************************************************
 * @brief Create a file descriptor to monitor SIGTERM and SIGINT.
 *
 * This was copied directly from gpiomon.c.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
make_signalfd(void)
{
    sigset_t sigmask;
    int sigfd;
    int rv;

    sigemptyset(&sigmask);
    sigaddset(&sigmask, SIGTERM);
    sigaddset(&sigmask, SIGINT);

    rv = sigprocmask(SIG_BLOCK, &sigmask, NULL);
    if (rv < 0)
        return rv;

    sigfd = signalfd(-1, &sigmask, 0);

    return sigfd;
}


/******************************************************************************
 * @brief Setup GPIO lines to their default values.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
setup_gpio(void)
{
    unsigned int offsets_vbus[1] = {109};
    int values_vbus[1] = {0};
    int rc;

    gpio_chip = gpiod_chip_open_lookup(GPIO_CHIP);
    if (!gpio_chip)
        return -1;

    rc = gpiod_chip_get_lines(
        gpio_chip,
        offsets_vbus,
        1,
        &gpio_bulk_vbus);
    if (rc < 0) {
        gpiod_chip_close(gpio_chip);
        return rc;
    }

    rc = gpiod_line_request_bulk_output(
        &gpio_bulk_vbus, GPIO_CONSUMER, values_vbus);
    if (rc < 0) {
        gpiod_chip_close(gpio_chip);
        return rc;
    }

    return 0;
}


/******************************************************************************
 * @brief Closes the GPIO device.
 *****************************************************************************/
static void
close_gpio(void)
{
    gpiod_chip_close(gpio_chip);
}


/******************************************************************************
 * @brief Set value of v-bus pin.
 *
 * @param value Value to set v-bus.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
set_vbus(int value)
{
    int rc;

    rc = gpiod_line_set_value_bulk(&gpio_bulk_vbus, &value);
    if (rc != 0) {
        fprintf(stderr, "Failed to set v-bus!\n");
    }
    return rc;
}


/******************************************************************************
 * @brief Callback for polling GPIO 'ID' line.
 *
 * This is almost a direct copy of the poll handler in gpiomon.
 *
 * @param num_lines Number of GPIO pins being monitored.
 * @param fds File descriptors for the GPIO pins being monitored.
 * @param timeout Timeout to be used for polling.
 * @param data Private data containing signal file descriptor.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
poll_callback(
    unsigned int num_lines,
    struct gpiod_ctxless_event_poll_fd *fds,
    const struct timespec *timeout,
    void *data)
{
    struct pollfd pfds[num_lines + 1];
    int *sigfd = (int *)data;
    int cnt;
    int ts;
    int rv;
    unsigned int i;

    for (i = 0; i < num_lines; i++) {
        pfds[i].fd = fds[i].fd;
        pfds[i].events = POLLIN | POLLPRI;
    }

    pfds[i].fd = *sigfd;
    pfds[i].events = POLLIN | POLLPRI;

    ts = timeout->tv_sec * 1000 + timeout->tv_nsec / 1000000;

    cnt = poll(pfds, num_lines + 1, ts);
    if (cnt < 0)
        return GPIOD_CTXLESS_EVENT_POLL_RET_ERR;
    else if (cnt == 0)
        return GPIOD_CTXLESS_EVENT_POLL_RET_TIMEOUT;

    rv = cnt;
    for (i = 0; i < num_lines; i++) {
        if (pfds[i].revents) {
            fds[i].event = true;
            if (!--cnt)
                return rv;
        }
    }

    return GPIOD_CTXLESS_EVENT_POLL_RET_STOP;
}


/******************************************************************************
 * @brief Callback that is executed when an edge occurs on the 'ID' pin.
 *
 * This is based on the callback handler in gpiomon.
 *
 * @param event_type Type of event. Either Rising or Falling edge.
 * @param line_offset Unused offset for the line.
 * @param timestamp Unused event timestamp.
 * @param data Unused private data.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
event_callback(
    int event_type,
    unsigned int line_offset,
    const struct timespec *timestamp,
    void *data)
{
    (void)data;
    (void)line_offset;
    (void)timestamp;

    switch (event_type) {
    case GPIOD_CTXLESS_EVENT_CB_RISING_EDGE:
    case GPIOD_CTXLESS_EVENT_CB_FALLING_EDGE:
        break;
    default:
        return GPIOD_CTXLESS_EVENT_CB_RET_OK;
    }

    /*@todo This should read the ID value from the USB-C controller to ensure
            that something changed. This could occur when the FPGA is reloaded.
    */

    set_vbus(0);

    switch(mode) {
    case MODE_OTG_HOST:
    case MODE_OTG_DEV:
        if (event_type == GPIOD_CTXLESS_EVENT_CB_RISING_EDGE) {
            load_devicetree((char *) "rwt/usb-peripheral.dtbo");
        } else {
            load_devicetree((char *) "rwt/usb-host.dtbo");
        }
        break;

    case MODE_HOST:
    case MODE_DEVICE:
    default:
        break;
    }

    switch(mode) {
    case MODE_HOST:
    case MODE_OTG_HOST:
    case MODE_OTG_DEV:
        if (event_type == GPIOD_CTXLESS_EVENT_CB_FALLING_EDGE) {
            sleep(1);
            set_vbus(1);
        }
        break;
    case MODE_DEVICE:
    default:
        break;
    }

    return GPIOD_CTXLESS_EVENT_CB_RET_OK;
}


/******************************************************************************
 * @brief Write multiple bytes to a given I2C device.
 *
 * @param i2cbus i2c bus to use.
 * @param dev_addr Address of the I2C slave.
 * @param reg_addrs Array of address to write.
 * @param reg_values Array of values to write.
 * @param num_regs The number of registers to write.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
static int
i2c_write_bytes(
    int i2cbus,
    int dev_addr,
    uint8_t *reg_addrs,
    uint8_t *reg_values,
    int num_regs)
{
    char filename[20];
    int fd;
    int rc;
    int i;

    sprintf(filename, "/dev/i2c-%d", i2cbus);

    fd = open(filename, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "Error: Could not open file %s: %s\n",
                filename, strerror(ENOENT));
        return fd;
    }

    rc = ioctl(fd, I2C_SLAVE, dev_addr);
    if (rc < 0) {
        fprintf(stderr,
            "Error: Could not set address to 0x%02x: %s\n",
            dev_addr, strerror(errno));
        close(fd);
        return -errno;
    }

    for (i = 0; i < num_regs; i++)
    {
        rc = i2c_smbus_write_byte_data(fd, reg_addrs[i], reg_values[i]);
        if (rc < 0) {
            fprintf(
                stderr,
                "Error: Failed to write i2c register: "
                "dev=%02x, addr=%02x, value=%02x\n",
                dev_addr, reg_addrs[i], reg_values[i]);
        }
    }

    close(fd);
    return 0;
}


/******************************************************************************
 * @brief Setup the I2C devices to use USB-C connector.
 *****************************************************************************/
static void
set_usbc_mode(void)
{
    uint8_t mode_mask;
    uint8_t reg_addrs[3];
    uint8_t reg_values[3];

    switch (mode) {
    case MODE_HOST:
        mode_mask = 0x20;
        break;
    case MODE_DEVICE:
        mode_mask = 0x10;
        break;
    case MODE_OTG_HOST:
        mode_mask = 0x06;
        break;
    case MODE_OTG_DEV:
    default:
        mode_mask = 0x02;
        break;
    }

    reg_addrs[0] = 0x0a;
    reg_addrs[1] = 0x0a;
    reg_addrs[2] = 0x0a;

    reg_values[0] = 0x01;
    reg_values[1] = 0x01 | mode_mask;
    reg_values[2] = 0x00 | mode_mask;

    i2c_write_bytes(
        I2C_BUS,
        I2C_ADDR_USB3_PORT_CTL,
        reg_addrs,
        reg_values,
        3);

}


/******************************************************************************
 * @brief Converts mode string to integer value.
 *
 * @param value Mode string.
 *
 * @returns mode on success or -1 on failure.
 *****************************************************************************/
static int
str_to_mode(char *value)
{
    int ret = -1;

    if (strcmp(value, "host") == 0) {
        ret = MODE_HOST;
    } else if (strcmp(value, "device") == 0) {
        ret = MODE_DEVICE;
    } else if (strcmp(value, "otg_host") == 0) {
        ret = MODE_OTG_HOST;
    } else if (strcmp(value, "otg_dev") == 0) {
        ret = MODE_OTG_DEV;
    }

    return ret;
}


/******************************************************************************
 * @brief Simple config file parser.
 *****************************************************************************/
static void
read_config(void)
{
    FILE *fp;
    char *line = NULL;
    ssize_t nread;
    size_t len = 0;
    char *token;
    int ret;

    fp = fopen(CONFIG_FILE, "r");
    if (!fp) {
        return;
    }

    while ((nread = getline(&line, &len, fp)) != -1) {
        token = strtok(line, "=:#\n\r\t");
        if (strcmp(token, "mode") == 0) {
            token = strtok(NULL, "=:#\n\r\t");

            ret = str_to_mode(token);
            if (ret < 0) {
                fprintf(stderr, "Invalid mode in config: '%s'\n", token);
            } else {
                mode = ret;
            }
        }
    }

    if (line) {
        free(line);
    }
    fclose(fp);
}


/******************************************************************************
 * @brief Main entry point.
 *
 * @param argc Number of arguments.
 * @param argv Array of arguments.
 *
 * @returns 0 on success. <0 on failure.
 *****************************************************************************/
int
main(int argc, char **argv)
{
    char *mode_arg = NULL;
    int opt;
    struct timespec timeout = { 10, 0 };
    int sigfd;

    mode = MODE_OTG_HOST;

    read_config();

    while ((opt = getopt(argc, argv, "m:h")) != -1) {
        switch (opt) {
        case 'm':
            mode_arg = optarg;
            break;
        case '?':
        case 'h':
        default:
            print_usage(argv[0]);
            return 1;
            break;
        }
    }

    if (mode_arg != NULL) {
        mode = str_to_mode(mode_arg);
        if (mode < 0) {
            fprintf(stderr, "Invalid mode: %s\n", mode_arg);
            fprintf(stderr, "See help for details\n");
            return 1;
        }
    }

    printf("Running in mode: ");
    switch(mode) {
    case MODE_HOST:
        printf("host");
        break;
    case MODE_DEVICE:
        printf("device");
        break;
    case MODE_OTG_HOST:
        printf("otg_host");
        break;
    case MODE_OTG_DEV:
    default:
        printf("otg_dev");
        break;
    }
    printf("\n");

    /* Create signal file descriptor to catch SIGINT and SIGTERM. */
    sigfd = make_signalfd();
    if (sigfd < 0) {
        fprintf(stderr, "Failed to create signalfd: %d\n", sigfd);
        return 1;
    }

    /* Cleanup any old overlays. */
    rmdir(SYSFS_OVERLAY_DIR);

    /* Setup GPIO's for controlling USB-2 switches and v-bus. */
    if (!setup_gpio())
        close_gpio();


    /* Setup mode on USB-C controller. */
    set_usbc_mode();

    /* Load device tree. Host is only loaded if explicitly in host mode. Any
       other mode sets it up in device mode first. */
    if (mode == MODE_HOST) {
        load_devicetree((char *) "rwt/usb-host.dtbo");
    } else {
        load_devicetree((char *) "rwt/usb-peripheral.dtbo");
    }

    /* Loops forever waiting for changes on the 'ID' pin. The loop is
       broken when SIGINT or SIGTERM is caught. */
    gpiod_ctxless_event_loop(
        GPIO_CHIP,
        GPIO_PIN_ID,
        false,
        GPIO_CONSUMER,
        &timeout,
        poll_callback,
        event_callback,
        &sigfd);

    /* Cleanup */
    close(sigfd);

    return 0;
}
