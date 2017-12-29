open Printf

type pipe =
  | PipeLetter of char
  | PipeVertical
  | PipeHorizontal
  | PipeTurn

let pipe_from_char (c : char) : pipe option =
  match c with
  | 'A'..'Z' | 'a'..'z' -> Some (PipeLetter c)
  | '|' -> Some PipeVertical
  | '-' -> Some PipeHorizontal
  | '+' -> Some PipeTurn
  | _ -> None

let pipes_from_string (si : int) (s : string) : (int * int * pipe) list =
  let pipes = ref [] in
  for i = String.length s - 1 downto 0 do
    match pipe_from_char s.[i] with
    | Some p -> pipes := (si, i, p) :: !pipes
    | None -> ()
  done;
  !pipes

let find_start (pipes : (int * int, pipe) Hashtbl.t) : (int * int) option =
  let start = ref None in
  let iter (i, j) pipe =
    if i == 0 && pipe == PipeVertical then
      start := Some (i, j)
    else
      ()
    in
  Hashtbl.iter iter pipes;
  !start

let find_opt (h : ('a, 'b) Hashtbl.t) (key : 'a) : 'b option =
  match Hashtbl.find_all h key with
  | [] -> None
  | x::xs -> Some x

let is_some (o : 'a option) : bool =
  match o with
  | Some _ -> true
  | None -> false

type dir = Up | Down | Left | Right

let rec walk ((i, j) : int * int) (d : dir) (pipes : (int * int, pipe) Hashtbl.t) : int * char list =
  let advance d' =
    match d' with
    | Up -> (i - 1, j)
    | Down -> (i + 1, j)
    | Left -> (i, j - 1)
    | Right -> (i, j + 1)
    in

  match find_opt pipes (i, j) with
  | Some (PipeLetter c) ->
    let (steps, chars) = walk (advance d) d pipes in
    steps + 1, c :: chars
  | Some PipeVertical | Some PipeHorizontal ->
    let (steps, chars) = walk (advance d) d pipes in
    steps + 1, chars
  | Some PipeTurn -> begin
    let d' =
      match d with
      | Up | Down ->
        if is_some (find_opt pipes (i, j - 1))
        then Left
        else Right
      | Left | Right ->
        if is_some (find_opt pipes (i - 1, j))
        then Up
        else Down
      in
    let (steps, chars) = walk (advance d') d' pipes in
    steps + 1, chars
  end
  | None -> 0, []

let () =
  if Array.length Sys.argv < 2 then begin
    print_endline "Input file path is required";
    exit 1
  end;

  let ic = open_in Sys.argv.(1) in
  let pipes = Hashtbl.create 100 in
  try
    let line_index = ref 0 in
    while true; do
      let pipes_line = pipes_from_string !line_index (input_line ic) in
      line_index := !line_index + 1;

      let add_pipe (i, j, pipe) =
        Hashtbl.add pipes (i, j) pipe in
      List.iter add_pipe pipes_line
    done
  with End_of_file ->
    close_in ic;

  let start =
    match find_start pipes with
    | Some (i, j) -> (i, j)
    | None -> begin
      print_endline "Could not find the start pipe";
      exit 1
    end in

  let steps, chars = walk start Down pipes in
  let chars_string =
    chars
    |> List.map (sprintf "%c")
    |> String.concat ""
    in
  printf "Walking sequence (took %d steps): %s\n" steps chars_string
