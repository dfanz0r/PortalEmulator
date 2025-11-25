using System;
using System.Interop;

namespace Assimp;

public static class Assimp
{
	const String LibName = "assimp-vc143-mt.dll";

	[CRepr]
	public struct aiString
	{
		public uint32 length;
		public char8[1024] data;

		public void ToString(String outString) mut
		{
			outString.Append((char8*)&data, (int)length);
		}
	}

	[CRepr]
	public struct aiVector3D
	{
		public float x, y, z;
	}

	[CRepr]
	public struct aiVector2D
	{
		public float x, y;
	}

	[CRepr]
	public struct aiColor4D
	{
		public float r, g, b, a;
	}

	[CRepr]
	public struct aiMatrix4x4
	{
		public float a1, a2, a3, a4;
		public float b1, b2, b3, b4;
		public float c1, c2, c3, c4;
		public float d1, d2, d3, d4;
	}

	[CRepr]
	public struct aiFace
	{
		public uint32 mNumIndices;
		public uint32* mIndices;
	}

	[CRepr]
	public struct aiMesh
	{
		public uint32 mPrimitiveTypes;
		public uint32 mNumVertices;
		public uint32 mNumFaces;
		public aiVector3D* mVertices;
		public aiVector3D* mNormals;
		public aiVector3D* mTangents;
		public aiVector3D* mBitangents;
		public aiColor4D*[8] mColors;
		public aiVector3D*[8] mTextureCoords;
		public uint32[8] mNumUVComponents;

		public aiFace* mFaces;
		public uint32 mNumBones;
		public void* mBones; // aiBone**
		public uint32 mMaterialIndex;
		public aiString mName;
		public uint32 mNumAnimMeshes;
		public void* mAnimMeshes; // aiAnimMesh**
		public uint32 mMethod;
        public void* mAABB; // aiAABB
	}

	[CRepr]
	public struct aiNode
	{
		public aiString mName;
		public aiMatrix4x4 mTransformation;
		public aiNode* mParent;
		public uint32 mNumChildren;
		public aiNode** mChildren;
		public uint32 mNumMeshes;
		public uint32* mMeshes;
		public void* mMetaData; // aiMetadata*
	}

	[CRepr]
	public struct aiScene
	{
		public uint32 mFlags;
		public aiNode* mRootNode;
		public uint32 mNumMeshes;
		public aiMesh** mMeshes;
		public uint32 mNumMaterials;
		public aiMaterial** mMaterials; // aiMaterial**
		public uint32 mNumAnimations;
		public void** mAnimations; // aiAnimation**
		public uint32 mNumTextures;
		public aiTexture** mTextures; // aiTexture**
		public uint32 mNumLights;
		public void** mLights; // aiLight**
		public uint32 mNumCameras;
		public void** mCameras; // aiCamera**
        public void* mMetaData; // aiMetadata*
        public aiString mName;
        public uint32 mNumSkeletons;
        public void** mSkeletons; // aiSkeleton**
        public void* mPrivate;
	}

    public enum aiSceneFlags : uint32
    {
        INCOMPLETE = 0x1,
        VALIDATED = 0x2,
        VALIDATION_WARNING = 0x4,
        NON_VERBOSE_FORMAT = 0x8,
        TERRAIN = 0x10,
        ALLOW_SHARED = 0x20
    }

    public enum aiReturn : int32
    {
        SUCCESS = 0,
        FAILURE = -1,
        OUTOFMEMORY = -3
    }

    [CRepr]
    public struct aiTexel
    {
        public uint8 b, g, r, a;
    }

    [CRepr]
    public struct aiTexture
    {
        public uint32 mWidth;
        public uint32 mHeight;
        public char8[9] achFormatHint;
        public aiTexel* pcData;
        public aiString mFilename;
    }

    public enum aiPropertyTypeInfo : int32
    {
        Float = 0x1,
        Double = 0x2,
        String = 0x3,
        Integer = 0x4,
        Buffer = 0x5
    }

    [CRepr]
    public struct aiMaterialProperty
    {
        public aiString mKey;
        public uint32 mSemantic;
        public uint32 mIndex;
        public uint32 mDataLength;
        public aiPropertyTypeInfo mType;
        public uint8* mData;
    }

    [CRepr]
    public struct aiMaterial
    {
        public aiMaterialProperty** mProperties;
        public uint32 mNumProperties;
        public uint32 mNumAllocated;
    }

    public enum aiTextureType : int32
	{
		NONE = 0,
		DIFFUSE = 1,
		SPECULAR = 2,
		AMBIENT = 3,
		EMISSIVE = 4,
		HEIGHT = 5,
		NORMALS = 6,
		SHININESS = 7,
		OPACITY = 8,
		DISPLACEMENT = 9,
		LIGHTMAP = 10,
		REFLECTION = 11,
		BASE_COLOR = 12,
		NORMAL_CAMERA = 13,
		EMISSION_COLOR = 14,
		METALNESS = 15,
		DIFFUSE_ROUGHNESS = 16,
		AMBIENT_OCCLUSION = 17,
		UNKNOWN = 18,
		SHEEN = 19,
		CLEARCOAT = 20,
		TRANSMISSION = 21,
		MAYA_BASE = 22,
		MAYA_SPECULAR = 23,
		MAYA_SPECULAR_COLOR = 24,
		MAYA_SPECULAR_ROUGHNESS = 25,
		ANISOTROPY = 26,
		GLTF_METALLIC_ROUGHNESS = 27,
	}
    
    public enum aiTextureOp : int32
    {
        Multiply = 0x0,
        Add = 0x1,
        Subtract = 0x2,
        Divide = 0x3,
        SmoothAdd = 0x4,
        SignedAdd = 0x5,
    }

    public enum aiTextureMapMode : int32
    {
        Wrap = 0x0,
        Clamp = 0x1,
        Decal = 0x3,
        Mirror = 0x2,
    }

    public enum aiTextureMapping : int32
    {
        UV = 0x0,
        SPHERE = 0x1,
        CYLINDER = 0x2,
        BOX = 0x3,
        PLANE = 0x4,
        OTHER = 0x5,
    }

    public enum aiPostProcessSteps : uint32
    {
        CalcTangentSpace = 0x1,
        JoinIdenticalVertices = 0x2,
        MakeLeftHanded = 0x4,
        Triangulate = 0x8,
        RemoveComponent = 0x10,
        GenNormals = 0x20,
        GenSmoothNormals = 0x40,
        SplitLargeMeshes = 0x80,
        PreTransformVertices = 0x100,
        LimitBoneWeights = 0x200,
        ValidateDataStructure = 0x400,
        ImproveCacheLocality = 0x800,
        RemoveRedundantMaterials = 0x1000,
        FixInfacingNormals = 0x2000,
        SortByPType = 0x8000,
        FindDegenerates = 0x10000,
        FindInvalidData = 0x20000,
        GenUVCoords = 0x40000,
        TransformUVCoords = 0x80000,
        FindInstances = 0x100000,
        OptimizeMeshes = 0x200000,
        OptimizeGraph = 0x400000,
        FlipUVs = 0x800000,
        FlipWindingOrder = 0x01000000,
        SplitByBoneCount = 0x02000000,
        Debone = 0x04000000,
        GlobalScale = 0x08000000,
        EmbedTextures = 0x10000000,
        ForceGenNormals = 0x20000000,
        DropNormals = 0x40000000,
        GenBoundingBoxes = 0x80000000
    }

	[Import(LibName), CLink]
	public static extern aiScene* aiImportFile(char8* pFile, uint32 pFlags);

	[Import(LibName), CLink]
	public static extern void aiReleaseImport(aiScene* pScene);

	[Import(LibName), CLink]
	public static extern char8* aiGetErrorString();
    
    [Import(LibName), CLink]
    public static extern aiScene* aiImportFileFromMemory(char8* pBuffer, uint32 pLength, uint32 pFlags, char8* pHint);

    [Import(LibName), CLink]
    public static extern aiReturn aiGetMaterialTexture(aiMaterial* mat, aiTextureType type, uint32 index, aiString* path, aiTextureMapping* mapping, uint32* uvindex, float* blend, aiTextureOp* op, aiTextureMapMode* mapmode, uint32* flags);

    [Import(LibName), CLink]
    public static extern aiReturn aiGetMaterialString(aiMaterial* pMat, char8* pKey, uint32 type, uint32 index, aiString* pOut);

    [Import(LibName), CLink]
    public static extern aiReturn aiGetMaterialColor(aiMaterial* pMat, char8* pKey, uint32 type, uint32 index, aiColor4D* pOut);
    
    [Import(LibName), CLink]
    public static extern aiReturn aiGetMaterialFloatArray(aiMaterial* pMat, char8* pKey, uint32 type, uint32 index, float* pOut, uint32* pMax);

    [Import(LibName), CLink]
    public static extern aiReturn aiGetMaterialIntegerArray(aiMaterial* pMat, char8* pKey, uint32 type, uint32 index, int32* pOut, uint32* pMax);

    public const char8* AI_MATKEY_NAME = "?mat.name";
    public const char8* AI_MATKEY_COLOR_DIFFUSE = "$clr.diffuse";
    public const char8* AI_MATKEY_COLOR_AMBIENT = "$clr.ambient";
    public const char8* AI_MATKEY_COLOR_SPECULAR = "$clr.specular";
    public const char8* AI_MATKEY_COLOR_EMISSIVE = "$clr.emissive";
    public const char8* AI_MATKEY_COLOR_TRANSPARENT = "$clr.transparent";
    public const char8* AI_MATKEY_COLOR_REFLECTIVE = "$clr.reflective";
    public const char8* AI_MATKEY_SHININESS = "$mat.shininess";
    public const char8* AI_MATKEY_OPACITY = "$mat.opacity";
    public const char8* AI_MATKEY_SHADING_MODEL = "$mat.shadingm";
}
