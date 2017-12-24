from os import paramCount, paramStr
from sequtils import insert
from strutils import parseInt


proc spinlock(step: int, n: int, limit: int): tuple[s: seq[int], lastInsert: int] =
    ## Constructs a spinklock of length `n` with step size of `step`.
    ## Returns a tuple of first `limit` elements of the spinlock sequence
    ## and index of the last inserted item.
    ## If limit is set to -1, returns all the elements of the sequence.

    var s: seq[int] = @[0]
    var buflen = 1
    var lastInsert = 0

    for i in 1..n-1:
        let insertAt = ((lastInsert + step) mod buflen) + 1

        if limit < 0 or buflen < limit or insertAt < s.len:
            s.insert(@[i], insertAt)
            if s.len > limit:
                s = s[0..limit-1]

        buflen += 1
        lastInsert = insertAt mod buflen

    return (s, lastInsert)


if paramCount() < 1:
    echo "Number of steps should be provided via command-line arguments"
    quit(1)

var numOfSteps: int
try:
    numOfSteps = parseInt(paramStr(1))
except ValueError:
    echo "Not a valid number of steps"
    quit(1)

const numOfElements = 50_000_000

let state = spinlock(numOfSteps, numOfElements, 2)
echo "Element just after 0: ", state.s[1]