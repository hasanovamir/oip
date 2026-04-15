import RPi.GPIO as GPIO

class R2R_DAC:
    def __init__ (self, gpio_bits, dynamic_rang, verbose = False):
        self.gpio_bits = gpio_bits
        self.dynamic_range = dynamic_range
        self.verbose = verbose

        GPIO.setmode (GPIO.BCM)
        GPIO.setup (self.gpoi_bita, GPIO.OUT, initial = 0)

    def deinit (self):
        GPIO.output (self.gpio_bits, 0)
        GPIO.cleanup ()

    def set_number (self, number):
        if number < 0:
            number = 0
        elif number > 255:
            number = 255
        
        for i in range (8):
            bit_value = (number >> i) & 1
            GPIO.output (self.gpio_bits[i], bit_value)

    def set_voltage (self, voltage):
        if not (0.0 <= voltage <= self.dynamic_range):
            if (self.verbose):
                print (f"out of range")
                print ("set 0.0B")
            number = 0

        else:
            number = int (voltage / self.dynamic_range * 255)

        self.set_number(number)

if __name__ == "__main__":
    try:
        dac = R2R_DAC ([22, 27, 17, 26, 25, 21, 20, 16], 3.183, True)

        while True:
            try:
                voltage = float (input("Enter:"))
                dac.set_voltage(voltage)

            except ValueError:
                print ("Not number")

    except KeyboardInterrupt:
        print ("program stopped")

    finally:
        dac.deinit()