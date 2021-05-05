// This script requires the SoundCache plugin to function

const int SND_OFFSET = 32768;
const int SND_IDK = 16384; // this is set by ambient_music but idk what it does

class StartSoundMsgParams {
	string sample;                     // sound file to play (relative to "sound/" folder)
	SOUND_CHANNEL channel = CHAN_AUTO;
	float volume = 1.0f;               // 0.0 - 1.0
	float attenuation = 1.0f;          // 0.0 - 4.0
	uint8 pitch = PITCH_NORM;
	float offset = 0.0f;               // seconds to skip (e.g. start from the middle of a song)
	int entindex = -1;                 // entity to attach to (-1 = use origin)
	Vector origin;                     // ignored if entindex >= 0
	
	// Combination of SoundFlag values. The following flags are handled by this script:
	// SND_VOLUME, SND_PITCH, SND_ATTENUATION, SND_ENT, SND_ORIGIN, SND_SENTENCE
	int16 flags = 0;
	
	StartSoundMsgParams() {}
}

void StartSoundMsg(StartSoundMsgParams params, NetworkMessageDest msgType=MSG_ALL, edict_t@ msgEdict=null) {
	int flags = params.flags;
	
	if (params.entindex >= 0) {
		flags |= SND_ENT;
	}
	else {
		flags |= SND_ORIGIN;
	}
	
	if (params.offset > 0) {
		flags |= SND_OFFSET;
	}
	if (params.volume != 1.0f or (flags & SND_CHANGE_VOL != 0)) {
		flags |= SND_VOLUME;
	}
	if (params.attenuation != 1.0f) {
		flags |= SND_ATTENUATION;
	}
	if (params.pitch != PITCH_NORM or (flags & SND_CHANGE_PITCH != 0)) {
		flags |= SND_PITCH;
	}
	if (flags & SND_ORIGIN != 0) {
		flags &= ~SND_ENT;
	}
	if (params.sample.Length() > 0 and params.sample[0] == '!') {
		flags |= SND_SENTENCE;
	}
	
	NetworkMessage m(msgType, NetworkMessages::StartSound, msgEdict);
	m.WriteShort(flags);
	
	if (flags & SND_ENT != 0) {
		m.WriteShort(params.entindex);
	}
	if (flags & SND_VOLUME != 0) {
		m.WriteByte(Math.clamp(0, 255, int(params.volume * 255)));
	}
	if (flags & SND_PITCH != 0) {
		m.WriteByte(params.pitch);
	}
	if (flags & SND_ATTENUATION != 0) {
		m.WriteByte(Math.clamp(0, 255, int(params.attenuation * 64)));
	}
	if (flags & SND_ORIGIN != 0) {
		m.WriteVector(params.origin);
	}
	if (flags & SND_OFFSET != 0) {
		m.WriteFloat(params.offset);
	}
	
	m.WriteByte(params.channel);
	m.WriteShort(getSoundIndex(params.sample));
	
	m.End();
}

int16 getSoundIndex(string sample) {
	CBaseEntity@ soundcache = g_EntityFuncs.FindEntityByClassname(null, "soundcache"); 
	
	if (soundcache is null) {
		g_Game.AlertMessage(at_console, "[StartSoundMsg] Failed to find soundcache ent. Did you install the SoundCache plugin?\n");
		return 0;
	}
	
	soundcache.pev.noise1 = sample;
	soundcache.Use(null, null, USE_TOGGLE);
	
	if (soundcache.pev.iuser1 == -1) {
		g_Game.AlertMessage(at_console, "[StartSoundMsg] Not precached: " + sample + "\n");
	}
	
	return soundcache.pev.iuser1;
}
