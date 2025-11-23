using System;
using Benchmarks.Framework;

namespace Benchmarks;

class Program
{
    public static void Main()
    {
        Benchmarks.Benchmarks.BitBenchmarks.Setup();
        Benchmarks.Benchmarks.EntityBenchmarks.Setup();
        Benchmarks.Benchmarks.RealEntityBenchmarks.Setup();
        BenchmarkRunner.RunAll();
        Benchmarks.Benchmarks.BitBenchmarks.Teardown();
        Benchmarks.Benchmarks.EntityBenchmarks.Teardown();
        Benchmarks.Benchmarks.RealEntityBenchmarks.Teardown();
        BenchmarkRegistry.Clear();
    }
}
