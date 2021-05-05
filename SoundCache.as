// This plugin requires a symlink for the soundcache folder.
// Open a shell in svencoop/scripts/plugins/store/ and run one of the below commands.
//     Linux:    ln -s ../../../maps/soundcache soundcache
//     Windows:  mklink /D soundcache ..\..\..\maps\soundcache

dictionary g_sounds; // maps file paths and sentences to indexes
dictionary g_sentences; // maps sentence names to sentence indexes
const string g_soundcache_folder = "scripts/plugins/store/soundcache/";

void PluginInit() {
	g_Module.ScriptInfo.SetAuthor( "w00tguy" );
	g_Module.ScriptInfo.SetContactInfo( "https://github.com/wootguy" );
}

enum parse_modes {
	PARSE_NONE,
	PARSE_SOUNDS,
	PARSE_SENTENCES
}

void MapActivate() {
	g_sounds.clear();
	g_sentences.clear();
	
	string soundcache_path = g_soundcache_folder + g_Engine.mapname + ".txt";
	File@ file = g_FileSystem.OpenFile(soundcache_path, OpenFile::READ);
	int parseMode = PARSE_NONE;
	int idx = 0;

	if (file is null or !file.IsOpen()) {
		g_Log.PrintF("[SoundCache.as] failed to open soundcache file: " + soundcache_path + "\n");
		return;
	}
	
	while (!file.EOFReached()) {
		string line;
		file.ReadLine(line);
		
		if (parseMode == PARSE_NONE) {
			if (line.Find("SOUNDLIST {") == 0) {
				parseMode = PARSE_SOUNDS;
				continue;
			}
			if (line.Find("SENTENCELIST {") == 0) {
				parseMode = PARSE_SENTENCES;
				continue;
			}
		}
		else {
			if (line.Find("}") == 0) {
				parseMode = PARSE_NONE;
				idx = 0;
				continue;
			}
			
			if (parseMode == PARSE_SOUNDS) {
				g_sounds[line] = idx;
			}
			else if (parseMode == PARSE_SENTENCES) {
				array<string> parts = line.Split(" ");
				g_sentences["!" + parts[0]] = idx;
			}
		
			idx++;
		}
	}

	file.Close();
	
	// create a custom entity that other plugins can call Use()	on to get sound indexes.
	g_CustomEntityFuncs.RegisterCustomEntity( "soundcache", "soundcache" );
	g_EntityFuncs.CreateEntity("soundcache", {}, true);
	
	g_Game.AlertMessage(at_console, "[SoundCache.as] Parsed " + g_sounds.size() + " sounds and " + g_sentences.size() + " sentences\n");
}

class soundcache : ScriptBaseEntity {

	// Reads a sound path from noise1 and outputs the index to iuser1.
	// Sets iuser1 to -1 if the sound is not found in the cache
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f) {
		if (!g_sounds.get(pev.noise1, pev.iuser1) and !g_sentences.get(pev.noise1, pev.iuser1)) {
			pev.iuser1 = -1;
		}
	}
}