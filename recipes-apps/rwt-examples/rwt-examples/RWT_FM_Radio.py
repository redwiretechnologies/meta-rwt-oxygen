#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Red Wire Technologies FM Demo
# Author: Toby Flynn
# Copyright: 2021 Red Wire Technologies
# GNU Radio version: 3.8.3.1

from distutils.version import StrictVersion

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print("Warning: failed to XInitThreads()")

from gnuradio import analog
from gnuradio import blocks
from gnuradio import gr
from gnuradio.filter import firdes
import sys
import signal
from PyQt5 import Qt
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import zeromq
from gnuradio.qtgui import Range, RangeWidget
import rwt
import pmt

from gnuradio import qtgui

class RWT_FM_Radio(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "Red Wire Technologies FM Demo")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("Red Wire Technologies FM Demo")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "RWT_FM_Radio")

        try:
            if StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
                self.restoreGeometry(self.settings.value("geometry").toByteArray())
            else:
                self.restoreGeometry(self.settings.value("geometry"))
        except:
            pass

        ##################################################
        # Variables
        ##################################################
        self.volume = volume = .2
        self.samp_rate = samp_rate = 192000
        self.frequency = frequency = 107.7

        ##################################################
        # Blocks
        ##################################################
        self._volume_range = Range(0.2, 2, 0.1, .2, 200)
        self._volume_win = RangeWidget(self._volume_range, self.set_volume, 'Volume', "counter_slider", float)
        self.top_layout.addWidget(self._volume_win)
        self._frequency_range = Range(87, 108, .1, 107.7, 200)
        self._frequency_win = RangeWidget(self._frequency_range, self.set_frequency, 'frequency', "counter_slider", float)
        self.top_layout.addWidget(self._frequency_win)
        self.zeromq_pub_sink_0 = zeromq.pub_sink(gr.sizeof_float, 1, 'tcp://192.168.10.1:50010', 100, False, -1)
        self.rwt_source_0 = None
        fmcomms_cfg = {
          "rx_freq": str(int(frequency*1e6)),
          "rx_bw": str(int(int(4e5))),
          "samplerate": str(int(samp_rate)),
          "rx_rfport1": "A_BALANCED",
          "rx_rfport2": "A_BALANCED",
          "escape": str(0xAAAAAAAAAAAAAAAA),
          "rx_gain1": str(32.0),
          "rx_gain1_mode": "manual",
          "rx_gain2": str(32.0),
          "rx_gain2_mode": "manual",
          "quadrature": str(int(True)),
          "rfdc": str(int(True)),
          "bbdc": str(int(True)),
          "decimation_arbitrary": str(int(0)),
          "correction_enable": str(int(True)),
          "bypass_enable": str(int(False)),
        }
        fmcomms_extra = {} if '' == "" else dict(x.split('=') for x in ''.split(','))
        fmcomms_cfg.update(fmcomms_extra)
        self.rwt_source_0 = rwt.rwt_source(
          pmt.to_pmt(fmcomms_cfg), True, False,
          0x9D000000, '', True, True,
          False, 32000)
        self.blocks_multiply_const_xx_0 = blocks.multiply_const_ff(volume, 1)
        self.analog_fm_demod_cf_0 = analog.fm_demod_cf(
        	channel_rate=samp_rate,
        	audio_decim=4,
        	deviation=75000,
        	audio_pass=16000,
        	audio_stop=20000,
        	gain=1.0,
        	tau=75e-6,
        )


        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_fm_demod_cf_0, 0), (self.blocks_multiply_const_xx_0, 0))
        self.connect((self.blocks_multiply_const_xx_0, 0), (self.zeromq_pub_sink_0, 0))
        self.connect((self.rwt_source_0, 0), (self.analog_fm_demod_cf_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "RWT_FM_Radio")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_volume(self):
        return self.volume

    def set_volume(self, volume):
        self.volume = volume
        self.blocks_multiply_const_xx_0.set_k(self.volume)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.rwt_source_0.set_config("samplerate", str(int(self.samp_rate)))

    def get_frequency(self):
        return self.frequency

    def set_frequency(self, frequency):
        self.frequency = frequency
        self.rwt_source_0.set_config("rx_freq", str(int(self.frequency*1e6)))





def main(top_block_cls=RWT_FM_Radio, options=None):

    if StrictVersion("4.5.0") <= StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()

    tb.start()

    tb.show()

    def sig_handler(sig=None, frame=None):
        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    def quitting():
        tb.stop()
        tb.wait()

    qapp.aboutToQuit.connect(quitting)
    qapp.exec_()

if __name__ == '__main__':
    main()
