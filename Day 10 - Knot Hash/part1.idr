module Main

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
    MkHasherState (pos + skip + len) (skip + 1) (tieKnot string pos len)

applyKnots : HasherState -> (lens : List Nat) -> HasherState
applyKnots state lens = foldl applyKnot state lens

parseInput : List String -> Either String (List Nat)
parseInput [] = Right []
parseInput (s::ss) =
    case parsePositive {a=Nat} s of
        Nothing => Left $ "Number has incorrect format: " ++ show s
        Just n => map (n::) $ parseInput ss

main : IO ()
main = do
    args <- getArgs
    Just inputPath <- pure $ head' $ drop 1 args
    | Nothing => putStrLn "Expected file path in the arguments"

    Right inputText <- readFile inputPath
    | Left err => (putStrLn $ "Error while opening file: " ++ show err)

    Right inputNumbers <- pure $ parseInput $ split (== ',') $ trim inputText
    | Left err => putStrLn err

    let finalNumbers = string $ applyKnots (newHasher 256) inputNumbers
    let finalProduct = product $ take 2 $ finalNumbers
    putStrLn $ "Product of first two numbers: " ++ show finalProduct
