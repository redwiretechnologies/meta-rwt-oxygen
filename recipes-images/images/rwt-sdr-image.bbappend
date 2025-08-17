IMAGE_INSTALL:append = "kernel-dev kernel-devsrc kernel-modules"
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
    python3-bokeh \
    gr-ieee80211 \
    gr-foo \
    gr-adsb \
    gr-mesa \
    gr-satellites \
    gr-pager \
    gr-mesa \
    gr-lora-sdr \
    gr-air-modes \
    gr-ais \
    python3-pybind11 \
    python3-typing-extensions \
    python3-construct \
    python3-matplotlib \
    device-tree-oxygen \
    python3-gunicorn \
"
