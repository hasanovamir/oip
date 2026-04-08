import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)

led_pin = 26

GPIO.setup(led_pin, GPIO.OUT)

pwm = GPIO.PWM(led_pin, 200)

duty = 0.0

pwm.start(duty)

while True:
    pwm.ChangeDutyCycle(duty)
    time.sleep(0.05)
    duty+=1.0
    if duty >= 100.0:
        duty = 0.0