using System;
using Benchmarks.Framework;
using Sizzle.Core;
using System.Collections;

namespace Benchmarks.Benchmarks;

class EntityInline
{
    public BitfieldArray Bits = .();
    public int32[256] Components;

    public this()
    {
        Bits.Reserve(256); // Ensure SOO
    }

    public ~this() { Bits.Dispose(); }
}

class EntityHeap
{
    public BitfieldArray* Bits;
    public int32[256] Components;

    public this()
    {
        Bits = new BitfieldArray();
        Bits.Reserve(256);
    }

    public ~this()
    {
        Bits.Dispose();
        delete Bits;
    }
}

class EntityHeapArray
{
    public BitfieldArray Bits = .();
    public int32[] Components;

    public this()
    {
        Bits.Reserve(256);
        Components = new int32[256];
    }

    public ~this()
    {
        Bits.Dispose();
        delete Components;
    }
}

class EntitySparseMap
{
    public BitfieldArray ActiveSlots = .();
    public uint8[256] SlotMapping = .();
    public List<int32> Components = new .();

    public this()
    {
        ActiveSlots.Reserve(256);
    }

    public ~this()
    {
        ActiveSlots.Dispose();
        delete Components;
    }
}

class EntitySparseMapHeap
{
    public BitfieldArray ActiveSlots = .();
    public uint8[] SlotMapping;
    public List<int32> Components = new .();

    public this()
    {
        ActiveSlots.Reserve(256);
        SlotMapping = new uint8[256];
    }

    public ~this()
    {
        ActiveSlots.Dispose();
        delete Components;
        delete SlotMapping;
    }
}

static class EntityBenchmarks
{
    private static List<EntityInline> mEntitiesInline;
    private static List<EntityHeap> mEntitiesHeap;
    private static List<EntityHeapArray> mEntitiesHeapArray;
    private static List<EntitySparseMap> mEntitiesSparseMap;
    private static List<EntitySparseMapHeap> mEntitiesSparseMapHeap;

    public static int64 sAccumulator = 0;

    public static void Setup()
    {
        // Entity Setup
        mEntitiesInline = new .();
        mEntitiesHeap = new .();
        mEntitiesHeapArray = new .();
        mEntitiesSparseMap = new .();
        mEntitiesSparseMapHeap = new .();
        
        for (int i = 0; i < 1000; i++)
        {
            let inlineEnt = new EntityInline();
            let heapEnt = new EntityHeap();
            let heapArrayEnt = new EntityHeapArray();
            let sparseMapEnt = new EntitySparseMap();
            let sparseMapHeapEnt = new EntitySparseMapHeap();

            // Set some random-ish bits (Sparse)
            for (int j = 0; j < 256; j++)
            {
                if ((i + j) % 10 == 0)
                {
                    inlineEnt.Bits.SetBit(j);
                    heapEnt.Bits.SetBit(j);
                    heapArrayEnt.Bits.SetBit(j);

                    sparseMapEnt.ActiveSlots.SetBit(j);
                    sparseMapEnt.Components.Add((int32)(i + j));
                    sparseMapEnt.SlotMapping[j] = (uint8)sparseMapEnt.Components.Count;

                    sparseMapHeapEnt.ActiveSlots.SetBit(j);
                    sparseMapHeapEnt.Components.Add((int32)(i + j));
                    sparseMapHeapEnt.SlotMapping[j] = (uint8)sparseMapHeapEnt.Components.Count;
                }
                inlineEnt.Components[j] = (int32)(i + j);
                heapEnt.Components[j] = (int32)(i + j);
                heapArrayEnt.Components[j] = (int32)(i + j);
            }

            mEntitiesInline.Add(inlineEnt);
            mEntitiesHeap.Add(heapEnt);
            mEntitiesHeapArray.Add(heapArrayEnt);
            mEntitiesSparseMap.Add(sparseMapEnt);
            mEntitiesSparseMapHeap.Add(sparseMapHeapEnt);
        }

        BenchmarkRegistry.Register("Entity_Inline_Check", new => Entity_Inline_Check, 10000, 5, 15, "Entity_Check_Dense", true);
        BenchmarkRegistry.Register("Entity_Heap_Check", new => Entity_Heap_Check, 10000, 5, 15, "Entity_Check_Dense");
        BenchmarkRegistry.Register("Entity_HeapArray_Check", new => Entity_HeapArray_Check, 10000, 5, 15, "Entity_Check_Dense");
        BenchmarkRegistry.Register("Entity_SparseMap_Check", new => Entity_SparseMap_Check, 10000, 5, 15, "Entity_Check_Sparse", true);
        BenchmarkRegistry.Register("Entity_SparseMapHeap_Check", new => Entity_SparseMapHeap_Check, 10000, 5, 15, "Entity_Check_Sparse");

        BenchmarkRegistry.Register("Entity_Inline_Iterate", new => Entity_Inline_Iterate, 10000, 5, 15, "Entity_Iterate_Dense", true);
        BenchmarkRegistry.Register("Entity_Heap_Iterate", new => Entity_Heap_Iterate, 10000, 5, 15, "Entity_Iterate_Dense");
        BenchmarkRegistry.Register("Entity_HeapArray_Iterate", new => Entity_HeapArray_Iterate, 10000, 5, 15, "Entity_Iterate_Dense");
        BenchmarkRegistry.Register("Entity_SparseMap_Iterate", new => Entity_SparseMap_Iterate, 10000, 5, 15, "Entity_Iterate_Sparse", true);
        BenchmarkRegistry.Register("Entity_SparseMapHeap_Iterate", new => Entity_SparseMapHeap_Iterate, 10000, 5, 15, "Entity_Iterate_Sparse");

        BenchmarkRegistry.Register("Entity_SparseMap_GetComponent", new => Entity_SparseMap_GetComponent, 10000, 5, 15, "Entity_GetComponent", true);
        BenchmarkRegistry.Register("Entity_SparseMapHeap_GetComponent", new => Entity_SparseMapHeap_GetComponent, 10000, 5, 15, "Entity_GetComponent");
    }

    public static void Teardown()
    {
        DeleteContainerAndItems!(mEntitiesInline);
        DeleteContainerAndItems!(mEntitiesHeap);
        DeleteContainerAndItems!(mEntitiesHeapArray);
        DeleteContainerAndItems!(mEntitiesSparseMap);
        DeleteContainerAndItems!(mEntitiesSparseMapHeap);
    }

    public static void Entity_Inline_Check()
    {
        for (let e in mEntitiesInline)
        {
            if (e.Bits.GetBit(5)) sAccumulator++;
        }
    }

    public static void Entity_Heap_Check()
    {
        for (let e in mEntitiesHeap)
        {
            if (e.Bits.GetBit(5)) sAccumulator++;
        }
    }

    public static void Entity_Inline_Iterate()
    {
        for (let e in mEntitiesInline)
        {
            for (let idx in e.Bits)
            {
                sAccumulator += e.Components[idx % 256];
            }
        }
    }

    public static void Entity_Heap_Iterate()
    {
        for (let e in mEntitiesHeap)
        {
            for (let idx in *e.Bits)
            {
                sAccumulator += e.Components[idx % 256];
            }
        }
    }

    public static void Entity_HeapArray_Check()
    {
        for (let e in mEntitiesHeapArray)
        {
            if (e.Bits.GetBit(5)) sAccumulator++;
        }
    }

    public static void Entity_HeapArray_Iterate()
    {
        for (let e in mEntitiesHeapArray)
        {
            for (let idx in e.Bits)
            {
                sAccumulator += e.Components[idx % 256];
            }
        }
    }

    public static void Entity_SparseMap_Check()
    {
        for (let e in mEntitiesSparseMap)
        {
            if (e.ActiveSlots.GetBit(5)) sAccumulator++;
        }
    }

    public static void Entity_SparseMap_Iterate()
    {
        for (let e in mEntitiesSparseMap)
        {
            for (let typeId in e.ActiveSlots)
            {
                let slot = e.SlotMapping[typeId];
                sAccumulator += e.Components[slot - 1];
            }
        }
    }

    public static void Entity_SparseMapHeap_Check()
    {
        for (let e in mEntitiesSparseMapHeap)
        {
            if (e.ActiveSlots.GetBit(5)) sAccumulator++;
        }
    }

    public static void Entity_SparseMapHeap_Iterate()
    {
        for (let e in mEntitiesSparseMapHeap)
        {
            for (let typeId in e.ActiveSlots)
            {
                let slot = e.SlotMapping[typeId];
                sAccumulator += e.Components[slot - 1];
            }
        }
    }

    public static void Entity_SparseMap_GetComponent()
    {
        // Simulate TryGetComponent<T> for a specific component (ID 20)
        // This tests the latency of: BitCheck -> Inline SlotLookup -> List Access
        for (let e in mEntitiesSparseMap)
        {
            if (e.ActiveSlots.GetBit(20))
            {
                let slot = e.SlotMapping[20];
                sAccumulator += e.Components[slot - 1];
            }
        }
    }

    public static void Entity_SparseMapHeap_GetComponent()
    {
        // Simulate TryGetComponent<T> for a specific component (ID 20)
        // This tests the latency of: BitCheck -> Heap SlotLookup -> List Access
        for (let e in mEntitiesSparseMapHeap)
        {
            if (e.ActiveSlots.GetBit(20))
            {
                let slot = e.SlotMapping[20];
                sAccumulator += e.Components[slot - 1];
            }
        }
    }
}
