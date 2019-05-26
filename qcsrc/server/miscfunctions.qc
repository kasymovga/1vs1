// copies a string to a tempstring (so one can strunzone it)
string strcat1(string s) = #115; // FRIK_FILE


#define CENTERPRIO_POINT 1
#define CENTERPRIO_SPAM 2
#define CENTERPRIO_VOTE 4
#define CENTERPRIO_NORMAL 5
#define CENTERPRIO_SHIELDING 7
#define CENTERPRIO_MAPVOTE 9
#define CENTERPRIO_IDLEKICK 50
#define CENTERPRIO_ADMIN 99
.float centerprint_priority;
.float centerprint_expires;
void centerprint_atprio(entity e, float prio, string s)
{
    if (intermission_running)
        if (prio < CENTERPRIO_MAPVOTE)
            return;

	entity spec;
	if (e.classname == "player")
		FOR_EACH_REALCLIENT(spec)
			if (spec.enemy == e)
			if (spec.classname == "spectator")
				centerprint_atprio(spec, prio, s);

    if (time > e.centerprint_expires)
        e.centerprint_priority = 0;
    if (prio >= e.centerprint_priority)
    {
        e.centerprint_priority = prio;
		e.centerprint_expires = time + (e.cvar_scr_centertime * max(slowmo, 0.0001));
        centerprint_builtin(e, s);
    }
}
void centerprint_expire(entity e, float prio)
{
    if (prio == e.centerprint_priority)
    {
        e.centerprint_priority = 0;
        centerprint_builtin(e, "");
    }
}
void centerprint(entity e, string s)
{
    centerprint_atprio(e, CENTERPRIO_NORMAL, s);
}

// decolorizes and team colors the player name when needed
string playername(entity p)
{
    string t;
    if (teamplay && !intermission_running && p.classname == "player")
    {
        t = Team_ColorCode(p.team);
        return strcat(t, strdecolorize(p.netname));
    }
    else
        return p.netname;
}

.float nottargeted;
#define IFTARGETED if(!self.nottargeted && self.targetname != "")

void adaptor_think2use()
{
    entity o, a;
    o = other;
    a = activator;
    activator = world;
    other = world;
    self.use();
    other = o;
    activator = a;
}

void print_to(entity e, string s)
{
    if (e)
        sprint(e, strcat(s, "\n"));
    else
        print(s, "\n");
}

string getrecords()
{
    float i;
    string s;
    s = "";
	for (i = 0; i < MapInfo_count; ++i)
		if (MapInfo_Get_ByID(i))
			s = strcat(s, GameHook_RecordForMap(MapInfo_Map_bspname));

    MapInfo_ClearTemps();
    if (s == "")
        return "No records are available on this server.\n";
    else
        return strcat("Records on this server:\n", s);
}

void write_recordmarker(entity pl, float tstart, float dt)
{
    // also write a marker into demo files for demotc-race-record-extractor to find
    stuffcmd(pl,
             strcat(
                 strcat("//", strconv(2, 0, 0, GametypeNameFromType(game)), " RECORD SET ", TIME_ENCODED_TOSTRING(TIME_ENCODE(dt))),
                 " ", ftos(tstart), " ", ftos(dt), "\n"));
}

entity gettaginfo_relative_ent;
vector gettaginfo_relative(entity e, float tag)
{
    if (!gettaginfo_relative_ent)
    {
        gettaginfo_relative_ent = spawn();
        gettaginfo_relative_ent.effects = EF_NODRAW;
    }
    gettaginfo_relative_ent.model = e.model;
    gettaginfo_relative_ent.modelindex = e.modelindex;
    gettaginfo_relative_ent.frame = e.frame;
    return gettaginfo(gettaginfo_relative_ent, tag);
}

float ParseCommandPlayerSlotTarget_firsttoken;
entity GetCommandPlayerSlotTargetFromTokenizedCommand(float tokens, float idx) // idx = start index
{
    string s;
    entity e, head;
    float n;

    s = string_null;

    ParseCommandPlayerSlotTarget_firsttoken = -1;

    if (tokens > idx)
    {
        if (substring(argv(idx), 0, 1) == "#")
        {
            s = substring(argv(idx), 1, -1);
            ++idx;
            if (s == "")
                if (tokens > idx)
                {
                    s = argv(idx);
                    ++idx;
                }
			ParseCommandPlayerSlotTarget_firsttoken = idx;
            if (s == ftos(stof(s)))
            {
                e = edict_num(stof(s));
                if (e.flags & FL_CLIENT)
                    return e;
            }
        }
        else
        {
            // it must be a nick name
            s = argv(idx);
            ++idx;
			ParseCommandPlayerSlotTarget_firsttoken = idx;

            n = 0;
            FOR_EACH_CLIENT(head)
            if (head.netname == s)
            {
                e = head;
                ++n;
            }
            if (n == 1)
                return e;

            s = strdecolorize(s);
            n = 0;
            FOR_EACH_CLIENT(head)
            if (strdecolorize(head.netname) == s)
            {
                e = head;
                ++n;
            }
            if (n == 1)
                return e;
        }
    }

    return world;
}

void defer_think() {
	entity oldself = self;
	self = self.enemy;
	oldself.use();
	self = oldself;
	remove(self);
}

void defer_for(entity e_for, float t, void() callback) {
	entity e = spawn();
	e.use = callback;
	e.enemy = e_for;
	e.nextthink = t + time;
	e.think = defer_think;
}

void defer(float t, void() callback) {
	defer_for(self, t, callback);
}

#define BoundToByte(x) ((x < 251) ? x : ((x < 500) ? 251 : ((x < 1000) ? 252 : ((x < 2000) ? 253 : ((x < 5000) ? 254 : 255)))))
