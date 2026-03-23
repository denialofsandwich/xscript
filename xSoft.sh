#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <pwm_chip> <button_pin>" >&2
  exit 1
fi

GPIOCHIP=$1
BUTTON=$2

re='^\/dev\/gpiochip[0-9\.]+$'
if ! [[ $GPIOCHIP =~ $re ]]; then
  echo "error: gpio_chip is not a path" >&2
  exit 1
fi

re='^GPIO[0-9\.]+$'
if ! [[ $BUTTON =~ $re ]]; then
  echo "error: button_pin is invalid" >&2
  exit 1
fi

echo "Triggering shutdown..."
gpioset -c "$GPIOCHIP" -p 2s -t 0 "$BUTTON=1"
gpioset -c "$GPIOCHIP" -t 0 "$BUTTON=0"
