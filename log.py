import math

def normal_log2(num):
    return math.log2(num)

def get_lut(entry_bits, bits):
    step = 1/2**entry_bits
    x = 1
    result = []
    while True:
        xlog = math.log2(x)
        xlog_bits = int(xlog * 2**bits)
        result.append(xlog_bits)
        x += step
        if x >= 2:
            break

    return result

def find_msb(number):
    # first get the number of bits necessary to represent our number
    # then we cheat, because we can. the floor is the msb
    x = math.floor(math.log2(number))
    return x

class log(object):
    def __init__(self, input_bits, output_bits):
        # compile time constants
        self.lut_bits = 5
        assert input_bits > 1
        assert output_bits > self.lut_bits
        self.in_bits = input_bits
        self.out_bits = output_bits
        max_val = ((self.in_bits-1) << self.lut_bits) + 2**self.lut_bits-1
        self.scale = (2**self.out_bits-1) / max_val

    def approx_log2(self, number):
        msb = find_msb(number)
        rest = number ^ (1<<msb)
        shift_rest = rest / 2**msb
        # use 8 bit lut
        bits = 5
        lut = get_lut(bits, self.lut_bits)
        # lookup value must be shifted by number of lut bits
        lookup = int(2**bits * shift_rest)
        dec = lut[lookup]
        print(msb, rest, lookup, dec)
        result = 2**self.lut_bits*msb + dec
        return result * self.scale


if __name__ == "__main__":
    approx_log2 = log(8,8).approx_log2
    for num in range(1,33):
        expected = normal_log2(num) * 256 / normal_log2(256)
        actual = approx_log2(num)
        diff = math.fabs(expected-actual)
        print("{} {} {}".format(expected, actual, diff))
    approx_log2 = log(18,18).approx_log2
    expected = normal_log2(2**18-1) * (2**18-1) / normal_log2(2**18-1)
    actual = approx_log2(2**18-1)
    print("{} {}".format(expected, actual))