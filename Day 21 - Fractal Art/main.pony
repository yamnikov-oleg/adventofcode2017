use "assert"
use "collections"
use "debug"
use "files"
use "json"


class Pattern
    let bits: Array[Array[Bool]]

    new zero() =>
        bits = []

    new zeros(s: USize) =>
        var bits' = Array[Array[Bool]](s)

        for i in Range(0, s) do
            var row = Array[Bool](s)
            for j in Range(0, s) do
                row.push(false)
            end
            bits'.push(row)
        end

        bits = bits'

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

    new sub(base: Pattern box, ib: USize, jb: USize, s: USize) =>
        var bits' = Array[Array[Bool]](s)

        for i in Range(ib, ib + s) do
            var row = Array[Bool](s)
            for j in Range(jb, jb + s) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    new transposed(base: Pattern box) =>
        var bits' = Array[Array[Bool]](base.size())

        for j in Range(0, base.size()) do
            var row = Array[Bool](base.size())
            for i in Range(0, base.size()) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    new hmirrored(base: Pattern box) =>
        var bits' = Array[Array[Bool]](base.size())

        for i in Range(0, base.size()) do
            var row = Array[Bool](base.size())
            for j in Range(base.size()-1, -1, -1) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    new vmirrored(base: Pattern box) =>
        var bits' = Array[Array[Bool]](base.size())

        for i in Range(base.size()-1, -1, -1) do
            var row = Array[Bool](base.size())
            for j in Range(0, base.size()) do
                row.push(try base.bits(i)?(j)? else false end)
            end
            bits'.push(row)
        end

        bits = bits'

    fun size(): USize =>
        bits.size()

    fun ref insert(p: Pattern, ib: USize, jb: USize) =>
        for i in Range(0, p.size()) do
            for j in Range(0, p.size()) do
                try
                    bits(ib+i)?(jb+j)? = p.bits(i)?(j)?
                end
            end
        end

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

    fun count_1_bits(): U64 =>
        var cnt: U64 = 0
        for row in bits.values() do
            for bit in row.values() do
                if bit then
                    cnt = cnt + 1
                end
            end
        end
        cnt

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


class Rule
    let from: Pattern
    let into: Pattern

    new create(f: Pattern, i: Pattern) =>
        from = f
        into = i


class Rulebook
    var rules: Array[Rule]

    new create() =>
        rules = []

    fun ref add_rule(r: Rule) =>
        rules.push(r)

    fun derive(p: Pattern): Pattern? =>
        let id = p.id()
        var deriv = Pattern.zero()
        for rule in rules.values() do
            if rule.from.id() == id then
                return Pattern.sub(rule.into, 0, 0, rule.into.size())
            end
        end
        error

    fun count_1_bits(initial: Pattern, iters: U64): U64? =>
        if iters <= 0 then
            return initial.count_1_bits()
        end

        if (initial.size() % 2) == 0 then
            let parts_cnt = initial.size() / 2
            let deriv = Pattern.zeros(parts_cnt * 3)
            for i in Range(0, parts_cnt) do
                for j in Range(0, parts_cnt) do
                    let part = Pattern.sub(initial, i*2, j*2, 2)
                    let part_deriv = derive(part)?
                    deriv.insert(part_deriv, i*3, j*3)
                end
            end
            count_1_bits(deriv, iters-1)?
        elseif (initial.size() % 3) == 0 then
            let parts_cnt = initial.size() / 3
            let deriv = Pattern.zeros(parts_cnt * 4)
            for i in Range(0, parts_cnt) do
                for j in Range(0, parts_cnt) do
                    let part = Pattern.sub(initial, i*3, j*3, 3)
                    let part_deriv = derive(part)?
                    deriv.insert(part_deriv, i*4, j*4)
                end
            end
            count_1_bits(deriv, iters-1)?
        else
            Debug.out("Grid size is not divisible by 2 or 3")
            error
        end


primitive StringToInt
    fun apply(s: String): U64? =>
        let doc = JsonDoc.create()
        doc.parse(s)?
        let i = doc.data as I64
        i.u64()


actor Main
    new create(env: Env) =>
        if env.args.size() < 3 then
            env.err.print("Input file path and iterations count are required")
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

        let iters_cnt =
            try
                StringToInt(env.args(2)?)?
            else
                env.err.print("Could not build input file path")
                env.exitcode(1)
                return
            end

        var rulebook = Rulebook.create()
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

                    let from_pat = Pattern.parse(parts(0)?)?
                    let into_pat = Pattern.parse(parts(1)?)?
                    rulebook.add_rule(Rule.create(from_pat, into_pat))
                    env.out.print(from_pat.string() + " -> " + from_pat.id().string())
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

        var initial = Pattern.zero()
        try
            initial = Pattern.parse(".#./..#/###")?
            env.out.print("Initial pattern's id = " + initial.id().string())
        else
            env.err.print("Could not parse initial pattern")
            env.exitcode(1)
            return
        end

        try
            env.out.print(rulebook.count_1_bits(initial, iters_cnt)?.string())
        else
            env.err.print("error")
            env.exitcode(1)
            return
        end