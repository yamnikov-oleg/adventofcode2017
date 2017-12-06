using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Day6
{
    class Memory
    {
        protected int[] Banks;

        public Memory(int[] banks)
        {
            Banks = banks;
        }

        public static Memory FromFile(string path)
        {
            using (var reader = File.OpenText(path))
            {
                var firstLine = reader.ReadLine().Trim();
                var numStrings = firstLine.Split('\t');
                var nums = numStrings.Select(str => Int32.Parse(str)).ToArray();
                return new Memory(nums);
            }
        }

        public int GetStateHash()
        {
            int hash = 0;
            foreach (var bank in Banks)
            {
                // sdbm algorithm
                hash = (hash << 16) + (hash << 6) - hash + bank;
            }
            return hash;
        }

        public override string ToString()
        {
            var builder = new StringBuilder();
            builder.Append("Memory@");
            builder.Append(GetStateHash());
            builder.Append("[");
            builder.Append(String.Join(", ", Banks));
            builder.Append("]");
            return builder.ToString();
        }

        public (int Index, int Size) GetLargestBank()
        {
            var largest = (Index: 0, Size: Banks[0]);

            for (int i = 1; i < Banks.Length; i++)
            {
                if (Banks[i] > largest.Size)
                {
                    largest = (Index: i, Size: Banks[i]);
                }
            }

            return largest;
        }

        public void RedistributeData()
        {
            // Remove the largest bank
            var largest = GetLargestBank();
            Banks[largest.Index] = 0;

            // Add the evenly distributed part of the bank's blocks
            var commonDistr = largest.Size / Banks.Length;
            for (int i = 0; i < Banks.Length; i++)
            {
                Banks[i] = Banks[i] + commonDistr;
            }

            // Distribute the remaining blocks
            var remaining = largest.Size % Banks.Length;
            for (int i = 0; i < remaining; i++)
            {
                var targetIndex = largest.Index + i + 1;
                if (targetIndex >= Banks.Length)
                {
                    targetIndex -= Banks.Length;
                }
                Banks[targetIndex]++;
            }
        }
    }

    class Program
    {

        static void Run(string inputPath, bool verbose = false)
        {
            // To avoid the infinite loop
            const ulong MaxIterations = 1_000_000_000;

            Memory memory;
            try
            {
                memory = Memory.FromFile(inputPath);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return;
            }

            if (verbose) Console.WriteLine($"Initial: {memory}");

            var stateIterations = new Dictionary<int, ulong>();
            stateIterations.Add(memory.GetStateHash(), 0);

            ulong iterations = 0L;
            while (true)
            {
                memory.RedistributeData();
                iterations++;

                if (verbose) Console.WriteLine($"Iter {iterations}: {memory}");

                if (stateIterations.ContainsKey(memory.GetStateHash()))
                {
                    break;
                }
                stateIterations.Add(memory.GetStateHash(), iterations);

                if (iterations >= MaxIterations)
                {
                    Console.WriteLine($"Reached maximum number of iterations ({MaxIterations})");
                    return;
                }
            }

            Console.WriteLine($"Repetitive state has been reached in {iterations} iterations");

            var loopSize = iterations - stateIterations[memory.GetStateHash()];
            Console.WriteLine($"The loop has a size of {loopSize}");
        }

        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Usage:");
                Console.WriteLine("  dotnet run input.txt [-v]");
                return;
            }

            Run(args[0], verbose: args.Contains("-v"));
        }
    }
}
