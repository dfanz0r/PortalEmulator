using System;
using System.Collections;
namespace PortalEmulator.Sizzle.Core;

[AttributeUsage(.Enum)]
struct StaticEnumKVAttribute : Attribute, IOnTypeInit
{
	[Comptime]
	public void OnTypeInit(Type type, Self* prev)
	{
		List<String> keys = scope .();
		for (var val in type.GetFields())
		{
			String tmpStr = new String(100);
			val.Name.ToString(tmpStr);
			keys.Add(tmpStr);
		}

		var typeName = new String(100);
		type.GetName(typeName);

		String vals = scope $"";
		for (var str in keys)
		{
			vals.AppendF($".{str},");
		}

		String enumKeys = scope $"";
		for (var str in keys)
		{
			enumKeys.AppendF($"\"{str}\",");
		}

		var code = scope $"public const String[?] Keys = String[] ({enumKeys});\n";
		var code2 = scope $"public const {typeName}[?] Values = {typeName}[] ({vals});\n";

		Compiler.EmitTypeBody(type, scope $"{code}\n");
		Compiler.EmitTypeBody(type, scope $"{code2}\n");
	}
}