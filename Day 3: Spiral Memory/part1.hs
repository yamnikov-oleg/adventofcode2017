import           Control.Monad      (when)
import           System.Environment (getArgs)
import           System.Exit        (die)
import           Text.Read          (readMaybe)

sumOfNats :: Integer -> Integer
sumOfNats n = round $ (dn+1) * dn / 2
    where dn = fromIntegral n :: Double

invSumOfNats :: Double -> Double
invSumOfNats s =
    if s == fromIntegral (sumOfNats (round approxSolution))
        then fromInteger $ round approxSolution
        else approxSolution
    where
        discriminant = 1.0 + 8.0 * s
        approxSolution = (-1 + sqrt discriminant) / 2

loopOfNumber :: Integer -> Integer
loopOfNumber num = ceiling $ invSumOfNats $ (fromIntegral num-1) / 8

loopBase :: Integer -> Integer
loopBase loop = sumOfNats (loop-1) * 8 + 1

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
