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

string STR_PLAYER = "player";
string STR_SPECTATOR = "spectator";
string STR_OBSERVER = "observer";

#define FOR_EACH_CLIENTSLOT(v) for(v = world; (v = nextent(v)) && (num_for_edict(v) <= maxclients); )
#define FOR_EACH_CLIENT(v) FOR_EACH_CLIENTSLOT(v) if(v.flags & FL_CLIENT)
#define FOR_EACH_REALCLIENT(v) FOR_EACH_CLIENT(v) if(clienttype(v) == CLIENTTYPE_REAL)
#define FOR_EACH_PLAYER(v) FOR_EACH_CLIENT(v) if(v.classname == STR_PLAYER)
#define FOR_EACH_REALPLAYER(v) FOR_EACH_REALCLIENT(v) if(v.classname == STR_PLAYER)
#define FOR_EACH_TEAMPLAYER(x) FOR_EACH_CLIENT(x) if (x.team > 0)

#define CACHE_CVAR(x) x = cvar(#x)
#define CACHE_CVAR_STR(x) unzone_ifneeded(x); x = cvar_string_zone_ifneeded(#x)
#define CACHE_CVAR_CHECK_EMPTY(x,y) x = ((cvar_string(#x) != "") ? cvar(#x) : y)

#define PLAYER_ALIVE(x) (x.deadflag == 0 || x.deadflag > DEAD_RESPAWNING)
#define PLAYER_DEAD(x) (x.deadflag)
#define PLAYER_REALLY_DEAD(x) (x.deadflag > 0 && x.deadflag <= DEAD_RESPAWNING)
#define PLAYER_REALLY_ALIVE(x) (!x.deadflag)

// copies a string to a tempstring (so one can strunzone it)
string strcat1(string s) = #115; // FRIK_FILE

void bcenterprint(string s)
{
    // TODO replace by MSG_ALL (would show it to spectators too, though)?
    entity head;
    FOR_EACH_PLAYER(head)
    if (clienttype(head) == CLIENTTYPE_REAL)
        centerprint(head, s);
}

float NUM_NEAREST_ENTITIES = 4;
entity nearest_entity[NUM_NEAREST_ENTITIES];
float nearest_length[NUM_NEAREST_ENTITIES];
entity findnearest(vector point, .string field, string value, vector axismod)
{
    entity localhead;
    float i;
    float j;
    float len;
    vector dist;

    float num_nearest;
    num_nearest = 0;

    localhead = find(world, field, value);
    while (localhead)
    {
        if ((localhead.items == IT_KEY1 || localhead.items == IT_KEY2) && localhead.targetname == "###item###")
            dist = localhead.oldorigin;
        else
            dist = localhead.origin;
        dist = dist - point;
        dist = dist_x * axismod_x * '1 0 0' + dist_y * axismod_y * '0 1 0' + dist_z * axismod_z * '0 0 1';
        len = vlen(dist);

        for (i = 0; i < num_nearest; ++i)
        {
            if (len < nearest_length[i])
                break;
        }

        // now i tells us where to insert at
        //   INSERTION SORT! YOU'VE SEEN IT! RUN!
        if (i < NUM_NEAREST_ENTITIES)
        {
            for (j = NUM_NEAREST_ENTITIES - 1; j >= i; --j)
            {
                nearest_length[j + 1] = nearest_length[j];
                nearest_entity[j + 1] = nearest_entity[j];
            }
            nearest_length[i] = len;
            nearest_entity[i] = localhead;
            if (num_nearest < NUM_NEAREST_ENTITIES)
                num_nearest = num_nearest + 1;
        }

        localhead = find(localhead, field, value);
    }

    // now use the first one from our list that we can see
    for (i = 0; i < num_nearest; ++i)
    {
        traceline(point, nearest_entity[i].origin, TRUE, world);
        if (trace_fraction == 1)
        {
            if (i != 0)
            {
                dprint("Nearest point (");
                dprint(nearest_entity[0].netname);
                dprint(") is not visible, using a visible one.\n");
            }
            return nearest_entity[i];
        }
    }

    if (num_nearest == 0)
        return world;

    dprint("Not seeing any location point, using nearest as fallback.\n");
    /* DEBUGGING CODE:
    dprint("Candidates were: ");
    for(j = 0; j < num_nearest; ++j)
    {
    	if(j != 0)
    		dprint(", ");
    	dprint(nearest_entity[j].netname);
    }
    dprint("\n");
    */

    return nearest_entity[0];
}

void spawnfunc_target_location()
{
    self.classname = "target_location";
    // location name in netname
    // eventually support: count, teamgame selectors, line of sight?
};

void spawnfunc_info_location()
{
    self.classname = "target_location";
    self.message = self.netname;
};

string NearestLocation(vector p)
{
    entity loc;
    string ret;
    ret = "somewhere";
    loc = findnearest(p, classname, "target_location", '1 1 1');
    if (loc)
    {
        ret = loc.message;
    }
    else
    {
        loc = findnearest(p, targetname, "###item###", '1 1 4');
        if (loc)
            ret = loc.netname;
    }
    return ret;
}

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

void weapon_precache(float wpn)
{
	string s = get_weaponinfo(wpn).mdl;
	precache_model(strcat("models/weapons/g_", s, ".md3"));
	precache_model(strcat("models/weapons/v_", s, ".md3"));
	precache_model(strcat("models/weapons/h_", s, ".dpm"));
	(get_weaponinfo(wpn)).weapon_func(WR_PRECACHE);
}

// sorry, but using \ in macros breaks line numbers
#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0

vector ExactTriggerHit_mins;
vector ExactTriggerHit_maxs;
float ExactTriggerHit_Recurse()
{
    float s;
    entity se;
    float f;

    tracebox('0 0 0', ExactTriggerHit_mins, ExactTriggerHit_maxs, '0 0 0', MOVE_NORMAL, other);
    if not(trace_ent)
        return 0;
    if (trace_ent == self)
        return 1;

    se = trace_ent;
    s = se.solid;
    se.solid = SOLID_NOT;
    f = ExactTriggerHit_Recurse();
    se.solid = s;

    return f;
}

float ExactTriggerHit()
{
    float f, s;

    if not(self.modelindex)
        return 1;

    s = self.solid;
    self.solid = SOLID_BSP;
    ExactTriggerHit_mins = other.absmin;
    ExactTriggerHit_maxs = other.absmax;
    f = ExactTriggerHit_Recurse();
    self.solid = s;

    return f;
}

// WARNING: this kills the trace globals
#define EXACTTRIGGER_TOUCH if not(ExactTriggerHit()) return
#define EXACTTRIGGER_INIT  InitSolidBSPTrigger(); self.solid = SOLID_TRIGGER

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

void Net_LinkEntity(entity e, float docull, float dt, float(entity, float) sendfunc)
{
    vector mi, ma;

    if (e.classname == "")
        e.classname = "net_linked";

    if (e.model == "" || self.modelindex == 0)
    {
        mi = e.mins;
        ma = e.maxs;
        setmodel(e, "null");
        setsize(e, mi, ma);
    }

    e.SendEntity = sendfunc;
    e.SendFlags = 0xFFFFFF;

    if (!docull)
        e.effects |= EF_NODEPTHTEST;

    if (dt)
    {
        e.nextthink = time + dt;
        e.think = SUB_Remove;
    }
}

void adaptor_think2touch()
{
    entity o;
    o = other;
    other = world;
    self.touch();
    other = o;
}

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

float SUB_NoImpactCheck()
{
	// zero hitcontents = this is not the real impact, but either the
	// mirror-impact of something hitting the projectile instead of the
	// projectile hitting the something, or a touchareagrid one. Neither of
	// these stop the projectile from moving, so...
	if(trace_dphitcontents == 0)
	{
		dprint("A hit happened with zero hit contents... DEBUG THIS, this should never happen for projectiles! Projectile will self-destruct.\n");
		checkclient();
	}
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        return 1;
    if (other == world && self.size != '0 0 0')
    {
        vector tic;
        tic = self.velocity * sys_ticrate;
        tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
        traceline(self.origin - tic, self.origin + tic, MOVE_NORMAL, self);
        if (trace_fraction >= 1)
        {
            dprint("Odd... did not hit...?\n");
        }
        else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        {
            dprint("Detected and prevented the sky-grapple bug.\n");
            return 1;
        }
    }

    return 0;
}

#define SUB_OwnerCheck() (other && (other == self.owner))

float projectile_skipnonsolid()
{
	//if (!sv_gameplayfix_skipnonsolid)
	//	backtrace("Skip nonsolid code activated when disabled");
	if(!other && (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID) && !(trace_dphitcontents & self.dphitcontentsmask)) {
		//Trying correct origin
		tracebox_skipnonsolid(self.origin, self.mins, self.maxs, self.origin + (self.velocity * (1 - trace_fraction) * frametime), FALSE, self);
		if (trace_fraction == 1) // The way is clear
			setorigin(self, trace_endpos);
		else // We can't move right to trace_endpos, because we can go through solid surface.
			setorigin(self, self.origin + ((trace_endpos - self.origin) * 0.99));
		UpdateCSQCProjectileNextFrame(self);
		return TRUE;
	}
	return FALSE;
}

#define PROJECTILE_SKIPNONSOLID if (WarpZone_Projectile_Touch()) { UpdateCSQCProjectileAfterTeleport(self); return; } else if (sv_gameplayfix_skipnonsolid) if(projectile_skipnonsolid()) { return; }
#define PROJECTILE_TOUCH do { PROJECTILE_SKIPNONSOLID if(SUB_OwnerCheck()) return; if (self.lastpushtime >= time) if (self.velocity * trace_plane_normal > 0) { setorigin(self, self.origin); return; } if(SUB_NoImpactCheck()) { remove(self); return; } if(trace_ent && trace_ent.solid > SOLID_TRIGGER) UpdateCSQCProjectileNextFrame(self); } while(0)

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

float zcurveparticles_effectno;
vector zcurveparticles_start;
float zcurveparticles_spd;

void endzcurveparticles()
{
	if(zcurveparticles_effectno)
	{
		// terminator
		WriteShort(MSG_BROADCAST, zcurveparticles_spd | 0x8000);
	}
	zcurveparticles_effectno = 0;
}

void zcurveparticles(float effectno, vector start, vector end, float end_dz, float spd)
{
	spd = bound(0, floor(spd / 16), 32767);
	if(effectno != zcurveparticles_effectno || start != zcurveparticles_start)
	{
		endzcurveparticles();
		WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte(MSG_BROADCAST, TE_CSQC_ZCURVEPARTICLES);
		WriteShort(MSG_BROADCAST, effectno);
		WriteCoord(MSG_BROADCAST, start_x);
		WriteCoord(MSG_BROADCAST, start_y);
		WriteCoord(MSG_BROADCAST, start_z);
		zcurveparticles_effectno = effectno;
		zcurveparticles_start = start;
	}
	else
		WriteShort(MSG_BROADCAST, zcurveparticles_spd);
	WriteCoord(MSG_BROADCAST, end_x);
	WriteCoord(MSG_BROADCAST, end_y);
	WriteCoord(MSG_BROADCAST, end_z);
	WriteCoord(MSG_BROADCAST, end_dz);
	zcurveparticles_spd = spd;
}

void zcurveparticles_from_tracetoss(float effectno, vector start, vector end, vector vel)
{
	float end_dz;
	vector vecxy, velxy;

	vecxy = end - start;
	vecxy_z = 0;
	velxy = vel;
	velxy_z = 0;

	if (vlen(velxy) < 0.000001 * fabs(vel_z))
	{
		endzcurveparticles();
		trailparticles(world, effectno, start, end);
		return;
	}

	end_dz = vlen(vecxy) / vlen(velxy) * vel_z - (end_z - start_z);
	zcurveparticles(effectno, start, end, end_dz, vlen(vel));
}

string GetGametype(); // g_world.qc
void write_recordmarker(entity pl, float tstart, float dt)
{
    // also write a marker into demo files for demotc-race-record-extractor to find
    stuffcmd(pl,
             strcat(
                 strcat("//", strconv(2, 0, 0, GetGametype()), " RECORD SET ", TIME_ENCODED_TOSTRING(TIME_ENCODE(dt))),
                 " ", ftos(tstart), " ", ftos(dt), "\n"));
}

void attach_sameorigin(entity e, entity to, string tag)
{
    vector org, t_forward, t_left, t_up, e_forward, e_up;
    vector org0, ang0;
    float tagscale;

    ang0 = e.angles;
    org0 = e.origin;

    org = e.origin - gettaginfo(to, gettagindex(to, tag));
    tagscale = pow(vlen(v_forward), -2); // undo a scale on the tag
    t_forward = v_forward * tagscale;
    t_left = v_right * -tagscale;
    t_up = v_up * tagscale;

    e.origin_x = org * t_forward;
    e.origin_y = org * t_left;
    e.origin_z = org * t_up;

    // current forward and up directions
    if not(substring(e.model, 0, 1) == "*") // bmodels have their own rules
        e.angles_x = -e.angles_x;
    makevectors(e.angles);

    // untransform forward, up!
    e_forward_x = v_forward * t_forward;
    e_forward_y = v_forward * t_left;
    e_forward_z = v_forward * t_up;
    e_up_x = v_up * t_forward;
    e_up_y = v_up * t_left;
    e_up_z = v_up * t_up;

    e.angles = vectoangles(e_forward, e_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
        e.angles_x = -e.angles_x;

    setattachment(e, to, tag);
    setorigin(e, e.origin);
}

void detach_sameorigin(entity e)
{
    vector org;
    org = gettaginfo(e, 0);
    e.angles = fixedvectoangles2(v_forward, v_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
        e.angles_x = -e.angles_x;
    setorigin(e, org);
    setattachment(e, world, "");
    setorigin(e, e.origin);
}

void follow_sameorigin(entity e, entity to)
{
    e.movetype = MOVETYPE_FOLLOW; // make the hole follow
    e.aiment = to; // make the hole follow bmodel
    e.punchangle = to.angles; // the original angles of bmodel
    e.view_ofs = e.origin - to.origin; // relative origin
    e.v_angle = e.angles - to.angles; // relative angles
}

void unfollow_sameorigin(entity e)
{
    e.movetype = MOVETYPE_NONE;
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

.float scale2;

float modeleffect_SendEntity(entity to, float sf)
{
	float f;
	WriteByte(MSG_ENTITY, ENT_CLIENT_MODELEFFECT);

	f = 0;
	if(self.velocity != '0 0 0')
		f |= 1;
	if(self.angles != '0 0 0')
		f |= 2;
	if(self.avelocity != '0 0 0')
		f |= 4;

	WriteByte(MSG_ENTITY, f);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteByte(MSG_ENTITY, self.skin);
	WriteByte(MSG_ENTITY, self.frame);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	if(f & 1)
	{
		WriteCoord(MSG_ENTITY, self.velocity_x);
		WriteCoord(MSG_ENTITY, self.velocity_y);
		WriteCoord(MSG_ENTITY, self.velocity_z);
	}
	if(f & 2)
	{
		WriteCoord(MSG_ENTITY, self.angles_x);
		WriteCoord(MSG_ENTITY, self.angles_y);
		WriteCoord(MSG_ENTITY, self.angles_z);
	}
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, self.avelocity_x);
		WriteCoord(MSG_ENTITY, self.avelocity_y);
		WriteCoord(MSG_ENTITY, self.avelocity_z);
	}
	WriteShort(MSG_ENTITY, self.scale * 256.0);
	WriteShort(MSG_ENTITY, self.scale2 * 256.0);
	WriteByte(MSG_ENTITY, self.teleport_time * 100.0);
	WriteByte(MSG_ENTITY, self.fade_time * 100.0);
	WriteByte(MSG_ENTITY, self.alpha * 255.0);

	return TRUE;
}

void modeleffect_spawn(string m, float s, float f, vector o, vector v, vector ang, vector angv, float s0, float s2, float a, float t1, float t2)
{
	entity e;
	float sz;
	e = spawn();
	e.classname = "modeleffect";
	setmodel(e, m);
	e.frame = f;
	setorigin(e, o);
	e.velocity = v;
	e.angles = ang;
	e.avelocity = angv;
	e.alpha = a;
	e.teleport_time = t1;
	e.fade_time = t2;
	e.skin = s;
	if(s0 >= 0)
		e.scale = s0 / max6(-e.mins_x, -e.mins_y, -e.mins_z, e.maxs_x, e.maxs_y, e.maxs_z);
	else
		e.scale = -s0;
	if(s2 >= 0)
		e.scale2 = s2 / max6(-e.mins_x, -e.mins_y, -e.mins_z, e.maxs_x, e.maxs_y, e.maxs_z);
	else
		e.scale2 = -s2;
	sz = max(e.scale, e.scale2);
	setsize(e, e.mins * sz, e.maxs * sz);
	Net_LinkEntity(e, FALSE, 0.1, modeleffect_SendEntity);
}

void shockwave_spawn(string m, vector org, float sz, float t1, float t2)
{
	return modeleffect_spawn(m, 0, 0, org, '0 0 0', '0 0 0', '0 0 0', 0, sz, 1, t1, t2);
}

float ExponentialFalloff(float mindist, float maxdist, float halflifedist, float d)
{
	if(halflifedist > 0)
		return pow(0.5, (bound(mindist, d, maxdist) - mindist) / halflifedist);
	else if(halflifedist < 0)
		return pow(0.5, (bound(mindist, d, maxdist) - maxdist) / halflifedist);
	else
		return 1;
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

vector CircleSpreadVector(float side, float up, float sangle) {
    return  side * v_forward * cos(sangle) +
            side * v_right   * sin(sangle) +
            up   * v_up;
}

void dropentities(entity platform) {
    const nudge = '1 1 1';
    entity e;

    while((e = findflags(e, flags, FL_ONGROUND))) {
        if(boxesoverlap(platform.absmin, platform.absmax, e.absmin - nudge, e.absmax + nudge)) {
            e.flags &~= FL_ONGROUND;
            UpdateCSQCProjectileNextFrame(e);
        }
    }

    while((e = findentity(e, aiment, platform))) {
        if(e.movetype == MOVETYPE_FOLLOW) {
            e.movetype = MOVETYPE_TOSS;
            e.aiment = world;
            e.flags &~= FL_ONGROUND;
            UpdateCSQCProjectileNextFrame(e);
        }
    }
}

#define BoundToByte(x) ((x < 251) ? x : ((x < 500) ? 251 : ((x < 1000) ? 252 : ((x < 2000) ? 253 : ((x < 5000) ? 254 : 255)))))
