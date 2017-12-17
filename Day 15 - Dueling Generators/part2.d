import std.stdio : writefln, writeln;
import std.range : take, zip;
import std.conv : parse, ConvException;

class Generator
{
    private const ulong MOD = 2147483647;
    private ulong factor;
    private ulong state;
    private ulong filter;

    this(ulong factor, ulong initial, ulong filter)
    {
        this.factor = factor;
        this.state = initial;
        this.filter = filter;
        this.popFront();
    }

    bool empty() const @property
    {
        return false;
    }

    ulong front() const @property
    {
        return this.state;
    }

    void popFront()
    {
        do
        {
            this.state = (this.state * this.factor) % this.MOD;
        }
        while (this.state % this.filter != 0);
    }
}

int main(string[] args)
{
    if (args.length < 3)
    {
        writeln("Initial values for both generators are required");
        return 1;
    }

    ulong initialA;
    ulong initialB;
    try
    {
        initialA = parse!ulong(args[1]);
        initialB = parse!ulong(args[2]);
    }
    catch (ConvException e)
    {
        writeln("Can't parse initial values");
        return 1;
    }

    const FACTOR_A = 16807;
    const FILTER_A = 4;
    auto genA = new Generator(FACTOR_A, initialA, FILTER_A);

    const FACTOR_B = 48271;
    const FILTER_B = 8;
    auto genB = new Generator(FACTOR_B, initialB, FILTER_B);

    const MAXMATCHES = 5_000_000;
    const PATTERN = 0xFFFF; // lower 16 bits
    ulong matches = 0;
    foreach (pair; take(zip(genA, genB), MAXMATCHES))
    {
        if ((pair[0] & PATTERN) == (pair[1] & PATTERN))
        {
            matches++;
        }
    }
    writefln("Total matches: %s", matches);

    return 0;
}
