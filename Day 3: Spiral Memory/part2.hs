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

-- I'm not proud of this code, but it works.
-- Returns list of indices from which the next number in the sequence should be
-- constructed. Each index describes how much steps do we have to go back
-- to find a neighbor of this value. The value equals to the sum of its neighbors.
sumOfLastInds :: Integer -> [Integer]
sumOfLastInds n
    | pos == 1        = [1, pllen]
    | pos == 2        = [1, 2, pos+pllen-2, pos+pllen-1]
    | pos < lq - 1    = [1, pllen, pllen+1, pllen+2]
    | pos == lq - 1   = [1, pllen+1, pllen+2]
    | pos == lq       = [1, pllen+2]
    | pos == lq + 1   = [1, 2, pllen+2, pllen+3]
    | pos < lq*2 - 1  = [1, pllen+2, pllen+3, pllen+4]
    | pos == lq*2 - 1 = [1, pllen+3, pllen+4]
    | pos == lq*2     = [1, pllen+4]
    | pos == lq*2 + 1 = [1, 2, pllen+4, pllen+5]
    | pos < lq*3 - 1  = [1, pllen+4, pllen+5, pllen+6]
    | pos == lq*3 - 1 = [1, pllen+5, pllen+6]
    | pos == lq*3     = [1, pllen+6]
    | pos == lq*3 + 1 = [1, 2, pllen+6, pllen+7]
    | pos < lq*4 - 1  = [1, pllen+6, pllen+7, pllen+8]
    | pos == lq*4 - 1 = [1, llen-2, pllen+7, pllen+8]
    | pos == lq*4     = [1, llen-1, pllen+8]
    where
        loop = loopOfNumber n
        lbase = loopBase loop
        pos = n - lbase
        llen = loopLength loop
        lq = llen `div` 4

        ploop = loop - 1
        pllen = loopLength ploop

firstLargerInSeq' :: Integer -> Integer -> [Integer] -> Integer
firstLargerInSeq' n i mem =
    let
        inds = sumOfLastInds i
        vals = map ((mem !!) . fromIntegral .  (\x -> x-1)) inds
        newVal = sum vals
    in
        if newVal > n
            then newVal
            else firstLargerInSeq' n (i+1) (newVal:mem)

firstLargerInSeq :: Integer -> Integer
firstLargerInSeq n = firstLargerInSeq' n 10 [25, 23, 11, 10, 5, 4, 2, 1, 1]

main :: IO ()
main = do
    args <- getArgs
    when (length args /= 1) $
        die "specify target number via command-line argument"
    case readMaybe (head args) of
        Nothing ->
            die "invalid number"
        Just n -> do
            let firstLarger = firstLargerInSeq n
            print firstLarger
