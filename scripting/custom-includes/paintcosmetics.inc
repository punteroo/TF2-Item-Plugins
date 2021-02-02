#include <tf2idb>
#include <tf2attributes>

enum struct PaintedHat {
	// This enum controls a player's painted hats status.
	// A maximum of 3 painted hats can be used at a time.
	float values[3];
	int   hatIndex;
	
	void WriteValues(float[3] buffer) {
		for (int i = 0; i < 3; i++)
			buffer[i] = this.values[i];
	}
}

// Returns wether or not an Item Definition Index is paintable or not.
bool IsHatPaintable(int iItemDefinitionIndex)
{
	char strItemDefinitionIndex[32];
	IntToString(iItemDefinitionIndex, strItemDefinitionIndex, 32);
	
	ArrayList arg = CreateArray(sizeof(strItemDefinitionIndex));
	arg.PushString(strItemDefinitionIndex);
	
	DBStatement result = TF2IDB_CustomQuery("SELECT capability FROM tf2idb_capabilities WHERE id = ?", arg, sizeof(strItemDefinitionIndex));
	if (result != INVALID_HANDLE) {
		while (SQL_FetchRow(result)) {
			char capability[64];
			SQL_FetchString(result, 0, capability, sizeof(capability));
			
			if (StrEqual(capability, "paintable"))
				return true;
		}
	}
	return false;
}

// Writes an array of all paint values present on a CTFWearable entity index, if any.
// If there was no present paint, 0.0 is returned. Else just returns the paint value present.
void GetPaint(float[] val, int[] ids, int amount, float paints[3])
{
	for (int i = 0; i < amount; i++) {
		switch (ids[i]) {
			case 142:
				paints[0] = val[i];
			case 261:
				paints[1] = val[i];
			case 1004:
				paints[2] = val[i];
		}
	}
}


#if defined _INCLUDE_included
 #endinput
#endif
#define _INCLUDE_included