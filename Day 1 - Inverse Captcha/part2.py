#!/usr/bin/env python3
import sys


def main():
    with open(sys.argv[1]) as f:
        input_number = f.read().strip()

    half_way = len(input_number) // 2
    half1 = input_number[:half_way]
    half2 = input_number[half_way:]

    magic_sum = 0
    for d1, d2 in zip(half1, half2):
        if d1 == d2:
            magic_sum += int(d1) * 2

    print(magic_sum)


if __name__ == "__main__":
    main()
