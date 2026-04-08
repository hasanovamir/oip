import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)

leds = [24, 22, 23, 27, 17, 25, 12, 16]

GPIO.setup(leds, GPIO.OUT)
GPIO.output(leds, 0)

up = 9
down = 10

GPIO.setup(up, GPIO.IN)
GPIO.setup(down, GPIO.IN)

num = 0

def dec2bin(value):
    return [int(element) for element in bin(value)[2:].zfill(8)]

sleep_time = 0.2

while True:
    up_st = GPIO.input(up)
    down_st = GPIO.input(down)

    if up_st and down_st:
        num = 255
        print(num, dec2bin(num))
        time.sleep(sleep_time)
    elif up_st:
        num += 1
        if (num > 255):
            num = 0
        print(num, dec2bin(num))
        time.sleep(sleep_time)
    elif down_st:
        num -= 1
        if (num < 0):
            num = 255
        print(num, dec2bin(num))
        time.sleep(sleep_time)

    GPIO.output(leds, dec2bin(num))