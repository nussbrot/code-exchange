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

def approx_log2(number):
    msb = find_msb(number)
    rest = number ^ (1<<msb)
    shift_rest = rest / 2**msb
    # use 8 bit lut
    bits = 5
    lut = get_lut(5, bits)
    # lookup value must be shifted by number of lut bits
    lookup = int(2**5 * shift_rest)
    dec = lut[lookup]
    print(msb, rest, lookup, dec)
    return 2**5*(msb)+dec


if __name__ == "__main__":
    for num in range(1,33):
        expected = normal_log2(num) * 256 / normal_log2(256)
        actual = approx_log2(num)
        print("{} {}".format(expected, actual))