enum struct KsClient {
	// Integer Array with selected type of Killstreak from our client.
	int 	type[3];
	// Same but for Sheens.
	int 	sheen[3];
	// Same but for Killstreakers.
	int 	streaker[3];
	
	// Temporary slot integer for handling user selections.
	int 	slot;
	
	// All Mode boolean.
	bool 	all;
}


/*

METHODMAPS SUCK COCK BRO

methodmap KsClient < StringMap {
	public KsClient() {
		return view_as<KsClient>(new StringMap());
	}
	
	// Initializes all values to 0
	public void Initialize() {
		this.SetValue("type", 		0.0);
		this.SetValue("sheen", 		0.0);
		this.SetValue("streaker",	0.0);
		this.SetValue("all", 		false);
	}
	
	// Temporary slot selection. Stores the selected slot on the menu to work with.
	public void SetSlot(int slot) {
		this.SetValue("slot", slot);
	}
	
	// Temporary slot selection. Gets the selected slot on the menu to work with.
	public int GetSlot() {
		int slot;
		this.GetValue("slot", slot);
		
		return slot;
	}
	
	// Sets the type of Killstreak the client chose.
	public void SetType(float val, int slot) {
		bool all;
		this.GetValue("all", all);
		
		if (!all) {
			float type[3];
			this.GetArray("type", type, sizeof(type));
			
			type[slot] = val;
			this.SetArray("type", type, sizeof(type));
		}
		else
			this.SetValue("type", val);
	}
		
	// Sets the sheen of a Specialized Killstreak the client chose.
	public void SetSheen(float val, int slot) {
		bool all;
		this.GetValue("all", all);
		
		if (!all) {
			float sheen[3];
			this.GetArray("sheen", sheen, sizeof(sheen));
			
			sheen[slot] = val;
			this.SetArray("sheen", sheen, sizeof(sheen));
		}
		else
			this.SetValue("sheen", val);
	}
		
	// Sets the killstreaker of a Professional Killstreak the client chose.
	public void SetStreaker(float val, int slot) {
		bool all;
		this.GetValue("all", all);
		
		if (!all) {
			float streaker[3];
			this.GetArray("streaker", streaker, sizeof(streaker));
			
			streaker[slot] = val;
			this.SetArray("streaker", streaker, sizeof(streaker));
		}
		else
			this.SetValue("streaker", val);
	}
		
	// Changes if the mode is for all weapons or not.
	public void AllWeapons(bool mode) {
		this.SetValue("all", mode);
	}
	
	// Gets the current type array (index is slot).
	public void GetType(float array[3]) {
		bool all;
		this.GetValue("all", all);
		
		if (!all) {
			float t[3];
			this.GetArray("type", t, sizeof(t));
			array = t;
		}
		else {
			float t1[3], t2;
			this.GetValue("type", t2);
			
			for (int i = 0; i < sizeof(t1); i++)
				t1[i] = t2;
				
			array = t1;
		}
	}
	
	// Gets the current sheen array (index is slot).
	public void GetSheen(float array[3]) {
		bool all;
		this.GetValue("all", all);
		
		if (!all) {
			float s[3];
			this.GetArray("sheen", s, sizeof(s));
			
			array = s;
		}
		else {
			float s1[3], s2;
			this.GetValue("sheen", s2);
			
			for (int i = 0; i < sizeof(s1); i++)
				s1[i] = s2;
				
			array = s1;
		}
	}
	
	// Gets the current killstreaker array (index is slot).
	public void GetStreaker(float array[3]) {
		bool all;
		this.GetValue("all", all);
		
		if (!all) {
			float st[3];
			this.GetArray("streaker", st, sizeof(st));
			array = st;
		}
		else {
			float st1[3], st2;
			this.GetValue("streaker", st2);
			
			for (int i = 0; i < sizeof(st1); i++)
				st1[i] = st2;
			
			array = st1;
		}
	}
	
	// Checks if the client has All Weapons Mode.
	public bool IsAllMode() {
		bool all;
		this.GetValue("all", all);
		
		return all;
	}
}*/