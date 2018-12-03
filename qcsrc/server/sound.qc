#define SND_VOLUME      1
#define SND_ATTENUATION 2
#define SND_LARGEENTITY 8
#define SND_LARGESOUND  16

void soundtoat(float dest, entity e, vector o, float chan, string samp, float vol, float atten)
{
    float entno, idx;

    entno = num_for_edict(e);
    idx = precache_sound_index(samp);

    float sflags;
    sflags = 0;

    atten = floor(atten * 64);
    vol = floor(vol * 255);

    if (vol != 255)
        sflags |= SND_VOLUME;
    if (atten != 64)
        sflags |= SND_ATTENUATION;
    if (entno >= 8192)
        sflags |= SND_LARGEENTITY;
    if (idx >= 256)
        sflags |= SND_LARGESOUND;

    WriteByte(dest, SVC_SOUND);
    WriteByte(dest, sflags);
    if (sflags & SND_VOLUME)
        WriteByte(dest, vol);
    if (sflags & SND_ATTENUATION)
        WriteByte(dest, atten);
    if (sflags & SND_LARGEENTITY)
    {
        WriteShort(dest, entno);
        WriteByte(dest, chan);
    }
    else
    {
        WriteShort(dest, entno * 8 + chan);
    }
    if (sflags & SND_LARGESOUND)
        WriteShort(dest, idx);
    else
        WriteByte(dest, idx);

    WriteCoord(dest, o_x);
    WriteCoord(dest, o_y);
    WriteCoord(dest, o_z);
}
void soundto(float dest, entity e, float chan, string samp, float vol, float atten)
{
    vector o;
    o = e.origin + 0.5 * (e.mins + e.maxs);
    soundtoat(dest, e, o, chan, samp, vol, atten);
}
void soundat(entity e, vector o, float chan, string samp, float vol, float atten)
{
    soundtoat(MSG_BROADCAST, e, o, chan, samp, vol, atten);
}
void stopsoundto(float dest, entity e, float chan)
{
    float entno;
    entno = num_for_edict(e);

    if (entno >= 8192)
    {
        float idx, sflags;
        idx = precache_sound_index("misc/null.wav");
        sflags = SND_LARGEENTITY;
        if (idx >= 256)
            sflags |= SND_LARGESOUND;
        WriteByte(dest, SVC_SOUND);
        WriteByte(dest, sflags);
        WriteShort(dest, entno);
        WriteByte(dest, chan);
        if (sflags & SND_LARGESOUND)
            WriteShort(dest, idx);
        else
            WriteByte(dest, idx);
        WriteCoord(dest, e.origin_x);
        WriteCoord(dest, e.origin_y);
        WriteCoord(dest, e.origin_z);
    }
    else
    {
        WriteByte(dest, SVC_STOPSOUND);
        WriteShort(dest, entno * 8 + chan);
    }
}
void stopsound(entity e, float chan)
{
    stopsoundto(MSG_BROADCAST, e, chan); // unreliable, gets there fast
    stopsoundto(MSG_ALL, e, chan); // in case of packet loss
}

void play2(entity e, string filename)
{
    //stuffcmd(e, strcat("play2 ", filename, "\n"));
    msg_entity = e;
    soundtoat(MSG_ONE, world, '0 0 0', CHAN_AUTO, filename, VOL_BASE, ATTN_NONE);
}

.float announcetime;
float announce_force(entity player, string msg)
{
	if not(clienttype(player) == CLIENTTYPE_REAL)
		return FALSE;

	player.announcetime = time + 0.8;
	play2(player, msg);
	return TRUE;
}

float announce(entity player, string msg)
{
    if (time > player.announcetime)
		return announce_force(player, msg);

    return FALSE;
}
// use this one if you might be causing spam (e.g. from touch functions that might get called more than once per frame)
float spamsound(entity e, float chan, string samp, float vol, float atten)
{
    if (time > e.announcetime)
    {
        e.announcetime = time;
        sound(e, chan, samp, vol, atten);
        return TRUE;
    }
    return FALSE;
}

void play2team(float t, string filename)
{
    local entity head;

    FOR_EACH_REALPLAYER(head)
    {
        if (head.team == t)
            play2(head, filename);
    }
}

void play2all(string samp)
{
    sound(world, CHAN_AUTO, samp, VOL_BASE, ATTN_NONE);
}

string randomsound(string s, float n) {
	if (s == "")
		return "";

	if (n < 2)
		return strcat(s, ".wav");

	return strcat(s, ftos(floor(random() * n + 1)), ".wav");
}

string randomsound_bystr(string s) {
	string s1 = car(s);
	string s2 = cdr(s);
	return randomsound(s1, stof(s2));
}

void precache_randomsound(string s, float n) {
	float i;
	if (n < 2) {
		precache_sound(strcat(s, ".wav"));
	} else
		for (i = 1; i <= n; i++) {
			precache_sound(strcat(s, ftos(i), ".wav"));
		}
}
