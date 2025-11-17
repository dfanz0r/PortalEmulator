using System.Collections;
using System;

namespace Sizzle.Core;

/// @brief Iterator adapter that automatically skips null elements in a collection.
/// @remarks Useful for sparse arrays or collections where null entries should be ignored.
public struct NullSkipEnumerator<T> : IEnumerator<T>
{
	/// @brief The underlying enumerator being wrapped.
	IEnumerator<T> mEnumerator;

	/// @brief Constructs a null-skipping enumerator from any enumerable collection.
	/// @param instance The collection to enumerate over.
	internal this<TEnumerable>(TEnumerable instance) where TEnumerable : IEnumerable<T>
	{
		mEnumerator = instance.GetEnumerator();
	}

	/// @brief Advances to the next non-null element in the collection.
	/// @returns Ok with the next non-null element, or Err if no more elements exist.
	public Result<T> GetNext()
	{
		// Skip any null values in the array
		while (mEnumerator.GetNext() case .Ok(let val))
		{
			if (val != null)
			{
				return .Ok(val);
			}
		}

		return .Err;
	}
}