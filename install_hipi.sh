#!/bin/sh
 set -e
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo" 1>&2
   exit 1
fi

setup_overlay(){
  # Download sc16is752 overlay in Raspberry Pi overlays folder
  wget --quiet https://github.com/show0k/HiPi/releases/download/0.1/sc16is752-spi.dtbo -O /boot/overlays/sc16is752-spi.dtbo

  # sc16is752 overlay activation and configuration
  sc16is752_overlay="dtoverlay=sc16is752-spi,clkrate=32000000,irqpin=13"
  config_file=/boot/config.txt
  if ! grep -q "$sc16is752_overlay" "$config_file" ; then
    echo -e "Adding sc16is752-spi overlay configuration ..."

    cat >> "$config_file" << EOF
# Hipi SPI to UART driver
$sc16is752_overlay
EOF

  else
    echo -e "sc16is752-spi overlay is already configured"
  fi

}

install_pyserial(){
  # Pip is installed by default in Raspbian Jessie but not in Whezzy or Jessie lite
  pip=/usr/bin/pip
  if [ ! -f "$pip" ]; then
    echo -e "Install pip"
    apt-get update
    apt-get install --yes python-pip
  fi

  # Install pyserial
  echo -e "Install pyserial"
  "$pip" install pyserial --upgrade

}

hipi_startup_script(){

  # Startup script to enable RS485
hipi_script=/usr/local/bin/hipi_enable_rs485.py
if [ ! -f "$hipi_script" ]; then
  echo -e "Add Hipi startup script ..."

  cat > "$hipi_script" << EOF
#!/usr/bin/python
import serial.rs485
ser = serial.Serial('/dev/ttySC0', 1000000, timeout=0.5)
ser.rs485_mode = serial.rs485.RS485Settings(rts_level_for_tx=False, rts_level_for_rx=True, delay_before_tx=0, delay_before_rx=0)

ser2 = serial.Serial('/dev/ttySC1', 1000000, timeout=0.5)
ser2.rs485_mode = serial.rs485.RS485Settings(rts_level_for_tx=False, rts_level_for_rx=True, delay_before_tx=0, delay_before_rx=0)

ser.close()
ser2.close()
EOF


  else
    echo -e "Hipi startup script already exist."

  fi

  # Create a systemd service for starting this script at system startup
  hipi_service=/lib/systemd/system/hipi.service

  if [ ! -f "$hipi_service" ]; then
    echo -e "Add Hipi service ..."
    cat > "$hipi_service" << EOF
[Unit]
Description=HiPi staring script
After=multi-user.target

[Service]
Type=idle
ExecStart=/usr/bin/python "$hipi_script"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable hipi.service
  else
    echo -e "Hipi service already exist."
  fi
}

setup_overlay
install_pyserial
hipi_startup_script
