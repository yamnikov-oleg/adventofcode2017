open System
open System.IO
open System.Text.RegularExpressions
open System.Collections.Generic

type Level = {
    Depth : int
    Range : int
}

let linePattern : Regex = new Regex "(\d+): (\d+)"

let parseLevel (line : string) : Level option =
    let m = linePattern.Match line
    if m.Success then
        let depth = int m.Groups.[1].Value
        let range = int m.Groups.[2].Value
        Some { Depth = depth; Range = range; }
    else
        None

let severity (trip : Level list) (delay : int) : int =
    trip
    |> List.filter (fun level ->
        let pos = (delay + level.Depth) % (level.Range * 2 - 2)
        pos = 0
    )
    |> List.map (fun level -> level.Depth * level.Range)
    |> List.sum

let timesCaught (trip : Level list) (delay : int64) : int =
    trip
    |> List.filter (fun level ->
        let pos = (delay + int64 level.Depth) % int64(level.Range * 2 - 2)
        pos = 0L
    )
    |> List.length

let minSafeDelay (trip : Level list) : int64 option =
    let rec gcd x y = if y = 0L then abs x else gcd y (x % y)
    let lcm x y = x * y / (gcd x y)
    let maxDelay =
        trip
        |> List.map (fun level -> int64(level.Range) * 2L - 2L)
        |> List.reduce lcm

    try
        seq{1L..maxDelay}
        |> Seq.pick (fun delay ->
            match timesCaught trip delay with
            | 0 -> Some delay
            | _ -> None
        )
        |> Some
    with
    | :? KeyNotFoundException as ex -> None

[<EntryPoint>]
let main argv =
    try
        if argv.Length < 1 then do
            failwith "Input file path is required"

        let inputPath = argv.[0]
        let linePattern = new Regex("(\d+): (\d+)")
        let levels =
            File.ReadLines(inputPath)
            |> Seq.mapi (fun index line ->
                match parseLevel line with
                | Some level -> level
                | None ->
                    sprintf "Line %d has invalid format: \"%s\"" (index + 1) line
                    |> failwith
            )
            |> Seq.toList

        let tripSeverity = severity levels 0
        printfn "Trip severity with delay 0: %d" tripSeverity

        match minSafeDelay levels with
        | Some delay -> printfn "Min safe delay %d" delay
        | None -> printfn "No safe trip delay was found"

        0
    with
    | ex ->
        printfn "%s" ex.Message
        1
