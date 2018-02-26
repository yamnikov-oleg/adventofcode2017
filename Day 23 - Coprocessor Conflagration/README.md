Written in Dart 1.24. Can be run with:

```
$ dart part1.dart input.txt
$ dart part2.dart input.txt
```

# Day 23: Coprocessor Conflagration

You decide to head directly to the CPU and fix the printer from there. As you get close, you find an _experimental coprocessor_ doing so much work that the local programs are afraid it will [halt and catch fire](https://en.wikipedia.org/wiki/Halt_and_Catch_Fire). This would cause serious issues for the rest of the computer, so you head in and see what you can do.

The code it's running seems to be a variant of the kind you saw recently on that [tablet](18). The general functionality seems _very similar_, but some of the instructions are different:

* `set X Y` _sets_ register `X` to the value of `Y`.
* `sub X Y` _decreases_ register `X` by the value of `Y`.
* `mul X Y` sets register `X` to the result of _multiplying_ the value contained in register `X` by the value of `Y`.
* `jnz X Y` _jumps_ with an offset of the value of `Y`, but only if the value of `X` is _not zero_. (An offset of `2` skips the next instruction, an offset of `-1` jumps to the previous instruction, and so on.)
Only the instructions listed above are used. The eight registers here, named `a` through `h`, all start at `0`.

The coprocessor is currently set to some kind of _debug mode_, which allows for testing, but prevents it from doing any meaningful work.

If you run the program (your puzzle input), _how many times is the `mul` instruction invoked?_

## Part Two

Now, it's time to fix the problem.

The _debug mode switch_ is wired directly to register `a`.  You flip the switch, which makes _register `a` now start at `1`_ when the program is executed.

Immediately, the coprocessor begins to overheat.  Whoever wrote this program obviously didn't choose a very efficient implementation.  You'll need to _optimize the program_ if it has any hope of completing before Santa needs that printer working.

The coprocessor's ultimate goal is to determine the final value left in register `h` once the program completes. Technically, if it had that... it wouldn't even need to run the program.

After setting register `a` to `1`, if the program were to run to completion, _what value would be left in register `h`?_
