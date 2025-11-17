using System;
using PortalEmulator.Sizzle.Core;
using Sizzle.Entities;

namespace Sizzle.Tests;

[RegisterComponent]
class TestComponentC : IGameComponent
{
    public void OnStart() { }
    public void OnEnable() { }
    public void OnDisable() { }
}

static class GameEntityTests
{
    [Test]
    public static void GameEntity_DefaultsToEnabledState()
    {
        GameEntity entity = scope .();

        Test.Assert(entity.EnabledSelf);
        Test.Assert(entity.Enabled);

        entity.EnabledSelf = false;
        Test.Assert(!entity.EnabledSelf);
        Test.Assert(!entity.Enabled);

        entity.EnabledSelf = true;
        Test.Assert(entity.EnabledSelf);
        Test.Assert(entity.Enabled);
    }

    [Test]
    public static void GameEntity_CanAddAndRetrieveComponent()
    {
        GameEntity entity = scope .();

        TestComponentA component;
        Test.Assert(entity.TryCreateComponent(out component));
        Test.Assert(component != null);
        Test.Assert(entity.HasComponentType<TestComponentA>());

        TestComponentA retrieved;
        Test.Assert(entity.TryGetComponent(out retrieved));
        Test.Assert(retrieved == component);
        Test.Assert(component.EntityId != 0);
    }

    [Test]
    public static void GameEntity_DuplicateComponentCreationFails()
    {
        GameEntity entity = scope .();

        TestComponentA first;
        Test.Assert(entity.TryCreateComponent(out first));

        TestComponentA duplicate;
        Test.Assert(!entity.TryCreateComponent(out duplicate));
        Test.Assert(duplicate == null);
    }

    [Test]
    public static void GameEntity_HasComponentTypeReflectsState()
    {
        GameEntity entity = scope .();

        Test.Assert(!entity.HasComponentType<TestComponentC>());

        TestComponentC component;
        Test.Assert(entity.TryCreateComponent(out component));
        Test.Assert(entity.HasComponentType<TestComponentC>());

        Test.Assert(entity.TryRemoveComponent<TestComponentC>());
        Test.Assert(!entity.HasComponentType<TestComponentC>());
        Test.Assert(!entity.TryRemoveComponent<TestComponentC>());
    }

    [Test]
    public static void GameEntity_TryGetComponentReturnsFalseWhenMissing()
    {
        GameEntity entity = scope .();

        TestComponentB component;
        Test.Assert(!entity.TryGetComponent(out component));
        Test.Assert(component == null);
    }

    [Test]
    public static void GameEntity_RemoveComponentClearsState()
    {
        GameEntity entity = scope .();

        TestComponentA component;
        Test.Assert(entity.TryCreateComponent(out component));
        Test.Assert(entity.HasComponentType<TestComponentA>());

        Test.Assert(entity.TryRemoveComponent<TestComponentA>());
        Test.Assert(!entity.HasComponentType<TestComponentA>());

        TestComponentA replacement;
        Test.Assert(entity.TryCreateComponent(out replacement));
        Test.Assert(replacement != null);
    }

    [Test]
    public static void GameEntity_RemoveByInstanceOverloadRemovesComponent()
    {
        GameEntity entity = scope .();

        TestComponentB component;
        Test.Assert(entity.TryCreateComponent(out component));
        Test.Assert(component != null);

        Test.Assert(entity.TryRemoveComponent(component));
        Test.Assert(!entity.HasComponentType<TestComponentB>());
    }

    [Test]
    public static void GameEntity_ReusesSlotWhenReaddingComponent()
    {
        GameEntity entity = scope .();

        TestComponentA component;
        Test.Assert(entity.TryCreateComponent(out component));
        int originalIndex = entity.GetComponentIndex<TestComponentA>();

        Test.Assert(entity.TryRemoveComponent<TestComponentA>());

        TestComponentA replacement;
        Test.Assert(entity.TryCreateComponent(out replacement));

        Test.Assert(entity.GetComponentIndex<TestComponentA>() == originalIndex);
    }

    [Test]
    public static void GameEntity_AssignsDistinctSlotsPerComponentType()
    {
        GameEntity entity = scope .();

        TestComponentA componentA;
        TestComponentB componentB;
        Test.Assert(entity.TryCreateComponent(out componentA));
        Test.Assert(entity.TryCreateComponent(out componentB));

        int indexA = entity.GetComponentIndex<TestComponentA>();
        int indexB = entity.GetComponentIndex<TestComponentB>();

        Test.Assert(indexA != indexB);
        Test.Assert(indexA >= 0 && indexB >= 0);
    }

    [Test]
    public static void GameEntity_ComponentEnumeratorSkipsNullSlots()
    {
        GameEntity entity = scope .();

        TestComponentA componentA;
        TestComponentB componentB;
        Test.Assert(entity.TryCreateComponent(out componentA));
        Test.Assert(entity.TryCreateComponent(out componentB));

        Test.Assert(entity.TryRemoveComponent<TestComponentB>());

        // Sanity check: the active-slot state should be updated by removal
        Test.Assert(entity.HasComponentType<TestComponentA>());
        Test.Assert(!entity.HasComponentType<TestComponentB>());

        var enumerator = entity.GetComponentEnumerator();
        int enumerated = 0;
        while (enumerator.GetNext() case .Ok(let component))
        {
            Console.WriteLine(scope $"{enumerated}: {(component != null) ? component.GetType().GetName(.. scope .()) : "null"}");
            Test.Assert(component != null);
            Test.Assert(component is TestComponentA);
            enumerated++;
        }

        Test.Assert(enumerated == 1);
    }
}
