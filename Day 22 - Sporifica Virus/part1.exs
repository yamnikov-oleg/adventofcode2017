defmodule Turn do
    def left(:up),    do: :left
    def left(:left),  do: :down
    def left(:down),  do: :right
    def left(:right), do: :up

    def right(:up),    do: :right
    def right(:right), do: :down
    def right(:down),  do: :left
    def right(:left),  do: :up
end

defmodule Virus do
    defstruct i: 0, j: 0, face: :up

    def move %Virus{i: i, j: j, face: face}, field do
        current_node = case MapSet.member?(field, {i, j}) do
            true -> :infected
            false -> :clean
        end

        face_ = case current_node do
            :infected -> Turn.right face
            :clean -> Turn.left face
        end

        {result, field_} = case current_node do
            :infected -> {:cleaned, MapSet.delete(field, {i, j})}
            :clean -> {:infected, MapSet.put(field, {i, j})}
        end

        {i_, j_} = case face_ do
            :up -> {i-1, j}
            :right -> {i, j+1}
            :down -> {i+1, j}
            :left -> {i, j-1}
        end

        {result, %Virus{i: i_, j: j_, face: face_}, field_}
    end
end

defmodule Day22 do
    def main args do
        {filename, bursts} = case args do
            [f, b | _] -> case Integer.parse(b) do
                {bnum, ""} -> {f, bnum}
                _ -> raise "Number of bursts must be integer"
            end
            _ -> raise "File name and number of bursts are required in cmdline args"
        end

        lines = case File.read filename do
            {:ok, c} -> String.split(c, "\n")
                # Ignore empty lines
                |> Enum.filter(&(String.length(&1) > 0))
            {:error, e} -> raise "Could not open the file: #{e}"
        end

        # Convert input into a set of initially infected points
        # represented as tuples {line_ix, column_ix}
        initially_infected = lines
        # Convert each line to the list of indices of '#' characters
        |> Enum.map(&String.to_charlist/1)
        |> Enum.map(fn chars ->
            chars
            |> Enum.with_index
            |> Enum.filter(fn {char, _} -> char == ?# end)
            |> Enum.map(fn {_, ix} -> ix end)
        end)
        # Add line index to each '#' index and flatten the list
        |> Enum.with_index
        |> Enum.flat_map(fn {pts, lix} ->
            Enum.map(pts, fn cix -> {lix, cix} end)
        end)
        # Collect
        |> Enum.into(MapSet.new)

        initial_height = length(lines)
        initial_width = lines
        |> Enum.map(&String.length/1)
        |> Enum.max

        start_i = trunc(initial_height/2)
        start_j = trunc(initial_width/2)

        start_virus = %Virus{i: start_i, j: start_j}

        {_, finally_infected, infections_cnt} = 1..bursts
        |> Enum.reduce(
            {start_virus, initially_infected, 0},
            fn _, {virus, field, infections_cnt} ->
                case Virus.move(virus, field) do
                    {:infected, virus_, field_} -> {virus_, field_, infections_cnt+1}
                    {:cleaned, virus_, field_} -> {virus_, field_, infections_cnt}
                end
            end
        )

        IO.puts "Started with: #{MapSet.size(initially_infected)} infected nodes"
        IO.puts "Finished with: #{MapSet.size(finally_infected)} infected nodes"
        IO.puts "Infections happened in total: #{infections_cnt}"
    end
end

Day22.main System.argv
