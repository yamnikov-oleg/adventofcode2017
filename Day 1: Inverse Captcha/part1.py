#!/usr/bin/env python3
import sys


def sliding_pairs(iterable):
    iterator = iter(iterable)

    try:
        last_digit = next(iterator)
    except StopIteration:
        return

    for next_digit in iterator:
        yield (last_digit, next_digit)
        last_digit = next_digit


def main():
    with open(sys.argv[1]) as f:
        input_number = f.read().strip()

    # Append first digit to the end
    input_number += input_number[-1]

    magic_sum = 0
    for d1, d2 in sliding_pairs(input_number):
        if d1 == d2:
            magic_sum += int(d1)

    print(magic_sum)


if __name__ == "__main__":
    main()
