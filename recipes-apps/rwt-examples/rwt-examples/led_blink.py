#!/usr/bin/env python3
import os
import time

for i in range(78, 78+12):
    os.system("gpioset 0 {}=0".format(i))

for i in range(78, 78+12):
    os.system("gpioset 0 {}=1".format(i))
    time.sleep(0.2)
    os.system("gpioset 0 {}=0".format(i))
    time.sleep(0.2)
