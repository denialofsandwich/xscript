#!/bin/bash

# Make sure enough parameters are passed in
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <pwm_chip> <shutdown_pin> <boot_pin>"
  exit 1
fi

GPIOCHIP=$1
SHUTDOWN=$2
BOOT=$3

# Checks if the passed parameters got the correct format
re='^\/dev\/gpiochip[0-9\.]+$'
if ! [[ $GPIOCHIP =~ $re ]]; then
  echo "error: gpio_chip is not a path" >&2
  exit 1
fi

re='^GPIO[0-9\.]+$'
if ! [[ $SHUTDOWN =~ $re ]]; then
  echo "error: shutdown_pin is invalid" >&2
  exit 1
fi

if ! [[ $BOOT =~ $re ]]; then
  echo "error: button_pin is invalid" >&2
  exit 1
fi

REBOOTPULSEMINIMUM=200
REBOOTPULSEMAXIMUM=600

# Initialize the BOOT pin to 1
gpioset -c "$GPIOCHIP" -p 1s -t 0 "$BOOT=1"

echo "Successfully started"

while true; do
  shutdownSignal=$(gpioget -c "$GPIOCHIP" --numeric "$SHUTDOWN")
  if [ "$shutdownSignal" -eq 0 ]; then
    sleep 0.2
  else
    pulseStart=$(date +%s%N | cut -b1-13)
    while [ "$shutdownSignal" -eq 1 ]; do
      sleep 0.02
      if [ $(($(date +%s%N | cut -b1-13) - $pulseStart)) -gt $REBOOTPULSEMAXIMUM ]; then
        echo "Your device is shutting down on pin $SHUTDOWN, halting Rpi ..."
        sudo poweroff
        exit
      fi
      shutdownSignal=$(gpioget -c "$GPIOCHIP" --numeric "$SHUTDOWN")
    done
    if [ $(($(date +%s%N | cut -b1-13) - $pulseStart)) -gt $REBOOTPULSEMINIMUM ]; then
      echo "Your device is rebooting on pin $SHUTDOWN, recycling Rpi ..."
      sudo reboot
      exit
    fi
  fi
done
