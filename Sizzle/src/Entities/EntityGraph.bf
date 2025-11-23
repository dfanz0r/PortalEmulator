using System;
using System.Collections;
using Sizzle.Math;
using Sizzle.Core;

using internal Sizzle.Entities;

namespace Sizzle.Entities;

/// @brief Manages a graph of entities, handling their hierarchy and transforms.
/// @remarks This class implements a Structure-of-Arrays (SoA) layout for entity data to optimize cache coherence.
/// It supports up to `MaxEntities` entities per graph.
class EntityGraph
{
	/// @brief The maximum number of entities that can be managed by a single graph.
	/// @remarks Reduced by 1 because 0 is reserved as an invalid slot ID in EntityID.
	public const int MaxEntities = 1048575;

	/// @brief Static storage for all entity graphs, indexed by graph ID.
	private static EntityGraph[4096] sGraphs = .() ~ Shutdown();
	private static bool sIsShutdown = false;

	/// @brief Clears up all allocated entity graphs on shutdown.
	private static void Shutdown()
	{
		sIsShutdown = true;
		for (int i = 0; i < sGraphs.Count; i++)
		{
			if (sGraphs[i] != null)
			{
				delete sGraphs[i];
				sGraphs[i] = null;
			}
		}
	}

	/// @brief The unique identifier for this graph.
	private int32 mGraphId;
	/// @brief Bitfield tracking which slots are currently in use.
	private BitfieldArray mAllocatedSlots = .();

	/// @brief Bitfield tracking which entities have dirty transforms that need updating.
	private BitfieldArray mDirtyFlags = .();

	// Hierarchy
	/// @brief Stores the parent entity ID for each slot. -1 indicates no parent.
	private List<int32> mParentIds = new .() ~ delete _;
	/// @brief Stores the first child entity ID for each slot. -1 indicates no children.
	private List<int32> mFirstChildIds = new .() ~ delete _;
	/// @brief Stores the next sibling entity ID for each slot. -1 indicates no next sibling.
	private List<int32> mNextSiblingIds = new .() ~ delete _;
	/// @brief Stores the previous sibling entity ID for each slot. -1 indicates no previous sibling.
	private List<int32> mPrevSiblingIds = new .() ~ delete _;
	/// @brief Stores the depth of each entity in the hierarchy. Root entities are at depth 0.
	private List<int32> mDepths = new .() ~ delete _;

	// Transforms
	/// @brief Stores the world transformation data (VQS) for each entity.
	private List<TransformData> mWorldTransforms = new .() ~ delete _;

	/// @brief Stores the cached world matrices for each entity.
	private List<Matrix4x4> mWorldMatrices = new .() ~ delete _;

	/// @brief Stores the raw transform data (position, rotation, scale) for each entity.
	private List<Transform3D> mTransforms = new .() ~ delete _;

	/// @brief Stores the GameEntity for each slot.
	private List<GameEntity> mEntities = new .() ~ delete _;

	/// @brief Initializes a new instance of the EntityGraph class.
	/// @param graphId The unique ID for this graph.
	public this(int32 graphId)
	{
		mGraphId = graphId;
		mAllocatedSlots.Reserve(MaxEntities);
		mDirtyFlags.Reserve(MaxEntities);
	}

	/// @brief Destructor that cleans up allocated resources.
	public ~this()
	{
		mAllocatedSlots.Dispose();
		mDirtyFlags.Dispose();
	}

	/// @brief Retrieves the entity graph for the specified ID, creating it if it doesn't exist.
	/// @param id The graph ID to retrieve.
	/// @return The EntityGraph instance.

	[Inline]
	public static EntityGraph GetOrCreate(int32 id)
	{
		if (sIsShutdown)
			Runtime.FatalError("Accessing EntityGraph after shutdown");

		ref EntityGraph graphSlot = ref sGraphs[id];
		if (graphSlot == null)
			graphSlot = new EntityGraph(id);

		return graphSlot;
	}

	/// @brief Creates a new entity in this graph with a Transform3D component.
	/// @return The created GameEntity.
	public GameEntity CreateEntity()
	{
		GameEntity entity = new GameEntity(mGraphId);
		Transform3D transform;
		entity.TryCreateComponent<Transform3D>(out transform);
		TryRegisterEntity(entity);
		return entity;
	}

	/// @brief Allocates a new slot for an entity in the graph.
	/// @return The index of the allocated slot.
	internal int32 AllocateSlot()
	{
		int slot = mAllocatedSlots.FindFirstClear();
		if (slot == -1) slot = mAllocatedSlots.Capacity;
		mAllocatedSlots.SetBit(slot);

		EnsureCapacity(slot + 1);

		mParentIds[slot] = -1;
		mFirstChildIds[slot] = -1;
		mNextSiblingIds[slot] = -1;
		mPrevSiblingIds[slot] = -1;
		mDepths[slot] = 0;
		mWorldTransforms[slot] = .Identity;
		mWorldMatrices[slot] = .Identity();
		mTransforms[slot] = null;
		mDirtyFlags.SetBit(slot);

		return (int32)slot + 1;
	}

	/// @brief Frees a previously allocated slot.
	/// @param slot The index of the slot to free.
	public void FreeSlot(int32 slot)
	{
		int32 internalSlot = slot - 1;
		if (internalSlot < 0 || internalSlot >= mAllocatedSlots.Capacity) return;

		mAllocatedSlots.ClearBit(internalSlot);
		mTransforms[internalSlot] = null;
		mEntities[internalSlot] = null;

		// Detach children
		int32 child = mFirstChildIds[internalSlot];
		while (child != -1)
		{
			mParentIds[child] = -1;
			int32 next = mNextSiblingIds[child];
			mPrevSiblingIds[child] = -1;
			mNextSiblingIds[child] = -1;
			child = next;
		}
		mFirstChildIds[internalSlot] = -1;

		// Ideally we should detach from parent here too if not already done
		int32 parent = mParentIds[internalSlot];
		if (parent != -1)
		{
			RemoveChild(parent, internalSlot);
			mParentIds[internalSlot] = -1;
		}
	}

	/// @brief Ensures that the internal arrays have enough capacity to accommodate the specified count.
	/// @param count The required capacity.
	private void EnsureCapacity(int count)
	{
		if (mParentIds.Count < count)
		{
			int grow = count - mParentIds.Count;
			for (int i = 0; i < grow; i++)
			{
				mParentIds.Add(-1);
				mFirstChildIds.Add(-1);
				mNextSiblingIds.Add(-1);
				mPrevSiblingIds.Add(-1);
				mDepths.Add(0);
				mWorldTransforms.Add(.Identity);
				mWorldMatrices.Add(.Identity());
				mTransforms.Add(null);
				mEntities.Add(null);
			}
		}
	}

	/// @brief Gets the graph ID from an entity ID.
	[Inline]
	public static int32 GetGraphId(EntityID entityId) => (int32)entityId.GraphId;

	/// @brief Gets the slot ID from an entity ID.
	[Inline]
	public static int32 GetSlotId(EntityID entityId) => (int32)entityId.GraphSlotId;

	/// @brief Registers an entity with the graph, associating its transform and ID.
	/// @param entity The entity to register.
	/// @return True if the entity has a transform and it was registered, false otherwise.
	public bool TryRegisterEntity(GameEntity entity)
	{
		int32 slot = AllocateSlot();
		var id = entity.EntityId;
		id.GraphSlotId = (uint32)slot;
		entity.[Friend]runtimeEntityId = id;

		int32 internalSlot = slot - 1;
		mEntities[internalSlot] = entity;

		Transform3D transform = null;
		if (entity.TryGetComponent<Transform3D>(out transform))
		{
			mTransforms[internalSlot] = transform;
			if (transform.Parent != null)
			{
				SetParent(entity.EntityId, transform.Parent);
			}
			MarkDirty(entity.EntityId);
			return true;
		}

		return false;
	}

	/// @brief Marks an entity's transform as dirty, triggering a recalculation of matrices.
	/// @param entityId The entity ID.
	[Inline]
	public void MarkDirty(EntityID entityId)
	{
		int32 slot = (int32)entityId.GraphSlotId - 1;
		if (slot >= 0)
		{
			mDirtyFlags.SetBit(slot);
		}
	}

	/// @brief Tries to get the transform component of the parent of the specified entity.
	/// @param entityId The entity ID.
	/// @param parentTransform The output parent transform.
	/// @return True if the parent exists and was retrieved, false otherwise.
	public bool TryGetParentTransform(EntityID entityId, out Transform3D parentTransform)
	{
		parentTransform = null;
		int32 slotId = (int32)entityId.GraphSlotId - 1;
		if (!mAllocatedSlots.GetBit(slotId)) return false;

		int32 parentSlot = mParentIds[slotId];
		if (parentSlot != -1)
		{
			parentTransform = mTransforms[parentSlot];
			return true;
		}
		return false;
	}

	/// @brief Tries to get the world transformation matrix for the specified entity.
	/// @param entityId The entity ID.
	/// @param worldMatrix The output world matrix.
	/// @return True if the matrix is valid (not dirty) and was retrieved, false otherwise.
	public bool TryGetWorldMatrix(EntityID entityId, out Matrix4x4 worldMatrix)
	{
		int32 slotId = (int32)entityId.GraphSlotId - 1;

		if (!mAllocatedSlots.GetBit(slotId) || mDirtyFlags.GetBit(slotId))
		{
			worldMatrix = .Identity();
			return false;
		}

		worldMatrix = mWorldMatrices[slotId];
		return true;
	}

	/// @brief Tries to get the local transformation matrix for the specified entity.
	/// @param entityId The entity ID.
	/// @param localMatrix The output local matrix.
	/// @return True if the matrix is valid (not dirty) and was retrieved, false otherwise.
	public bool TryGetLocalMatrix(EntityID entityId, out Matrix4x4 localMatrix)
	{
		localMatrix = .Identity();
		int32 slotId = (int32)entityId.GraphSlotId - 1;
		if (!mAllocatedSlots.GetBit(slotId)) return false;

		Transform3D transform = mTransforms[slotId];
		if (transform != null)
		{
			localMatrix = Matrix4x4.TRS(transform.Position, transform.Rotation, transform.Scale);
			return true;
		}
		return false;
	}

	/// @brief Sets the parent for a child entity.
	/// @param childEntityId The entity ID of the child.
	/// @param parent The transform of the new parent entity, or null to detach.
	public void SetParent(EntityID childEntityId, Transform3D parent)
	{
		int32 childSlot = (int32)childEntityId.GraphSlotId - 1;
		if (childSlot < 0) return;

		int32 parentSlot = -1;
		if (parent != null)
		{
			parentSlot = GetSlotId(GameEntity.GetEntityId(parent.EntityId)) - 1;
		}

		SetParentInternal(childSlot, parentSlot);
	}

	/// @brief Internal helper to update parent-child relationships and depths.
	/// @param childSlot The slot index of the child.
	/// @param parentSlot The slot index of the new parent.
	private void SetParentInternal(int32 childSlot, int32 parentSlot)
	{
		int32 oldParent = mParentIds[childSlot];
		if (oldParent != -1)
		{
			RemoveChild(oldParent, childSlot);
		}

		mParentIds[childSlot] = parentSlot;

		if (parentSlot != -1)
		{
			AddChild(parentSlot, childSlot);
			UpdateDepth(childSlot, mDepths[parentSlot] + 1);
		}
		else
		{
			UpdateDepth(childSlot, 0);
		}

		mDirtyFlags.SetBit(childSlot);
	}

	/// @brief Removes a child from a parent's list of children.
	/// @param parentSlot The slot index of the parent.
	/// @param childSlot The slot index of the child to remove.
	private void RemoveChild(int32 parentSlot, int32 childSlot)
	{
		int32 prev = mPrevSiblingIds[childSlot];
		int32 next = mNextSiblingIds[childSlot];

		if (prev != -1)
			mNextSiblingIds[prev] = next;
		else
			mFirstChildIds[parentSlot] = next;

		if (next != -1)
			mPrevSiblingIds[next] = prev;

		mPrevSiblingIds[childSlot] = -1;
		mNextSiblingIds[childSlot] = -1;
	}

	/// @brief Adds a child to a parent's list of children.
	/// @param parentSlot The slot index of the parent.
	/// @param childSlot The slot index of the child to add.
	private void AddChild(int32 parentSlot, int32 childSlot)
	{
		int32 first = mFirstChildIds[parentSlot];
		mNextSiblingIds[childSlot] = first;
		if (first != -1)
			mPrevSiblingIds[first] = childSlot;
		mFirstChildIds[parentSlot] = childSlot;
		mPrevSiblingIds[childSlot] = -1;
	}

	/// @brief Recursively updates the depth of a slot and its descendants.
	/// @param slot The slot index to update.
	/// @param depth The new depth value.
	private void UpdateDepth(int32 slot, int32 depth)
	{
		mDepths[slot] = depth;
		int32 child = mFirstChildIds[slot];
		while (child != -1)
		{
			UpdateDepth(child, depth + 1);
			child = mNextSiblingIds[child];
		}
	}


	/*[ThreadStatic]*/
	// todo - if we move to having multi-threaded processing this needs to be changed
	static List<int32> descendantStack = new .() ~ delete _;

	/// @brief Collects a slot and all its descendants into a list.
	/// @param slot The root slot to start collecting from.
	/// @param list The list to populate.
	private void CollectDescendants(int32 slot, List<int32> list)
	{
		descendantStack.Add(slot);

		while (!descendantStack.IsEmpty)
		{
			int32 curr = descendantStack.PopBack();
			list.Add(curr);

			int32 child = mFirstChildIds[curr];
			while (child != -1)
			{
				descendantStack.Add(child);
				child = mNextSiblingIds[child];
			}
		}
	}

	// todo - if we move to having multi-threaded processing this needs to be changed
	static List<int32> updateList = new .() ~ delete _;

	/// @brief Updates transforms for all dirty entities and their descendants.
	/// @remarks This method sorts updates by depth to ensure parents are processed before children.
	public void UpdateTransforms()
	{
		// ensure the updateList is always cleared before leaving this function
		// Since this instance is reused between ALL EntityGraph instances
		defer updateList.Clear();

		for (let slot in mDirtyFlags)
		{
			int32 parent = mParentIds[slot];
			if (parent == -1 || !mDirtyFlags.GetBit(parent))
			{
				CollectDescendants((int32)slot, updateList);
			}
		}

		updateList.Sort((a, b) => mDepths[a] <=> mDepths[b]);

		for (int32 slot in updateList)
		{
			Transform3D transform = mTransforms[slot];
			if (transform != null)
			{
				ref TransformData local = ref transform.[Friend]mInternalState;
				int32 parent = mParentIds[slot];
				if (parent != -1)
				{
					ref TransformData parentWorld = ref mWorldTransforms[parent];

					// 1. World Scale
					Vector3 worldScale = parentWorld.Scale * local.Scale;

					// 2. World Rotation
					Quaternion worldRotation = parentWorld.Rotation * local.Rotation;

					// 3. World Position
					// Scale Offset
					Vector3 offset = local.Position * parentWorld.Scale;
					// Rotate Offset
					Vector3 rotatedOffset = parentWorld.Rotation.Rotate(offset);
					// Translate
					Vector3 worldPosition = parentWorld.Position + rotatedOffset;

					mWorldTransforms[slot] = .(worldRotation, worldPosition, worldScale);
				}
				else
				{
					mWorldTransforms[slot] = local;
				}

				ref TransformData world = ref mWorldTransforms[slot];
				mWorldMatrices[slot] = Matrix4x4.TRS(world.Position, world.Rotation, world.Scale);
			}
			mDirtyFlags.ClearBit(slot);
		}
	}

	/// @brief Safely frees a slot without creating a new graph if it doesn't exist or during shutdown.
	public static void SafeFreeSlot(int32 graphId, int32 slotId)
	{
		if (sIsShutdown) return;
		if (sGraphs[graphId] != null)
		{
			sGraphs[graphId].FreeSlot(slotId);
		}
	}
}