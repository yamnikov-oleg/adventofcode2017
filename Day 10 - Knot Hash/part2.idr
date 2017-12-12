module Main

import Data.Bits
import Data.List
import Data.String

delta : Nat -> Nat -> Nat
delta Z b = b
delta a Z = a
delta (S a) (S b) = delta a b

cycle : (shift : Nat) -> List a -> List a
cycle _ [] = []
cycle Z xs = xs
cycle (S n) (x::xs) = cycle n (xs ++ [x])

cycleBack : (shift : Nat) -> List a -> List a
cycleBack _ [] = []
cycleBack Z xs = xs
cycleBack (S n) xs@(_::_) = cycleBack n (last xs :: init xs)

reverseFirst : (splitAt : Nat) -> List a -> List a
reverseFirst n xs =
    let
        MkPair part1 part2 = splitAt n xs
    in reverse part1 ++ part2

tieKnot : List Nat -> (pos : Nat) -> (len : Nat) -> List Nat
tieKnot nums pos len = cycleBack pos $ reverseFirst len $ cycle pos nums

record HasherState where
    constructor MkHasherState
    position : Nat
    skip : Nat
    string : List Nat

newHasher : (stringLen : Nat) -> HasherState
newHasher l = MkHasherState 0 0 (take l [0..])

applyKnot : HasherState -> (len : Nat) -> HasherState
applyKnot (MkHasherState pos skip string) len =
    let
        pos' = (pos + skip + len) `mod` (length string)
        skip' = skip + 1
        string' = tieKnot string pos len
    in
        MkHasherState pos' skip' string'

applyKnots : HasherState -> (lens : List Nat) -> HasherState
applyKnots state lens = foldl applyKnot state lens

parseInput : List String -> Either String (List Nat)
parseInput [] = Right []
parseInput (s::ss) =
    case parsePositive {a=Nat} s of
        Nothing => Left $ "Number has incorrect format: " ++ show s
        Just n => map (n::) $ parseInput ss

splitByGroups : (size : Nat) -> List a -> List (List a)
splitByGroups _ Nil = []
splitByGroups size l = (take size l) :: (splitByGroups size (drop size l))

condense : (groupSize : Nat) -> List Nat -> List Nat
condense groupSize nats =
    let
        bitGroups = splitByGroups 16 $ map (natToBits {n=0}) nats
        zeroByte = natToBits {n=0} 0
        xors = map (foldl (xor' {n=0}) zeroByte) bitGroups
        denseHash = map (cast . (bitsToInt' {n=0})) xors
    in
        denseHash

byteToHex : Nat -> String
byteToHex num = pack [digit ((num `div` 16) `mod` 16), digit (num `mod` 16)] where
    digit n = fromMaybe 'x' $ index' n $ unpack "0123456789abcdef"

join : List String -> String
join Nil = ""
join (s :: ss) = s ++ join ss

round : (knots : List Nat) -> HasherState -> (index : Nat) -> IO HasherState
round knots state index = do
    putChar '.'
    pure $ applyKnots state knots

main : IO ()
main = do
    args <- getArgs
    Just inputText <- pure $ head' $ drop 1 args
    | Nothing => putStrLn "Expected target string in the arguments"

    let inputNumbers = map (cast . ord) $ unpack inputText
    let magicSuffix = [17, 31, 73, 47, 23]
    let hashKnots = inputNumbers ++ magicSuffix
    putStrLn $ "Input: " ++ show inputText ++ " (" ++ (show $ length hashKnots) ++ " knots)"

    let rounds = 64
    disableBuffering -- To output progress bar immediately
    hasher <- foldlM (round hashKnots) (newHasher 256) [1..rounds]
    putStrLn ""

    let sparseHash = string hasher
    let denseHash = condense 16 sparseHash
    let hashString = join $ map byteToHex denseHash
    putStrLn $ "Hash: " ++ hashString
