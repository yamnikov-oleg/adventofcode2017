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
        for rule in rules.values() do
            if rule.from.id() == id then
                return Pattern.sub(rule.into, 0, 0, rule.into.size())
            end
        end
        error


class FastRoolbook
    var rules33_44: Array[(U64, Array[U64])]
    var rules33_66: Array[(U64, Array[U64])]
    var rules33_99: Array[(U64, Array[U64])]

    new compile(b: Rulebook)? =>
        rules33_44 = []
        var rules33_44_raw: Array[Rule] = []
        for rule in b.rules.values() do
            if rule.from.size() == 3 then
                rules33_44_raw.push(rule)
                rules33_44.push((rule.from.id(), [rule.into.id()]))
            end
        end

        rules33_66 = []
        var rules33_66_raw: Array[Rule] = []
        for rule in rules33_44_raw.values() do
            var into = Pattern.zeros(6)
            var into_ids: Array[U64] = []
            for i in Range(0, 2) do
                for j in Range(0, 2) do
                    let part = Pattern.sub(rule.into, i*2, j*2, 2)
                    let part_deriv = b.derive(part)?
                    into.insert(part_deriv, i*3, j*3)
                    into_ids.push(part_deriv.id())
                end
            end
            rules33_66_raw.push(Rule.create(rule.from, into))
            rules33_66.push((rule.from.id(), into_ids))
        end

        rules33_99 = []
        for rule in rules33_66_raw.values() do
            var into_ids: Array[U64] = []
            for i in Range(0, 3) do
                for j in Range(0, 3) do
                    let part = Pattern.sub(rule.into, i*2, j*2, 2)
                    let part_deriv = b.derive(part)?
                    into_ids.push(part_deriv.id())
                end
            end
            rules33_99.push((rule.from.id(), into_ids))
        end

    fun count_1_bits(initial_id: U64, iters: U64): U64? =>
        if iters == 0 then
            var bits_cnt: U64 = 0
            var iid = initial_id
            while iid > 0 do
                if (iid % 2) == 1 then
                    bits_cnt = bits_cnt + 1
                end
                iid = iid / 2
            end
            bits_cnt
        elseif iters == 1 then
            for (from_id, into_ids) in rules33_44.values() do
                if from_id == initial_id then
                    var bits_cnt: U64 = 0
                    for id in into_ids.values() do
                        bits_cnt = bits_cnt + count_1_bits(id, 0)?
                    end
                    return bits_cnt
                end
            end
            Debug.out("Rulebook is incomplete")
            error
        elseif iters == 2 then
            for (from_id, into_ids) in rules33_66.values() do
                if from_id == initial_id then
                    var bits_cnt: U64 = 0
                    for id in into_ids.values() do
                        bits_cnt = bits_cnt + count_1_bits(id, 0)?
                    end
                    return bits_cnt
                end
            end
            Debug.out("Rulebook is incomplete")
            error
        else
            for (from_id, into_ids) in rules33_99.values() do
                if from_id == initial_id then
                    var bits_cnt: U64 = 0
                    for id in into_ids.values() do
                        bits_cnt = bits_cnt + count_1_bits(id, iters - 3)?
                    end
                    return bits_cnt
                end
            end
            Debug.out("Rulebook is incomplete")
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

        let fast_rulebook =
            try
                FastRoolbook.compile(rulebook)?
            else
                env.err.print("Could not compile the rulebook")
                env.exitcode(1)
                return
            end

        var initial = Pattern.zero()
        try
            initial = Pattern.parse(".#./..#/###")?
        else
            env.err.print("Could not parse initial pattern")
            env.exitcode(1)
            return
        end

        try
            let bits_cnt = fast_rulebook.count_1_bits(initial.id(), iters_cnt)?.string()
            env.out.print("Number of bits: " + bits_cnt.string())
        else
            env.err.print("Could not count bits")
            env.exitcode(1)
            return
        end