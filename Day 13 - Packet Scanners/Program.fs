open System
open System.IO
open System.Text.RegularExpressions

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
        let tripSeverity =
            levels
            |> List.filter (fun level ->
                let pos = level.Depth % (level.Range * 2 - 2)
                pos = 0
            )
            |> List.map (fun level -> level.Depth * level.Range)
            |> List.sum

        printfn "Trip severity: %d" tripSeverity
        0
    with
    | ex ->
        printfn "%s" ex.Message
        1
