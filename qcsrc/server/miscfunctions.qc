void droptofloor();
.vector dropped_origin;

void move_out_of_solid_expand(entity e, vector by, float t)
{
    float eps = 0.0625;
    tracebox(e.origin, e.mins - '1 1 1' * eps, e.maxs + '1 1 1' * eps, e.origin + by, t, e);
    if (trace_startsolid)
        return;
    if (trace_fraction < 1)
    {
        // hit something
        // adjust origin in the other direction...
        setorigin(e,e.origin - by * (1 - trace_fraction));
    }
}

float move_out_of_solid_with_type(entity e, float t)
{
    vector o, m0, m1;

    o = e.origin;
    traceline(o, o, t, e);
    if (trace_startsolid)
        return 0;

    tracebox(o, e.mins, e.maxs, o, t, e);
    if (!trace_startsolid)
        return 1;

    m0 = e.mins;
    m1 = e.maxs;
    e.mins = '0 0 0';
    e.maxs = '0 0 0';
    move_out_of_solid_expand(e, '1 0 0' * m0_x, t);
    e.mins_x = m0_x;
    move_out_of_solid_expand(e, '1 0 0' * m1_x, t);
    e.maxs_x = m1_x;
    move_out_of_solid_expand(e, '0 1 0' * m0_y, t);
    e.mins_y = m0_y;
    move_out_of_solid_expand(e, '0 1 0' * m1_y, t);
    e.maxs_y = m1_y;
    move_out_of_solid_expand(e, '0 0 1' * m0_z, t);
    e.mins_z = m0_z;
    move_out_of_solid_expand(e, '0 0 1' * m1_z, t);
    e.maxs_z = m1_z;
    setorigin(e, e.origin);

    tracebox(e.origin, e.mins, e.maxs, e.origin, MOVE_WORLDONLY, e);
    if (trace_startsolid)
    {
        setorigin(e, o);
        return 0;
    }

    return 1;
}
#define move_out_of_solid(x) move_out_of_solid_with_type(x, MOVE_WORLDONLY)

#define CACHE_CVAR(x) x = cvar(#x)
#define CACHE_CVAR_STR(x) unzone_ifneeded(x); x = cvar_string_zone_ifneeded(#x)
#define CACHE_CVAR_CHECK_EMPTY(x,y) x = ((cvar_string(#x) != "") ? cvar(#x) : y)

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

entity get_weaponinfo(float w);

enum {
	INITPRIO_FIRST,
	INITPRIO_GAMETYPE,
	INITPRIO_GAMETYPE_FALLBACK,
	INITPRIO_CVARS,
	INITPRIO_FINDTARGET,
	INITPRIO_DROPTOFLOOR,
	INITPRIO_SETLOCATION,
	INITPRIO_LINKDOORS,
	INITPRIO_LAST,
};

void objerror(string s)
{
    objerror_builtin(s);
}

float initialize_entities_done;
void InitializeEntity(entity for_e, void(void) func, float order)
{
	entity e = spawn();
	e.classname = "initialize_entity";
	e.enemy = for_e;
    e.think = func;
    e.cnt = order;
	initialize_entities_done = FALSE;
}

void InitializeEntitiesRun()
{
	if (initialize_entities_done)
		return;

	entity oldself = self;
	entity e;
	float i;
	for (i = INITPRIO_FIRST; i <= INITPRIO_LAST; i++)
		for (e = find(world, classname, "initialize_entity"); e; e = find(e, classname, "initialize_entity")) {
			if (e.cnt != i)
				continue;

			self = e.enemy;
			e.think();
			remove(e);
		}
	self = oldself;
	initialize_entities_done = TRUE;
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

// deferred dropping
void DropToFloor_Handler()
{
    droptofloor_builtin();
    self.dropped_origin = self.origin;
}

void droptofloor()
{
    InitializeEntity(self, DropToFloor_Handler, INITPRIO_DROPTOFLOOR);
}



float trace_hits_box_a0, trace_hits_box_a1;

float trace_hits_box_1d(float end, float thmi, float thma)
{
    if (end == 0)
    {
        // just check if x is in range
        if (0 < thmi)
            return FALSE;
        if (0 > thma)
            return FALSE;
    }
    else
    {
        // do the trace with respect to x
        // 0 -> end has to stay in thmi -> thma
        trace_hits_box_a0 = max(trace_hits_box_a0, min(thmi / end, thma / end));
        trace_hits_box_a1 = min(trace_hits_box_a1, max(thmi / end, thma / end));
        if (trace_hits_box_a0 > trace_hits_box_a1)
            return FALSE;
    }
    return TRUE;
}

float trace_hits_box(vector start, vector end, vector thmi, vector thma)
{
    end -= start;
    thmi -= start;
    thma -= start;
    // now it is a trace from 0 to end

    trace_hits_box_a0 = 0;
    trace_hits_box_a1 = 1;

    if (!trace_hits_box_1d(end_x, thmi_x, thma_x))
        return FALSE;
    if (!trace_hits_box_1d(end_y, thmi_y, thma_y))
        return FALSE;
    if (!trace_hits_box_1d(end_z, thmi_z, thma_z))
        return FALSE;

    return TRUE;
}

float tracebox_hits_box(vector start, vector mi, vector ma, vector end, vector thmi, vector thma)
{
    return trace_hits_box(start, end, thmi - ma, thma - mi);
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

float MoveToRandomMapLocation(entity e, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float shiftdistance)
{
    float m, i;
    vector start, org, delta, end, enddown;

    m = e.dphitcontentsmask;
    e.dphitcontentsmask = goodcontents | badcontents;

    org = world.mins;
    delta = world.maxs - world.mins;
	entity firstspot = findchain(classname, "info_player_deathmatch");
	random_selection_init();
	entity spot;
	for(spot = firstspot; spot; spot = spot.chain)
		random_selection_add(spot, 0, string_null, 1, 1);

    for (i = 0; i < attempts; ++i)
    {
		start = random_selection_chosen_ent.origin;
		if (random_selection_chosen_ent.mins_z > e.mins_z)
			start_z = start_z - e.mins_z + random_selection_chosen_ent.mins_z;

        end_x = random() - 0.5;
        end_y = random() - 0.5;
        end_z = random() / 2;
        end = start + normalize(end) * (vlen(delta) * random() + shiftdistance);
        tracebox(start, e.mins, e.maxs, end, MOVE_NORMAL, e);
		end = start;
		start = trace_endpos;

        // rule 1: start inside world bounds, and outside
        // solid, and don't start from somewhere where you can
        // fall down to evil
        tracebox(start, e.mins, e.maxs, start - '0 0 1' * delta_z, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        if (trace_startsolid)
            continue;
        if (trace_dphitcontents & badcontents)
            continue;
        if (trace_dphitq3surfaceflags & badsurfaceflags)
            continue;

        // rule 2: if we are too high, lower the point
        if (trace_fraction * delta_z > maxaboveground)
            start = trace_endpos + '0 0 1' * maxaboveground;

        enddown = trace_endpos;

        // rule 3: we must not end up in trigger_hurt
        if (tracebox_hits_trigger_hurt(start, e.mins, e.maxs, enddown))
        {
            dprint("trigger_hurt! ouch! and nothing else could find it!\n");
            continue;
        }

        break;
    }

    e.dphitcontentsmask = m;

    if (i < attempts)
    {
        setorigin(e, trace_endpos);
		e.flags &~= FL_ONGROUND;
        e.angles = vectoangles(start - end);
		e.angles_x = 0;
		e.angles_z = 0;
        dprint("Needed ", ftos(i + 1), " attempts\n");
        return TRUE;
    }
    else
        return FALSE;
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

void dropentities(entity platform) {
    const nudge = '1 1 1';
    entity e;

    while((e = findflags(e, flags, FL_ONGROUND))) {
        if(boxesoverlap(platform.absmin, platform.absmax, e.absmin - nudge, e.absmax + nudge)) {
            e.flags &~= FL_ONGROUND;
            projectile_update_next_frame(e);
        }
    }

    while((e = findentity(e, aiment, platform))) {
        if(e.movetype == MOVETYPE_FOLLOW) {
            e.movetype = MOVETYPE_TOSS;
            e.aiment = world;
            e.flags &~= FL_ONGROUND;
            projectile_update_next_frame(e);
        }
    }
}

#define BoundToByte(x) ((x < 251) ? x : ((x < 500) ? 251 : ((x < 1000) ? 252 : ((x < 2000) ? 253 : ((x < 5000) ? 254 : 255)))))
