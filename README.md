# HiPi

## Specifications
TODO

## Software
Hipi board use a SPI to UART component (sc16is752) to communicate with Dynamixels motors.
To use the HiPi board on a Raspberry Pi, you have to install and configure a driver.
### Quick setup
You can install the drivers, and the starup script of the HiPi with this command:
```
curl https://raw.githubusercontent.com/poppy-project/HiPi/master/install_hipi.sh | sudo bash
```
After a reboot, you will be able to comunicate with the motors on:
- /dev/ttySC0 for TTL1 and RS4851 Hipi output
- /dev/ttySC1 for TTL2 and RS4852 Hipi output

### Detailed instructions
**Without** the install script, you can do it by hand:
- you need to add the [sc16is752 overlay](https://github.com/poppy-project/HiPi/releases/download/0.1/sc16is752-spi.dtbo) in /boot/overlays
- you need to add the overlay configuration `dtoverlay=sc16is752-spi,clkrate=32000000,irqpin=13` in /boot/config.txt
- due to Hipi hardware, you need to open serial ports /dev/ttySC0 and /dev/ttySC1 (serial ports of the HiPi board) in RS485 mode (whatever TTL or RS485 Hipi output you want to use). It can be done one time at startup and the configuration will stay afterwards. 

This snippet will open and close /dev/ttySC0 and /dev/ttySC1 ports in RS485 mode:
```python
import serial.rs485
ser = serial.Serial('/dev/ttySC0', 1000000, timeout=0.5)
ser.rs485_mode = serial.rs485.RS485Settings(rts_level_for_tx=False, rts_level_for_rx=True, delay_before_tx=0, delay_before_rx=0)

ser2 = serial.Serial('/dev/ttySC1', 1000000, timeout=0.5)
ser2.rs485_mode = serial.rs485.RS485Settings(rts_level_for_tx=False, rts_level_for_rx=True, delay_before_tx=0, delay_before_rx=0)

```
If you use the [Hipi install script](https://raw.githubusercontent.com/poppy-project/HiPi/master/install_hipi.sh) the snippet above is called at Raspberry Pi startup, so the RS485 configuration is already registered.
