from os import paramCount, paramStr
from sequtils import insert
from strutils import parseInt


proc spinlock(s: var seq[int], step: int, n: int): int =
    s.add(0)

    var lastInsert = 0
    for i in 1..n-1:
        lastInsert = (lastInsert + step) mod s.len
        s.insert(@[i], lastInsert + 1)
        lastInsert = (lastInsert + 1) mod s.len

    return lastInsert


if paramCount() < 1:
    echo "Number of steps should be provided via command-line arguments"
    quit(1)

var numOfSteps: int
try:
    numOfSteps = parseInt(paramStr(1))
except ValueError:
    echo "Not a valid number of steps"
    quit(1)

const numOfElements = 2018

var state: seq[int] = @[]
let lastInsert = state.spinlock(numOfSteps, numOfElements)
echo "Last insert happened at ", lastInsert

let nextIndex =
    if lastInsert < numOfElements - 1:
        lastInsert + 1
    else:
        0

echo "Next element is ", state[nextIndex]