import           Control.Monad      (when)
import           System.Environment (getArgs)
import           System.Exit        (die)
import           Text.Read          (readMaybe)

loopOfNumber :: Integer -> Integer
loopOfNumber num = loopOfNumber' 0 (num-1)
    where
        loopOfNumber' li num
            | num - li*8 <= 0 = li
            | otherwise = loopOfNumber' (li+1) (num-li*8)

loopBase :: Integer -> Integer
loopBase 0    = 1
loopBase 1    = 1
loopBase loop = (loop - 1) * 8 + loopBase (loop - 1)

loopLength :: Integer -> Integer
loopLength loop = loop * 8

loopMiddles :: Integer -> [Integer]
loopMiddles 0 = [1]
loopMiddles loop = [base + p, base + 3*p, base + 5*p, base + 7*p]
    where
        base = loopBase loop
        p = loopLength loop `div` 8

minimumKey :: (Ord b) => (a -> b) -> [a] -> a
minimumKey key (x:xs) = foldl cmp x xs
    where
        cmp a b = if key a <= key b
            then a
            else b

closestMiddleToNumber :: Integer -> Integer
closestMiddleToNumber num = minimumKey dist middles
    where
        dist middle = abs (num - middle)
        middles = loopMiddles loop
        loop = loopOfNumber num

manhattanDistance :: Integer -> Integer
manhattanDistance num = loop + abs (num - middle)
    where
        loop = loopOfNumber num
        middle = closestMiddleToNumber num

main :: IO ()
main = do
    args <- getArgs
    when (length args /= 1) $
        die "specify target number via command-line argument"
    case readMaybe (head args) of
        Nothing ->
            die "invalid number"
        Just num -> do
            let dist = manhattanDistance num
            putStrLn $ "Manhattan distance to the square 1: " ++ show dist
