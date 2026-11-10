#!/bin/sh
# USB network gadget (NCM) set up through configfs, with jumbo frames.
#
# Compared with the legacy g_ncm module this can announce a larger maximum frame size
# (max_segment_size, Linux 6.7+), so the host's cdc_ncm / Windows UsbNcm driver allows an MTU above
# 1500, and every setting (MACs, qmult, strings) is explicit. Written for Linux 6.12 (any 6.7+ works;
# older kernels run it with standard 1514-byte frames).
#
# Commands (run as root on the device):
#   usb-gadget-configfs up               create the gadget and bind it to the USB controller
#   usb-gadget-configfs down             unbind and remove it
#   usb-gadget-configfs status           show what is active
#   usb-gadget-configfs switch <host-ip> move from a legacy gadget module (g_ncm / g_ether) to this one
#                                        safely; run it detached, see below
#   usb-gadget-configfs legacy <host-ip> move back to the legacy g_ncm module (same safety net)
#
# "switch" and "legacy" keep the MAC addresses and IPv4 setup, let NetworkManager re-activate the
# connection (or set the addresses directly), restart a standalone dnsmasq, and if the host doesn't
# answer pings within TIMEOUT seconds they undo the change. Run them detached so the SSH session
# dropping doesn't stop them:
#
#   nohup setsid sh usb-gadget-configfs.sh switch <host-ip> > /tmp/usb-gadget.log 2>&1 &
#
# Settings come from /etc/default/usb-gadget (shell variables, see usb-gadget.conf) or the
# environment. "switch" writes that file with the current MAC addresses if it doesn't exist yet.
#
# POSIX sh (works with BusyBox). Needs: modprobe, ip, ping, awk; nmcli if NetworkManager is used.

set -u
CONF=${CONF:-/etc/default/usb-gadget}
# shellcheck disable=SC1090
[ -r "$CONF" ] && . "$CONF"

GADGET=${GADGET:-ncm}
CFS=${CFS:-/sys/kernel/config}
G=$CFS/usb_gadget/$GADGET
FUNC=ncm.usb0
VENDOR_ID=${VENDOR_ID:-0x1d6b}          # Linux Foundation
PRODUCT_ID=${PRODUCT_ID:-0x0103}        # NCM (Ethernet) gadget, as g_ncm uses
DEVICE_BCD=${DEVICE_BCD:-0x0100}
MANUFACTURER=${MANUFACTURER:-Linux}
PRODUCT=${PRODUCT:-NCM network gadget}
SERIAL=${SERIAL:-$(cut -c1-16 /etc/machine-id 2>/dev/null || echo 0123456789)}
DEV_MAC=${DEV_MAC:-}
HOST_MAC=${HOST_MAC:-}
QMULT=${QMULT:-15}
MTU=${MTU:-9000}
SEGMENT=${SEGMENT:-$((MTU + 14))}       # Ethernet frame size = MTU + 14-byte header
IFACE=${IFACE:-usb0}
TIMEOUT=${TIMEOUT:-60}
LEGACY=${LEGACY:-g_ncm}

log() { echo "$(date '+%H:%M:%S') $*"; }
die() { log "ERROR: $*"; exit 1; }
need_root() { [ "$(id -u)" = 0 ] || die "run as root"; }
wr() { echo "$2" > "$1" 2>/dev/null || { log "  could not write '$2' to $1"; return 1; }; }

# ------------------------------------------------------------------ gadget up / down / status

mount_configfs() {
    grep -q " $CFS configfs " /proc/mounts || mount -t configfs none "$CFS" 2>/dev/null
    modprobe libcomposite 2>/dev/null
    modprobe usb_f_ncm 2>/dev/null
    [ -d "$CFS/usb_gadget" ] || die "no $CFS/usb_gadget: the kernel needs CONFIG_USB_CONFIGFS and CONFIG_USB_CONFIGFS_NCM"
}

udc_name() {
    if [ -n "${UDC_NAME:-}" ]; then echo "$UDC_NAME"; return; fi
    ls /sys/class/udc 2>/dev/null | head -n1
}

# 02:xx:xx:xx:xx:xx from a hash of the machine ID (or serial) and $1, empty if no hash tool exists.
stable_mac() {
    id=$( (cat /etc/machine-id 2>/dev/null || echo "$SERIAL") | head -n1)
    h=$(printf '%s-%s' "$id" "$1" | md5sum 2>/dev/null | cut -c1-10)
    [ ${#h} -eq 10 ] || return 0
    echo "02:$(echo "$h" | sed 's/\(..\)/\1:/g; s/:$//')"
}

gadget_up() {
    need_root
    mount_configfs
    if [ -d "$G" ] && [ -n "$(cat "$G/UDC" 2>/dev/null)" ]; then log "gadget '$GADGET' is already up"; return 0; fi
    # The USB controller driver may still be probing at boot.
    i=0; while [ -z "$(udc_name)" ] && [ $i -lt 20 ]; do sleep 1; i=$((i + 1)); done
    udc=$(udc_name); [ -n "$udc" ] || die "no USB device controller in /sys/class/udc"
    [ -n "$(cat /sys/class/udc/"$udc"/function 2>/dev/null)" ] && die "$udc is in use (a legacy gadget module loaded?)"

    mkdir -p "$G" || die "cannot create $G"
    wr "$G/idVendor" "$VENDOR_ID"; wr "$G/idProduct" "$PRODUCT_ID"; wr "$G/bcdDevice" "$DEVICE_BCD"
    mkdir -p "$G/strings/0x409"
    wr "$G/strings/0x409/manufacturer" "$MANUFACTURER"
    wr "$G/strings/0x409/product" "$PRODUCT"
    wr "$G/strings/0x409/serialnumber" "$SERIAL"
    mkdir -p "$G/configs/c.1/strings/0x409"
    wr "$G/configs/c.1/strings/0x409/configuration" "NCM"
    wr "$G/configs/c.1/MaxPower" 250

    # Without configured MACs the kernel picks random ones at every boot (a new host interface name
    # and DHCP lease each time): derive stable, locally administered ones from the machine ID instead.
    [ -n "$DEV_MAC" ] || DEV_MAC=$(stable_mac dev)
    [ -n "$HOST_MAC" ] || HOST_MAC=$(stable_mac host)

    F=$G/functions/$FUNC
    mkdir -p "$F" || die "cannot create function $FUNC (is usb_f_ncm available?)"
    # Everything below must be set before the function is linked and the gadget bound.
    [ -n "$DEV_MAC" ] && wr "$F/dev_addr" "$DEV_MAC"
    [ -n "$HOST_MAC" ] && wr "$F/host_addr" "$HOST_MAC"
    [ -f "$F/qmult" ] && wr "$F/qmult" "$QMULT"
    if [ -f "$F/max_segment_size" ]; then
        wr "$F/max_segment_size" "$SEGMENT" || log "  max_segment_size $SEGMENT refused; frames stay at $(cat "$F/max_segment_size")"
    else
        log "  this kernel has no max_segment_size (needs Linux 6.7+): frames stay at 1514 bytes"
    fi
    [ -e "$G/configs/c.1/$FUNC" ] || ln -s "$F" "$G/configs/c.1/" || die "cannot link $FUNC into the configuration"
    wr "$G/UDC" "$udc" || die "cannot bind to $udc"

    ifn=$(cat "$F/ifname" 2>/dev/null)
    i=0; while [ ! -d "/sys/class/net/$ifn" ] && [ $i -lt 10 ]; do sleep 1; i=$((i + 1)); done
    seg=$(cat "$F/max_segment_size" 2>/dev/null || echo 1514)
    want=$((seg - 14)); [ "$want" -gt "$MTU" ] && want=$MTU
    ip link set "$ifn" mtu "$want" 2>/dev/null || log "  could not set the MTU of $ifn to $want"
    log "gadget '$GADGET' up on $udc: interface $ifn, MTU $(cat /sys/class/net/"$ifn"/mtu 2>/dev/null), frames up to $seg bytes, qmult $(cat "$F/qmult" 2>/dev/null)"
}

gadget_down() {
    need_root
    [ -d "$G" ] || { log "gadget '$GADGET' is not set up"; return 0; }
    [ -n "$(cat "$G/UDC" 2>/dev/null)" ] && echo "" > "$G/UDC"
    rm -f "$G/configs/c.1/$FUNC"
    rmdir "$G/configs/c.1/strings/0x409" "$G/configs/c.1" "$G/functions/$FUNC" "$G/strings/0x409" "$G" 2>/dev/null
    [ -d "$G" ] && die "could not remove $G completely"
    log "gadget '$GADGET' removed"
}

gadget_status() {
    for m in g_ncm g_ether g_multi g_cdc; do [ -d /sys/module/$m ] && echo "legacy gadget module loaded: $m"; done
    if [ ! -d "$G" ]; then echo "configfs gadget '$GADGET': not set up"; return; fi
    F=$G/functions/$FUNC
    udc=$(cat "$G/UDC" 2>/dev/null)
    ifn=$(cat "$F/ifname" 2>/dev/null)
    echo "configfs gadget '$GADGET': bound to ${udc:-nothing}"
    [ -n "$udc" ] && echo "  link speed: $(cat /sys/class/udc/"$udc"/current_speed 2>/dev/null)"
    echo "  interface: $ifn, MTU $(cat /sys/class/net/"$ifn"/mtu 2>/dev/null)"
    echo "  max_segment_size: $(cat "$F/max_segment_size" 2>/dev/null || echo n/a), qmult: $(cat "$F/qmult" 2>/dev/null)"
    echo "  device MAC: $(cat "$F/dev_addr" 2>/dev/null), host MAC: $(cat "$F/host_addr" 2>/dev/null)"
}

# ------------------------------------------------------------------ safe switching

HOST_IP=""
NM_CONN=""; NM_OLD_MTU=""; ADDRS=""; ROUTES=""; DHCP_FILE=/tmp/usb-gadget.dhcp; DHCP_NAMES=""

remember_network() {
    ADDRS=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet /{print $2}')
    ROUTES=$(ip route show dev "$IFACE" 2>/dev/null | grep -v "proto kernel" | grep -v "scope link")
    if command -v nmcli >/dev/null 2>&1; then
        NM_CONN=$(nmcli -g GENERAL.CONNECTION device show "$IFACE" 2>/dev/null)
        [ "$NM_CONN" = "--" ] && NM_CONN=""
        case "$(nmcli -g GENERAL.STATE device show "$IFACE" 2>/dev/null)" in *external*) NM_CONN="" ;; esac
        [ -n "$NM_CONN" ] && NM_OLD_MTU=$(nmcli -g 802-3-ethernet.mtu connection show "$NM_CONN" 2>/dev/null)
    fi
    # Standalone DHCP/DNS servers (not NetworkManager's own) to restart afterwards.
    : > $DHCP_FILE
    for name in dnsmasq udhcpd dhcpd; do
        for pid in $(pidof $name 2>/dev/null); do
            ppid=$(awk '{print $4}' /proc/"$pid"/stat 2>/dev/null)
            [ "$(cat /proc/"$ppid"/comm 2>/dev/null)" = "NetworkManager" ] && continue
            tr '\000' ' ' < /proc/"$pid"/cmdline >> $DHCP_FILE && echo >> $DHCP_FILE
            DHCP_NAMES="$DHCP_NAMES $name"
        done
    done
    [ -n "$ADDRS" ] || die "no IPv4 address on $IFACE; refusing to continue"
    log "  $IFACE: $(echo $ADDRS); NetworkManager: ${NM_CONN:-none}${NM_CONN:+ (MTU setting ${NM_OLD_MTU:-auto})}; DHCP/DNS to restart:${DHCP_NAMES:- none}"
}

restore_network() { # $1 = MTU for the NetworkManager connection ("" = leave)
    i=0; while [ ! -d /sys/class/net/"$IFACE" ] && [ $i -lt 30 ]; do sleep 1; i=$((i + 1)); done
    [ -d /sys/class/net/"$IFACE" ] || { log "  $IFACE did not appear"; return 1; }
    if [ -n "$NM_CONN" ]; then
        # NetworkManager shows an automatic MTU as "auto"; it is set back as 0.
        nm_mtu=$1; [ "$nm_mtu" = auto ] && nm_mtu=0
        [ -n "$nm_mtu" ] && nmcli connection modify "$NM_CONN" 802-3-ethernet.mtu "$nm_mtu" >/dev/null 2>&1
        i=0
        while [ $i -lt 40 ]; do
            case "$(nmcli -g GENERAL.STATE device show "$IFACE" 2>/dev/null)" in 100*) break ;; esac
            if [ $((i % 8)) -eq 2 ]; then nmcli connection up "$NM_CONN" ifname "$IFACE" >/dev/null 2>&1; fi
            sleep 1; i=$((i + 1))
        done
    fi
    case "$(nmcli -g GENERAL.STATE device show "$IFACE" 2>/dev/null)" in
        100*) log "  NetworkManager: $IFACE connected ($NM_CONN)" ;;
        *)
            [ -n "$NM_CONN" ] && log "  NetworkManager did not connect $IFACE; setting the addresses directly"
            ip link set "$IFACE" up
            for a in $ADDRS; do ip addr add "$a" dev "$IFACE" 2>/dev/null; done
            echo "$ROUTES" | while read -r r; do [ -n "$r" ] && ip route add $r dev "$IFACE" 2>/dev/null; done
            ;;
    esac
    # Restart standalone DHCP/DNS servers so they serve the new interface.
    if [ -n "$DHCP_NAMES" ]; then
        if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet dnsmasq 2>/dev/null; then
            log "  systemctl restart dnsmasq"; systemctl restart dnsmasq
        else
            for name in $DHCP_NAMES; do killall "$name" 2>/dev/null; done
            sleep 1
            while read -r cmd; do
                [ -n "$cmd" ] || continue
                log "  restarting: $cmd"; setsid sh -c "exec $cmd" < /dev/null > /dev/null 2>&1 &
            done < $DHCP_FILE
            sleep 1
        fi
    fi
    return 0
}

wait_host() {
    t=0
    while [ $t -lt "$TIMEOUT" ]; do
        ping -c 1 -W 1 "$HOST_IP" >/dev/null 2>&1 && return 0
        sleep 1; t=$((t + 2))
    done
    return 1
}

legacy_loaded() { for m in g_ncm g_ether g_multi g_cdc; do [ -d /sys/module/$m ] && { echo $m; return; }; done; }

param() { v=$(cat /sys/module/"$1"/parameters/"$2" 2>/dev/null); [ -n "$v" ] && [ "$v" != "(null)" ] && echo "$v"; return 0; }

load_legacy() { # module
    modprobe "$1" dev_addr="$DEV_MAC" ${HOST_MAC:+host_addr=$HOST_MAC} qmult="${LEGACY_QMULT:-$QMULT}"
}

write_conf() {
    [ -e "$CONF" ] && return 0
    mkdir -p "$(dirname "$CONF")"
    cat > "$CONF" <<EOF
# Settings for usb-gadget-configfs (written by "switch" on $(date '+%Y-%m-%d')).
DEV_MAC=$DEV_MAC
HOST_MAC=$HOST_MAC
QMULT=$QMULT
MTU=$MTU
EOF
    log "  wrote $CONF with the MAC addresses (keep it: they keep the host's interface name and DHCP lease)"
}

switch_to_configfs() {
    need_root
    HOST_IP=${1:?usage: $0 switch <host-ip>}
    mod=$(legacy_loaded); [ -n "$mod" ] || die "no legacy gadget module loaded; use 'up' instead"
    [ -d /sys/class/net/"$IFACE" ] || die "no interface $IFACE (set IFACE=...)"
    DEV_MAC=${DEV_MAC:-$(cat /sys/class/net/"$IFACE"/address)}
    HOST_MAC=${HOST_MAC:-$(param "$mod" host_addr)}
    LEGACY_QMULT=$(param "$mod" qmult)
    log "switching $mod -> configfs NCM (MTU $MTU) on $IFACE; device MAC $DEV_MAC, host MAC ${HOST_MAC:-unknown}"
    [ -n "$HOST_MAC" ] || log "  WARNING: host-side MAC unknown, so it will change; pass HOST_MAC=... to keep it"
    remember_network
    sleep 2 # let SSH print the above before the link goes away
    rmmod "$mod" || die "rmmod $mod failed; nothing changed"
    if (gadget_up) && restore_network "$MTU" && wait_host; then
        log "OK: configfs NCM gadget is up and $HOST_IP answers"
        gadget_status
        write_conf
        log "  To keep it: stop loading $mod at boot, and enable usb-gadget.service (see scripts/device/README.md)."
        exit 0
    fi
    log "host $HOST_IP not reachable within ${TIMEOUT}s; switching back to $mod"
    (gadget_down)
    load_legacy "$mod" || die "could not reload $mod; a reboot restores the original setup"
    restore_network "${NM_OLD_MTU:-auto}"
    if wait_host; then log "rolled back to $mod; $HOST_IP answers"; exit 2; fi
    log "rolled back to $mod, but $HOST_IP still doesn't answer"
    exit 3
}

switch_to_legacy() {
    need_root
    HOST_IP=${1:?usage: $0 legacy <host-ip>}
    [ -d "$G" ] || die "the configfs gadget isn't set up"
    F=$G/functions/$FUNC
    IFACE=$(cat "$F/ifname" 2>/dev/null || echo "$IFACE")
    DEV_MAC=${DEV_MAC:-$(cat "$F/dev_addr")}; HOST_MAC=${HOST_MAC:-$(cat "$F/host_addr")}
    log "switching configfs NCM -> $LEGACY on $IFACE"
    remember_network
    sleep 2
    gadget_down
    if load_legacy "$LEGACY" && restore_network 1500 && wait_host; then log "OK: $LEGACY is up and $HOST_IP answers"; exit 0; fi
    log "host $HOST_IP not reachable; switching back to configfs"
    rmmod "$LEGACY" 2>/dev/null
    (gadget_up) && restore_network "${NM_OLD_MTU:-$MTU}"
    wait_host && { log "back on configfs; $HOST_IP answers"; exit 2; }
    exit 3
}

case "${1:-}" in
    up) gadget_up ;;
    down) gadget_down ;;
    status) gadget_status ;;
    switch) shift; switch_to_configfs "$@" ;;
    legacy) shift; switch_to_legacy "$@" ;;
    *) echo "usage: $0 up | down | status | switch <host-ip> | legacy <host-ip>"; exit 1 ;;
esac
