use "assert"
use "collections"
use "debug"
use "files"


class val Pattern
    let bits: Array[Array[Bool]]

    new parse(s: String)? =>
        var bits' = Array[Array[Bool]](4)
        let lines_cnt = s.split_by("/").size()
        for line in s.split_by("/").values() do
            Fact(line.size() == lines_cnt)?
            var row = Array[Bool](4)
            for rune in line.runes() do
                if rune == '.' then
                    row.push(false)
                elseif rune == '#' then
                    row.push(true)
                else
                    error
                end
            end
            bits'.push(row)
        end

        bits = bits'

    new sub(base: Pattern box, ib: USize, jb: USize, size: USize) =>
        var bits' = Array[Array[Bool]](size)

        for i in Range(ib, ib + size) do
            var row = Array[Bool](size)
            for j in Range(jb, jb + size) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    new transposed(base: Pattern box) =>
        let size = base.bits.size()
        var bits' = Array[Array[Bool]](size)

        for j in Range(0, size) do
            var row = Array[Bool](size)
            for i in Range(0, size) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    new hmirrored(base: Pattern box) =>
        let size = base.bits.size()
        var bits' = Array[Array[Bool]](size)

        for i in Range(0, size) do
            var row = Array[Bool](size)
            for j in Range(size-1, -1, -1) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    new vmirrored(base: Pattern box) =>
        let size = base.bits.size()
        var bits' = Array[Array[Bool]](size)

        for i in Range(size-1, -1, -1) do
            var row = Array[Bool](size)
            for j in Range(0, size) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    fun into_number(): U64 =>
        var num: U64 = 0
        for row in bits.values() do
            for bit in row.values() do
                if bit then
                    num = (num * 2) + 1
                else
                    num = num * 2
                end
            end
        end
        num

    fun string(): String =>
        var lines = Array[String](bits.size())

        for row in bits.values() do
            var line = ""
            for bit in row.values() do
                if bit then
                    line = line + "#"
                else
                    line = line + "."
                end
            end
            lines.push(line)
        end

        "/".join(lines.values())

    fun id(): U64 =>
        var min: U64 = into_number()
        min = Pattern.hmirrored(this).into_number().min(min)
        min = Pattern.vmirrored(this).into_number().min(min)
        min = Pattern.hmirrored(Pattern.vmirrored(this)).into_number().min(min)
        let t = Pattern.transposed(this)
        min = t.into_number().min(min)
        min = Pattern.hmirrored(t).into_number().min(min)
        min = Pattern.vmirrored(t).into_number().min(min)
        min = Pattern.hmirrored(Pattern.vmirrored(t)).into_number().min(min)
        min


actor Main
    new create(env: Env) =>
        if env.args.size() < 2 then
            env.err.print("Input file path is required")
            env.exitcode(1)
            return
        end

        let input_path =
            try
                FilePath(env.root as AmbientAuth, env.args(1)?)?
            else
                env.err.print("Could not build input file path")
                env.exitcode(1)
                return
            end

        match OpenFile(input_path)
        | let file: File =>
            var line_no: U32 = 1
            while file.errno() is FileOK do
                let line =
                    try
                        file.line()?
                    else
                        break
                    end

                line.strip()

                if line.size() == 0 then
                    continue
                end

                try
                    let parts = line.split_by(" => ")
                    Fact(parts.size() == 2)?

                    let src_pattern = parts(0)?
                    let pat = Pattern.parse(src_pattern)?
                    env.out.print(pat.string() + " -> " + pat.id().string())
                else
                    env.err.print("Could not parse line " + line_no.string())
                    env.exitcode(1)
                    return
                end

                line_no = line_no + 1
            end
        else
            env.err.print("Could not open the file")
            env.exitcode(1)
            return
        end