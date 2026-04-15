import RPi.GPIO as GPIO

# dac = [16, 20, 21, 25, 26, 17, 27, 22]
dac = [22, 27, 17, 26, 25, 21, 20, 16]
GPIO.setmode (GPIO.BCM)
for pin in dac:
    GPIO.setup (pin, GPIO.OUT)
    GPIO.output (pin, 0)

dynamic_range = 3.2

def VoltageToNumber (voltage):
    if not (0.0 <= voltage <= dynamic_range):
        print (f"Напряжение выходит за динамический диапазон ЦАП (0ю00 - {dynamic_range:.2f}В)")
        print ("Устанавливаем 0.0В")
        return 0
    return int (voltage / dynamic_range * 255)

def dec2bin (value):
    return [int (element) for element in bin (value)[2:].zfill (8)]

def number_to_dac (number):
    if number < 0:
        number = 0
    elif number > 255:
        number = 255

    for i in range (8):
        GPIO.output (dac[i], 0)
    
    for i in range (8):
        bit_value = (number >> i) & 1
        GPIO.output (dac[i], bit_value)

try:
    while True:
        try:
            voltage = float (input ("Введите напряжение в Вольтах: "))
            number = VoltageToNumber (voltage)
            number_to_dac (number)

        except ValueError:
            print ("Вы ввели не число. Попробуйте еще раз\n")
    
finally:
    GPIO.output (dac, 0)
    GPIO.cleanup ()