import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)

led = 26

GPIO.setup(led, GPIO.OUT)

govno = 6

GPIO.setup(govno, GPIO.IN)

while True:
    sensor_value = GPIO.input(govno)
    GPIO.output(led, not sensor_value)
    time.sleep(0.05)