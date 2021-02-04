// Re-wrote the old MethodMap method to a simple enum struct logic.
enum struct UnusualClient {
	int   slot;			// Temporary slot integer. Keeps the selected slot by the user in memory until it is no longer needed.
	
	int   id[3];		// This array keeps the Hat IDs the user selected. Used to identify if the hat we're applying the effect is the one that the user selected.
	float unusual[3];	// This array keeps the Unusual effect IDs selected by the user, each slot number also corresponds to the hat slot selected.
}

// Unusual Particle Effects List
int unusualIds[150] =  {
	0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 29, 30, 31, 
	32, 33, 34, 35, 36, 37, 38, 39, 40, 43, 44, 45, 46, 47, 56, 57, 
	58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 
	74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 
	90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 
	105, 106, 107, 108, 109, 110, 
	111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 
	124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 
	137, 138, 139, 141, 142, 143, 144, 145, 147, 148, 149, 
	150, 151, 152, 153, 154, 155, 
	156, 157, 158, 159, 160, 161, 162, 163, 
	164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175
};

char unusualNames[150][64] =  {
	"Ninguno", "Green Confetti", "Purple Confetti", "Haunted Ghosts", "Green Energy", 
	"Purple Energy", "Circling TF Logo", "Massed Flies", "Burning Flames", 
	"Scorching Flames", "Searing Plasma", "Vivid Plasma", "Sunbeams", 
	"Circling Peace Sign", "Circling Heart", "Stormy Storm", "Blizzardy Storm", 
	"Nuts n' Bolts", "Orbiting Planets", "Orbiting Fire", "Bubbling", "Smoking", 
	"Steaming", "Flaming Lantern", "Cloudy Moon", "Cauldron Bubbles", "Eerie Orbiting Fire", 
	"Knifestorm", "Misty Skull", "Harvest Moon", "It's A Secret To Everybody", 
	"Stormy 13th Hour", "Kill-a-Watt", "Terror-Watt", "Cloud 9", "Aces High", 
	"Dead Presidents", "Miami Nights", "Disco Beat Down", "Phosphorous", "Sulphurous", 
	"Memory Leak", "Overclocked", "Electrostatic", "Power Surge", "Anti-Freeze", 
	"Time Warp", "Green Black Hole", "Roboactive", "Arcana", "Spellbound", 
	"Chiroptera Venenata", "Poisoned Shadow", "Something Burning This Way Comes", 
	"Hellfire", "Darkblaze", "Demonflame", "Bonzo The All-Gnawing", "Amaranthine", 
	"Stare From Beyond", "The Ooze", "Ghastly Ghosts Jr", "Haunted Phantasm Jr", 
	"Frostbite", "Molten Mallard", "Morning Glory", "Death at Dusk", "Abduction", 
	"Atomic", "Subatomic", "Electric Hat Protector", "Magnetic Hat Protector", 
	"Voltaic Hat Protector", "Galactic Codex", "Ancient Codex", "Nebula", "Death by Disco", 
	"It's a mystery to everyone", "It's a puzzle to me", "Ether Trail", "Nether Trail", 
	"Ancient Eldritch", "Eldritch Flame", "Neutron Star", "Tesla Coil", "Starstorm Insomnia", 
	"Starstorm Slumber", "Brain Drain", "Open Mind", "Head of Steam", "Galactic Gateway", 
	"The Eldritch Opening", "The Dark Doorway", "Ring of Fire", "Vicious Circle", "White Lightning", 
	"Omniscient Orb", "Clairvoyance", "Fifth Dimension", "Vicious Vortex", "Menacing Miasma", "Abyssal Aura", 
	"Wicked Wood", "Ghastly Grove", "Mystical Medley", "Ethereal Essence", "Twisted Radiance", 
	"Violet Vortex", "Verdant Vortex", "Valiant Vortex", "Sparkling Lights", "Frozen Icefall", 
	"Fragmented Gluons", "Fragmented Quarks", "Fragmented Photons", "Defragmenting Reality", 
	"Fragmenting Reality", "Refragmenting Reality", "Snowfallen", "Snowblinded", "Pyroland Daydream", 
	"Verdatica", "Aromatica", "Chromatica", "Prismatica", "Bee Swarm", "Frisky Fireflies", "Smoldering Spirits", 
	"Wandering Wisps", "Kaleidoscope", 
	"Green Giggler", "Laugh-O-Lantern", "Plum Prankster", "Pyroland Nightmare", "Gravelly Ghoul", "Vexed Volcanics", 
	"Gourdian Angels", "Pumpkin Party", 
	"Frozen Fractals", "Lavender Landfall", "Special Snowfall", "Divine Desire", "Distant Dream", "Violent Wintertide", 
	"Blighted Snowstorm", "Pale Nimbus", "Genus Plasmos", "Serenus Lumen", "Ventum Maris", "Mirthful Mistletoe"
};

// AddUnusuals(Menu menu) - Adds all Unusual Effects to a menu.
void AddUnusuals(Menu menu)
{
	for (int i = 0; i < sizeof(unusualIds); i++) {
		char id[5];
		IntToString(unusualIds[i], id, sizeof(id));
		
		AddMenuItem(menu, id, unusualNames[i]);
	}
}









/*

WRITING THIS SHITTY ASS METHODMAP WAS WORTHLESS. A SIMPLE ENUM STRUCT WAS ENOUGH FFS.

// Unusual Class
methodmap UnusualClient < StringMap {
	public UnusualClient() {
		return view_as<UnusualClient>(new StringMap());
	}
	
	public void Initialize() {
		this.SetValue("slot", 0);
		this.SetArray("id", { 0, 0, 0 }, 3);
		this.SetArray("unusual", { 0.0, 0.0, 0.0 }, 3);
	}
	
	// SetSlot() - Temporary function, used only to keep track of the slot selected by the user.
	public void SetSlot(int slot) {
		this.SetValue("slot", slot);
	}
	
	// SetId() - Temporary function, used only to keep track of the item ID selected by the user.
	public void SetId(int id) {
		int slot;
		this.GetValue("slot", slot);
		
		int arr[3];
		if (!this.GetArray("id", arr, sizeof(arr)))
			arr =  { 0, 0, 0 };
		arr[slot] = id;
		this.SetArray("id", arr, sizeof(arr));
	}
	
	// SetUnusual() - Sets the Unusual effect the user chose.
	// Keep in mind, a max of 3 different effects and hats can be chosen.
	public void SetUnusual(float eff) {
		int slot;
		this.GetValue("slot", slot);
		
		float unu[3];
		if (!this.GetArray("unusual", unu, sizeof(unu)))
			unu =  { 0.0, 0.0, 0.0 };
		
		unu[slot] = eff;
		this.SetArray("unusual", unu, sizeof(unu));
	}
	
	public int GetSlot() {
		int slot;
		this.GetValue("slot", slot);
		
		return slot;
	}
	
	// GetId() - Gets the ID at a certain slot.
	// Empty slots (no unusual) is identified with 0.0 content.
	public int GetId(int slot) {
		int id[3];
		this.GetArray("id", id, sizeof(id));
		
		return id[slot];
	}
	
	// GetUnusual() - Gets the unusual array the client has currently on n slot.
	// Empty slots (no unusual) is identified with 0.0 content.
	public float GetUnusual(int slot) {
		float unusual[3];
		this.GetArray("unusual", unusual, sizeof(unusual));
		
		return unusual[slot];
	}
}

*/