include conf/machine/include/xilinx-wic.inc

CORE_IMAGE_EXTRA_INSTALL += "\
    bitfiles-default \
    bitfiles-griio \
    bitfiles-default-chan \
    misc-gether-files \
    usbc-helper \
    rngd-reboot \
    base-files \
    pciutils \
    dtc \
    rwt-examples \
    python3-setuptools \
    python3-pyadi-iio \
    python3-pybind11 \
    python3-colorama \
    python3-typing-extensions \
    python3-construct \
    python3-matplotlib \
    device-tree-oxygen \
    python3-gunicorn \
    kernel-devsrc \
    cryptsetup \
    sudo \
    connection \
    gnuradio4-control-plane \
    gnuradio4-blocks \
    soapysdr \
"
