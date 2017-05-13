void droptofloor();
.vector dropped_origin;

void() spawnfunc_info_player_deathmatch; // needed for the other spawnpoints
void() spawnpoint_use;
string ColoredTeamName(float t);

float DistributeEvenly_amount;
float DistributeEvenly_totalweight;
void DistributeEvenly_Init(float amount, float totalweight)
{
    if (DistributeEvenly_amount)
    {
        dprint("DistributeEvenly_Init: UNFINISHED DISTRIBUTION (", ftos(DistributeEvenly_amount), " for ");
        dprint(ftos(DistributeEvenly_totalweight), " left!)\n");
    }
    if (totalweight == 0)
        DistributeEvenly_amount = 0;
    else
        DistributeEvenly_amount = amount;
    DistributeEvenly_totalweight = totalweight;
}
float DistributeEvenly_Get(float weight)
{
    float f;
    if (weight <= 0)
        return 0;
    f = floor(0.5 + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
    DistributeEvenly_totalweight -= weight;
    DistributeEvenly_amount -= f;
    return f;
}

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

#if 0
#define FOR_EACH_CLIENT(v) for(v = world; (v = findflags(v, flags, FL_CLIENT)) != world; )
#define FOR_EACH_REALCLIENT(v) FOR_EACH_CLIENT(v) if(clienttype(v) == CLIENTTYPE_REAL)
#define FOR_EACH_PLAYER(v) for(v = world; (v = find(v, classname, STR_PLAYER)) != world; )
#define FOR_EACH_REALPLAYER(v) FOR_EACH_PLAYER(v) if(clienttype(v) == CLIENTTYPE_REAL)
#else
#define FOR_EACH_CLIENTSLOT(v) for(v = world; (v = nextent(v)) && (num_for_edict(v) <= maxclients); )
#define FOR_EACH_CLIENT(v) FOR_EACH_CLIENTSLOT(v) if(v.flags & FL_CLIENT)
#define FOR_EACH_REALCLIENT(v) FOR_EACH_CLIENT(v) if(clienttype(v) == CLIENTTYPE_REAL)
#define FOR_EACH_PLAYER(v) FOR_EACH_CLIENT(v) if(v.classname == STR_PLAYER)
#define FOR_EACH_REALPLAYER(v) FOR_EACH_REALCLIENT(v) if(v.classname == STR_PLAYER)
#define FOR_EACH_TEAMPLAYER(x) FOR_EACH_CLIENT(x) if (x.team > 0)
#endif

#define CACHE_CVAR(x) x = cvar(#x)

#define PLAYER_ALIVE(x) (x.deadflag == 0 || x.deadflag > DEAD_RESPAWNING)
#define PLAYER_DEAD(x) (x.deadflag)
#define PLAYER_REALLY_DEAD(x) (x.deadflag > 0 && x.deadflag <= DEAD_RESPAWNING)
#define PLAYER_REALLY_ALIVE(x) (!x.deadflag)

// copies a string to a tempstring (so one can strunzone it)
string strcat1(string s) = #115; // FRIK_FILE

float logfile_open;
float logfile;

void bcenterprint(string s)
{
    // TODO replace by MSG_ALL (would show it to spectators too, though)?
    entity head;
    FOR_EACH_PLAYER(head)
    if (clienttype(head) == CLIENTTYPE_REAL)
        centerprint(head, s);
}

float PlayerCanFire(entity plr, float wep) {
	if (PLAYER_DEAD(plr))
		return FALSE;

	if (time < game_starttime)
	if (!restart_active)
		return FALSE;

	if (timeoutStatus == 2) //don't allow the player to shoot while game is paused
		return FALSE;

	return GameHookChain_PlayerCanFire(plr, wep);
}

void GameLogEcho(string s)
{
    string fn;
    float matches;

    if (cvar("sv_eventlog_files"))
    {
        if (!logfile_open)
        {
            logfile_open = TRUE;
            matches = cvar("sv_eventlog_files_counter") + 1;
            cvar_set("sv_eventlog_files_counter", ftos(matches));
            fn = ftos(matches);
            if (strlen(fn) < 8)
                fn = strcat(substring("00000000", 0, 8 - strlen(fn)), fn);
            fn = strcat(cvar_string("sv_eventlog_files_nameprefix"), fn, cvar_string("sv_eventlog_files_namesuffix"));
            logfile = fopen(fn, FILE_APPEND);
            fputs(logfile, ":logversion:3\n");
        }
        if (logfile >= 0)
        {
            if (cvar("sv_eventlog_files_timestamps"))
                fputs(logfile, strcat(":time:", strftime(TRUE, "%Y-%m-%d %H:%M:%S", "\n", s, "\n")));
            else
                fputs(logfile, strcat(s, "\n"));
        }
    }
    if (cvar("sv_eventlog_console"))
    {
        print(s, "\n");
    }
}

void GameLogInit()
{
    logfile_open = 0;
    // will be opened later
}

void GameLogClose()
{
    if (logfile_open && logfile >= 0)
    {
        fclose(logfile);
        logfile = -1;
    }
}

float spawnpoint_nag;
void relocate_spawnpoint()
{
    // nudge off the floor
    setorigin(self, self.origin + '0 0 1');

    tracebox(self.origin, PL_MIN, PL_MAX, self.origin, TRUE, self);
    if (trace_startsolid)
    {
        vector o;
        o = self.origin;
        self.mins = PL_MIN;
        self.maxs = PL_MAX;
        if (!move_out_of_solid(self))
            objerror("could not get out of solid at all!");
        print("^1NOTE: this map needs FIXING. Spawnpoint at ", vtos(o - '0 0 1'));
        print(" needs to be moved out of solid, e.g. by '", ftos(self.origin_x - o_x));
        print(" ", ftos(self.origin_y - o_y));
        print(" ", ftos(self.origin_z - o_z), "'\n");
        if (cvar("g_spawnpoints_auto_move_out_of_solid"))
        {
            if (!spawnpoint_nag)
                print("\{1}^1NOTE: this map needs FIXING (it contains spawnpoints in solid, see server log)\n");
            spawnpoint_nag = 1;
        }
        else
        {
            setorigin(self, o);
            self.mins = self.maxs = '0 0 0';
            objerror("player spawn point in solid, mapper sucks!\n");
            return;
        }
    }

    if (cvar("g_spawnpoints_autodrop"))
    {
        setsize(self, PL_MIN, PL_MAX);
        droptofloor();
    }

    self.use = spawnpoint_use;
    self.team_saved = self.team;
    if (!self.cnt)
        self.cnt = 1;

    if (teams_matter)
        if (self.team)
            have_team_spawns = 1;

    if (cvar("r_showbboxes"))
    {
        // show where spawnpoints point at too
        makevectors(self.angles);
        entity e;
        e = spawn();
        e.classname = "info_player_foo";
        setorigin(e, self.origin + v_forward * 24);
        setsize(e, '-8 -8 -8', '8 8 8');
        e.solid = SOLID_TRIGGER;
    }
}

#define strstr strstrofs
/*
// NOTE: DO NOT USE THIS FUNCTION TOO OFTEN.
// IT WILL MOST PROBABLY DESTROY _ALL_ OTHER TEMP
// STRINGS AND TAKE QUITE LONG. haystack and needle MUST
// BE CONSTANT OR strzoneD!
float strstr(string haystack, string needle, float offset)
{
	float len, endpos;
	string found;
	len = strlen(needle);
	endpos = strlen(haystack) - len;
	while(offset <= endpos)
	{
		found = substring(haystack, offset, len);
		if(found == needle)
			return offset;
		offset = offset + 1;
	}
	return -1;
}
*/

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
        if ((localhead.items == IT_KEY1 || localhead.items == IT_KEY2) && localhead.target == "###item###")
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
        loc = findnearest(p, target, "###item###", '1 1 4');
        if (loc)
            ret = loc.netname;
    }
    return ret;
}

string formatmessage(string msg)
{
    float p, p1, p2;
    float n;
    string escape;
    string replacement;
    p = 0;
    n = 7;
    while (1)
    {
        if (n < 1)
            break; // too many replacements
        n = n - 1;
        p1 = strstr(msg, "%", p); // NOTE: this destroys msg as it's a tempstring!
        p2 = strstr(msg, "\\", p); // NOTE: this destroys msg as it's a tempstring!

        if (p1 < 0)
            p1 = p2;
        if (p2 < 0)
            p2 = p1;
        p = min(p1, p2);

        if (p < 0)
            break;
        replacement = substring(msg, p, 2);
        escape = substring(msg, p + 1, 1);
        if (escape == "%")
            replacement = "%";
        else if (escape == "\\")
            replacement = "\\";
        else if (escape == "n")
            replacement = "\n";
        else if (escape == "a")
            replacement = ftos(floor(self.armorvalue));
        else if (escape == "h")
            replacement = ftos(floor(self.health));
        else if (escape == "l")
            replacement = NearestLocation(self.origin);
        else if (escape == "y")
            replacement = NearestLocation(self.cursor_trace_endpos);
        else if (escape == "d")
            replacement = NearestLocation(self.death_origin);
        else if (escape == "w")
        {
            float wep;
            wep = self.weapon;
            if (!wep)
                wep = self.switchweapon;
            if (!wep)
                wep = self.cnt;
            replacement = W_Name(wep);
        }
        else if (escape == "W")
        {
            if (self.items & IT_SHELLS) replacement = "shells";
            else if (self.items & IT_NAILS) replacement = "bullets";
            else if (self.items & IT_ROCKETS) replacement = "rockets";
            else if (self.items & IT_CELLS) replacement = "cells";
            else replacement = "batteries"; // ;)
        }
        else if (escape == "x")
        {
            replacement = self.cursor_trace_ent.netname;
            if (!replacement || !self.cursor_trace_ent)
                replacement = "nothing";
        }
        else if (escape == "p")
        {
            if (self.last_selected_player)
                replacement = self.last_selected_player.netname;
            else
                replacement = "(nobody)";
        }
        msg = strcat(substring(msg, 0, p), replacement, substring(msg, p+2, strlen(msg) - (p+2)));
        p = p + strlen(replacement);
    }
    return msg;
}

/*
=============
GetCvars
=============
Called with:
  0:  sends the request
  >0: receives a cvar from name=argv(f) value=argv(f+1)
*/
void GetCvars_handleString(string thisname, float f, .string field, string name)
{
	if (f < 0)
	{
		if (self.field)
			strunzone(self.field);
		self.field = string_null;
	}
	else if (f > 0)
	{
		if (thisname == name)
		{
			if (self.field)
				strunzone(self.field);
			self.field = strzone(argv(f + 1));
		}
	}
	else
		stuffcmd(self, strcat("sendcvar ", name, "\n"));
}
void GetCvars_handleString_Fixup(string thisname, float f, .string field, string name, string(string) func)
{
	GetCvars_handleString(thisname, f, field, name);
	if (f >= 0) // also initialize to the fitting value for "" when sending cvars out
		if (thisname == name)
		{
			string s;
			s = func(strcat1(self.field));
			if (s != self.field)
			{
				strunzone(self.field);
				self.field = strzone(s);
			}
		}
}
void GetCvars_handleFloat(string thisname, float f, .float field, string name)
{
	if (f < 0)
	{
	}
	else if (f > 0)
	{
		if (thisname == name)
			self.field = stof(argv(f + 1));
	}
	else
		stuffcmd(self, strcat("sendcvar ", name, "\n"));
}
void GetCvars_handleFloatOnce(string thisname, float f, .float field, string name)
{
	if (f < 0)
	{
	}
	else if (f > 0)
	{
		if (thisname == name)
		{
			if(!self.field)
			{
				self.field = stof(argv(f + 1));
				if(!self.field)
					self.field = -1;
			}
		}
	}
	else
	{
		if(!self.field)
			stuffcmd(self, strcat("sendcvar ", name, "\n"));
	}
}
string W_FixWeaponOrder_ForceComplete(string s);
string W_FixWeaponOrder_AllowIncomplete(string s);
float FakeInit_SendEntity(entity to, float sf);
void Net_LinkEntity(entity e, float docull, float dt, float(entity, float) sendfunc);
float w_getbestweapon(entity e);
void GetCvars(float f)
{
	string s;
	if (f > 0)
		s = strcat1(argv(f));
	GetCvars_handleFloat(s, f, autoswitch, "cl_autoswitch");
	GetCvars_handleFloat(s, f, cvar_cl_playerdetailreduction, "cl_playerdetailreduction");
	GetCvars_handleFloat(s, f, cvar_scr_centertime, "scr_centertime");
	GetCvars_handleFloat(s, f, cvar_cl_shownames, "cl_shownames");
	GetCvars_handleString(s, f, cvar_g_nexuizversion, "g_nexuizversion");
	GetCvars_handleFloat(s, f, cvar_cl_handicap, "cl_handicap");
	GetCvars_handleFloat(s, f, cvar_cl_gunalpha, "cl_gunalpha");
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriority, "cl_weaponpriority", W_FixWeaponOrder_ForceComplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[0], "cl_weaponpriority0", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[1], "cl_weaponpriority1", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[2], "cl_weaponpriority2", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[3], "cl_weaponpriority3", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[4], "cl_weaponpriority4", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[5], "cl_weaponpriority5", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[6], "cl_weaponpriority6", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[7], "cl_weaponpriority7", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[8], "cl_weaponpriority8", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[9], "cl_weaponpriority9", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleFloat(s, f, cvar_cl_autotaunt, "cl_autotaunt");
	GetCvars_handleFloat(s, f, cvar_cl_voice_directional, "cl_voice_directional");
	GetCvars_handleFloat(s, f, cvar_cl_voice_directional_taunt_attenuation, "cl_voice_directional_taunt_attenuation");
	GetCvars_handleFloat(s, f, cvar_cl_hitsound, "cl_hitsound");
#ifdef ALLOW_FORCEMODELS
	GetCvars_handleFloat(s, f, cvar_cl_forceplayermodels, "cl_forceplayermodels");
	GetCvars_handleFloat(s, f, cvar_cl_forceplayermodelsfromnexuiz, "cl_forceplayermodelsfromnexuiz");
#endif
	GetCvars_handleFloatOnce(s, f, cvar_cl_gunalign, "cl_gunalign");


	// fixup of switchweapon (needed for LMS or when spectating is disabled, as PutClientInServer comes too early)
	if (f > 0)
	{
		if (s == "cl_weaponpriority")
			self.switchweapon = w_getbestweapon(self);
		else if (!self.fake_init && s == "cl_gunalign")
		{
			self.fake_init = spawn();
			self.fake_init.owner = self;
			Net_LinkEntity(self.fake_init, FALSE, 0, FakeInit_SendEntity);
		}
	}
}

void backtrace(string msg)
{
    float dev, war;
    dev = cvar("developer");
    war = cvar("prvm_backtraceforwarnings");
    cvar_set("developer", "1");
    cvar_set("prvm_backtraceforwarnings", "1");
    dprint("\n");
    dprint("--- CUT HERE ---\nWARNING: ");
    dprint(msg);
    dprint("\n");
    remove(world); // isn't there any better way to cause a backtrace?
    dprint("\n--- CUT UNTIL HERE ---\n");
    cvar_set("developer", ftos(dev));
    cvar_set("prvm_backtraceforwarnings", ftos(war));
}

string Team_ColorCode(float teamid)
{
    if (teamid == COLOR_TEAM1)
        return "^1";
    else if (teamid == COLOR_TEAM2)
        return "^4";
    else if (teamid == COLOR_TEAM3)
        return "^3";
    else if (teamid == COLOR_TEAM4)
        return "^6";
    else
        return "^7";
}
string Team_ColorName(float t)
{
    // fixme: Search for team entities and get their .netname's!
    if (t == COLOR_TEAM1)
        return "Red";
    if (t == COLOR_TEAM2)
        return "Blue";
    if (t == COLOR_TEAM3)
        return "Yellow";
    if (t == COLOR_TEAM4)
        return "Pink";
    return "Neutral";
}
string Team_ColorNameLowerCase(float t)
{
    // fixme: Search for team entities and get their .netname's!
    if (t == COLOR_TEAM1)
        return "red";
    if (t == COLOR_TEAM2)
        return "blue";
    if (t == COLOR_TEAM3)
        return "yellow";
    if (t == COLOR_TEAM4)
        return "pink";
    return "neutral";
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
    if (time > e.centerprint_expires)
        e.centerprint_priority = 0;
    if (prio >= e.centerprint_priority)
    {
        e.centerprint_priority = prio;
        if (timeoutStatus == 2)
            e.centerprint_expires = time + (e.cvar_scr_centertime * TIMEOUT_SLOWMO_VALUE);
        else
            e.centerprint_expires = time + e.cvar_scr_centertime;
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
    if (teams_matter && !intermission_running && p.classname == "player")
    {
        t = Team_ColorCode(p.team);
        return strcat(t, strdecolorize(p.netname));
    }
    else
        return p.netname;
}

vector randompos(vector m1, vector m2)
{
    local vector v;
    m2 = m2 - m1;
    v_x = m2_x * random() + m1_x;
    v_y = m2_y * random() + m1_y;
    v_z = m2_z * random() + m1_z;
    return  v;
};

entity get_weaponinfo(float w);

void weapon_precache(float wpn)
{
	string s = get_weaponinfo(wpn).mdl;
	precache_model(strcat("models/weapons/g_", s, ".md3"));
	precache_model(strcat("models/weapons/v_", s, ".md3"));
	precache_model(strcat("models/weapons/h_", s, ".dpm"));
	(get_weaponinfo(wpn)).weapon_func(WR_PRECACHE);
}

/*
// TODO sound pack system
string soundpack;

string precache_sound_builtin (string s) = #19;
void(entity e, float chan, string samp, float vol, float atten) sound_builtin = #8;
string precache_sound(string s)
{
	return precache_sound_builtin(strcat(soundpack, s));
}
void play2(entity e, string filename)
{
	stuffcmd(e, strcat("play2 ", soundpack, filename, "\n"));
}
void sound(entity e, float chan, string samp, float vol, float atten)
{
	sound_builtin(e, chan, strcat(soundpack, samp), vol, atten);
}
*/

// Sound functions
string precache_sound (string s) = #19;
void(entity e, float chan, string samp, float vol, float atten) sound_builtin = #8;
float precache_sound_index (string s) = #19;

#define SND_VOLUME      1
#define SND_ATTENUATION 2
#define SND_LARGEENTITY 8
#define SND_LARGESOUND  16

float sound_allowed(float dest, entity e)
{
    // sounds from world may always pass
    for (;;)
    {
        if (e.classname == "body")
            e = e.enemy;
        if (e.owner && e.owner != e)
            e = e.owner;
        else
            break;
    }
    // sounds to self may always pass
    if (dest == MSG_ONE)
        if (e == msg_entity)
            return TRUE;
    // sounds by players can be removed
    if (cvar("bot_sound_monopoly"))
        if (clienttype(e) == CLIENTTYPE_REAL)
            return FALSE;
    // anything else may pass
    return TRUE;
}

void sound(entity e, float chan, string samp, float vol, float atten)
{
    if (!sound_allowed(MSG_BROADCAST, e))
        return;
    sound_builtin(e, chan, samp, vol, atten);
}
void soundtoat(float dest, entity e, vector o, float chan, string samp, float vol, float atten)
{
    float entno, idx;

    if (!sound_allowed(dest, e))
        return;

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

    if (!sound_allowed(dest, e))
        return;

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

    if (!sound_allowed(dest, e))
        return;

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
    if (!sound_allowed(MSG_BROADCAST, e))
        return;

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
    if (!sound_allowed(MSG_BROADCAST, e))
        return FALSE;

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

    if (cvar("bot_sound_monopoly"))
        return;

    FOR_EACH_REALPLAYER(head)
    {
        if (head.team == t)
            play2(head, filename);
    }
}

void play2all(string samp)
{
    if (cvar("bot_sound_monopoly"))
        return;

    sound(world, CHAN_AUTO, samp, VOL_BASE, ATTN_NONE);
}

void PrecachePlayerSounds(string f);
void precache_all_models(string pattern)
{
    float globhandle, i, n;
    string f;

    globhandle = search_begin(pattern, TRUE, FALSE);
    if (globhandle < 0)
        return;
    n = search_getsize(globhandle);
    for (i = 0; i < n; ++i)
    {
		//print(search_getfilename(globhandle, i), "\n");
		f = search_getfilename(globhandle, i);
		if(sv_loddistance1)
			precache_model(f);
		if(substring(f, -9,5) == "_lod1")
			continue;
		if(substring(f, -9,5) == "_lod2")
			continue;
		if(!sv_loddistance1)
			precache_model(f);
		PrecachePlayerSounds(strcat(f, ".sounds"));
    }
    search_end(globhandle);
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

#define INITPRIO_FIRST              0
#define INITPRIO_GAMETYPE           0
#define INITPRIO_GAMETYPE_FALLBACK  1
#define INITPRIO_CVARS              5
#define INITPRIO_FINDTARGET        10
#define INITPRIO_DROPTOFLOOR       20
#define INITPRIO_SETLOCATION       90
#define INITPRIO_LINKDOORS         91
#define INITPRIO_LAST              99

.void(void) initialize_entity;
.float initialize_entity_order;
.entity initialize_entity_next;
entity initialize_entity_first;

void make_safe_for_remove(entity e)
{
    if (e.initialize_entity)
    {
        entity ent, prev;
        for (ent = initialize_entity_first; ent; )
        {
            if ((ent == e) || ((ent.classname == "initialize_entity") && (ent.enemy == e)))
            {
                //print("make_safe_for_remove: getting rid of initializer ", etos(ent), "\n");
                // skip it in linked list
                if (prev)
                {
                    prev.initialize_entity_next = ent.initialize_entity_next;
                    ent = prev.initialize_entity_next;
                }
                else
                {
                    initialize_entity_first = ent.initialize_entity_next;
                    ent = initialize_entity_first;
                }
            }
            else
            {
                prev = ent;
                ent = ent.initialize_entity_next;
            }
        }
    }
}

void objerror(string s)
{
    make_safe_for_remove(self);
    objerror_builtin(s);
}

void remove_unsafely(entity e)
{
    remove_builtin(e);
}

void remove_safely(entity e)
{
    make_safe_for_remove(e);
    remove_builtin(e);
}

void InitializeEntity(entity e, void(void) func, float order)
{
    entity prev, cur;

    if (!e || e.initialize_entity)
    {
        // make a proxy initializer entity
        entity e_old;
        e_old = e;
        e = spawn();
        e.classname = "initialize_entity";
        e.enemy = e_old;
    }

    e.initialize_entity = func;
    e.initialize_entity_order = order;

    cur = initialize_entity_first;
    for (;;)
    {
        if (!cur || cur.initialize_entity_order > order)
        {
            // insert between prev and cur
            if (prev)
                prev.initialize_entity_next = e;
            else
                initialize_entity_first = e;
            e.initialize_entity_next = cur;
            return;
        }
        prev = cur;
        cur = cur.initialize_entity_next;
    }
}
void InitializeEntitiesRun()
{
    entity startoflist;
    startoflist = initialize_entity_first;
    initialize_entity_first = world;
    for (self = startoflist; self; )
    {
        entity e;
        var void(void) func;
        e = self.initialize_entity_next;
        func = self.initialize_entity;
        self.initialize_entity_order = 0;
        self.initialize_entity = func_null;
        self.initialize_entity_next = world;
        if (self.classname == "initialize_entity")
        {
            entity e_old;
            e_old = self.enemy;
            remove_builtin(self);
            self = e_old;
        }
        //dprint("Delayed initialization: ", self.classname, "\n");
        func();
        self = e;
    }
}

.float uncustomizeentityforclient_set;
.void(void) uncustomizeentityforclient;
void(void) SUB_Nullpointer = #0;
void UncustomizeEntitiesRun()
{
    entity oldself;
    oldself = self;
    for (self = world; (self = findfloat(self, uncustomizeentityforclient_set, 1)); )
        self.uncustomizeentityforclient();
    self = oldself;
}
void SetCustomizer(entity e, float(void) customizer, void(void) uncustomizer)
{
    e.customizeentityforclient = customizer;
    e.uncustomizeentityforclient = uncustomizer;
    e.uncustomizeentityforclient_set = (uncustomizer != SUB_Nullpointer);
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

#define PROJECTILE_SKIPNONSOLID if (sv_gameplayfix_skipnonsolid) if(projectile_skipnonsolid()) { return; }
#define PROJECTILE_TOUCH do { PROJECTILE_SKIPNONSOLID if(SUB_OwnerCheck()) return; if(SUB_NoImpactCheck()) { remove(self); return; } if(trace_ent && trace_ent.solid > SOLID_TRIGGER) UpdateCSQCProjectileNextFrame(self); } while(0)

float MAX_IPBAN_URIS = 16;

float URI_GET_DISCARD   = 0;
float URI_GET_IPBAN     = 1;
float URI_GET_IPBAN_END = 16;

void URI_Get_Callback(float id, float status, string data)
{
    dprint("Received HTTP request data for id ", ftos(id), "; status is ", ftos(status), "\nData is:\n");
    dprint(data);
    dprint("\nEnd of data.\n");

    if (id == URI_GET_DISCARD)
    {
        // discard
    }
    else if (id >= URI_GET_IPBAN && id <= URI_GET_IPBAN_END)
    {
        // online ban list
        OnlineBanList_URI_Get_Callback(id, status, data);
    }
    else
    {
        print("Received HTTP request data for an invalid id ", ftos(id), ".\n");
    }
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

float MoveToRandomMapLocation(entity e, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float minviewdistance)
{
    float m, i;
    vector start, org, delta, end, enddown, mstart;

    m = e.dphitcontentsmask;
    e.dphitcontentsmask = goodcontents | badcontents;

    org = world.mins;
    delta = world.maxs - world.mins;

    for (i = 0; i < attempts; ++i)
    {
        start_x = org_x + random() * delta_x;
        start_y = org_y + random() * delta_y;
        start_z = org_z + random() * delta_z;

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

        // rule 3: make sure we aren't outside the map. This only works
        // for somewhat well formed maps. A good rule of thumb is that
        // the map should have a convex outside hull.
        // these can be traceLINES as we already verified the starting box
        mstart = start + 0.5 * (e.mins + e.maxs);
        traceline(mstart, mstart + '1 0 0' * delta_x, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        traceline(mstart, mstart - '1 0 0' * delta_x, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        traceline(mstart, mstart + '0 1 0' * delta_y, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        traceline(mstart, mstart - '0 1 0' * delta_y, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        traceline(mstart, mstart + '0 0 1' * delta_z, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;

        // find a random vector to "look at"
        end_x = org_x + random() * delta_x;
        end_y = org_y + random() * delta_y;
        end_z = org_z + random() * delta_z;
        end = start + normalize(end - start) * vlen(delta);

        // rule 4: start TO end must not be too short
        tracebox(start, e.mins, e.maxs, end, MOVE_NORMAL, e);
        if (trace_startsolid)
            continue;
        if (trace_fraction < minviewdistance / vlen(delta))
            continue;

        // rule 5: don't want to look at sky
        if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
            continue;

        // rule 6: we must not end up in trigger_hurt
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
        setorigin(e, start);
        e.angles = vectoangles(end - start);
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
    GameLogEcho(strcat(":recordset:", ftos(pl.playerid), ":", ftos(dt)));

    // also write a marker into demo files for demotc-race-record-extractor to find
    stuffcmd(pl,
             strcat(
                 strcat("//", strconv(2, 0, 0, GetGametype()), " RECORD SET ", TIME_ENCODED_TOSTRING(TIME_ENCODE(dt))),
                 " ", ftos(tstart), " ", ftos(dt), "\n"));
}

vector shotorg_adjustfromclient(vector vecs, float y_is_right, float allowcenter)
{
	switch(self.owner.cvar_cl_gunalign)
	{
		case 1: // right
			break;

		case 2: // left
			vecs_y = -vecs_y;
			break;

		default:
		case 3:
			if(allowcenter) // 2: allow center handedness
			{
				// center
				vecs_y = 0;
				vecs_z -= 4;
			}
			else
			{
				// right
			}
			break;

		case 4:
			if(allowcenter) // 2: allow center handedness
			{
				// center
				vecs_y = 0;
				vecs_z -= 4;
			}
			else
			{
				// left
				vecs_y = -vecs_y;
			}
			break;
	}
	return vecs;
}

vector shotorg_adjust(vector vecs, float y_is_right, float visual, float akimbo_active)
{
	string s;
	vector v;
	if (akimbo_active)
	{
		if (akimbo_active == 2)
			vecs_y = -vecs_y;
		if not(visual)
		{
			if (cvar("g_shootfromeye"))
				vecs_z = 0;
			else if (cvar("g_shootfromcenter"))
				vecs_z -= 0;
			else if ((s = cvar_string("g_shootfromfixedorigin")) != "")
			{
				v = stov(s);
				if (v_x != 0)
					vecs_x = v_x;
				vecs_z = v_z;
			}
		}
		vecs_y = vecs_y * 1.2;
		return vecs;
	}

	if (cvar("g_shootfromeye"))
	{
		if (visual)
		{
			vecs = shotorg_adjustfromclient(vecs, y_is_right, TRUE);
		}
		else
		{
			vecs_y = 0;
			vecs_z = 0;
		}
	}
	else if (cvar("g_shootfromcenter"))
	{
		if (visual)
		{
			vecs = shotorg_adjustfromclient(vecs, y_is_right, TRUE);
		}
		else
		{
			vecs_y = 0;
			vecs_z -= 4;
		}
	}
	else if (cvar("g_shootfromclient"))
	{
		vecs = shotorg_adjustfromclient(vecs, y_is_right, (cvar("g_shootfromclient") >= 2));
	}
	else if ((s = cvar_string("g_shootfromfixedorigin")) != "")
	{
		v = stov(s);
		if (y_is_right)
			v_y = -v_y;
		if (v_x != 0)
			vecs_x = v_x;
		vecs_y = v_y;
		vecs_z = v_z;
	}
	return vecs;
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
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
        e.angles_x = -e.angles_x;
    fixedmakevectors(e.angles);

    // untransform forward, up!
    e_forward_x = v_forward * t_forward;
    e_forward_y = v_forward * t_left;
    e_forward_z = v_forward * t_up;
    e_up_x = v_up * t_forward;
    e_up_y = v_up * t_left;
    e_up_z = v_up * t_up;

    e.angles = fixedvectoangles2(e_forward, e_up);
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

void SoundEntity_StartSound(entity pl, float chan, string samp, float vol, float attn)
{
    float p;
    p = pow(2, chan);
    if (pl.soundentity.cnt & p)
        return;
    soundtoat(MSG_ALL, pl.soundentity, gettaginfo(pl.soundentity, 0), chan, samp, vol, attn);
    pl.soundentity.cnt |= p;
}

void SoundEntity_StopSound(entity pl, float chan)
{
    float p;
    p = pow(2, chan);
    if (pl.soundentity.cnt & p)
    {
        stopsoundto(MSG_ALL, pl.soundentity, chan);
        pl.soundentity.cnt &~= p;
    }
}

void SoundEntity_Attach(entity pl)
{
    pl.soundentity = spawn();
    pl.soundentity.classname = "soundentity";
    pl.soundentity.owner = pl;
    setattachment(pl.soundentity, pl, "");
    setmodel(pl.soundentity, "null");
}

void SoundEntity_Detach(entity pl)
{
    float i;
    for (i = 0; i <= 7; ++i)
        SoundEntity_StopSound(pl, i);
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

float randombit(float bits)
{
	if not(bits & (bits-1)) // this ONLY holds for powers of two!
		return bits;

	float n, f, b, r;

	r = random();
	b = 0;
	n = 0;

	for(f = 1; f <= bits; f *= 2)
	{
		if(bits & f)
		{
			++n;
			r *= n;
			if(r <= 1)
				b = f;
			else
				r = (r - 1) / (n - 1);
		}
	}

	return b;
}

float randombits(float bits, float k, float error_return)
{
	float r;
	r = 0;
	while(k > 0 && bits != r)
	{
		r += randombit(bits - r);
		--k;
	}
	if(error_return)
		if(k > 0)
			return -1; // all
	return r;
}

void randombit_test(float bits, float iter)
{
	while(iter > 0)
	{
		print(ftos(randombit(bits)), "\n");
		--iter;
	}
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

/**
 * Resets the state of all clients, items, flags, runes, keys, weapons, waypoints, ... of the map.
 * Sets the 'warmup' global variable.
 */
void reset_map(float dorespawn)
{
	entity oldself;
	oldself = self;

	GameHook_Reset();
	HG_MapReset();

	for(self = world; (self = nextent(self)); )
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT)
	{
		if(self.reset)
		{
			self.reset();
			continue;
		}

		if(self.team_saved)
			self.team = self.team_saved;

		if(self.flags & FL_PROJECTILE) // remove any projectiles left
		{
			stopsound(self, CHAN_PAIN);
			remove(self);
		}
	}

	// Waypoints and assault start come LAST
	for(self = world; (self = nextent(self)); )
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT)
	{
		if(self.reset2)
		{
			self.reset2();
			continue;
		}
	}

	// Moving the player reset code here since the player-reset depends
	// on spawnpoint entities which have to be reset first --blub
	if(dorespawn)
	FOR_EACH_CLIENT(self) {
		if(self.flags & FL_CLIENT)				// reset all players
		if (self.classname == "player") {
			//PlayerScore_Clear(self);
			self.killcount = 0;
			//stop the player from moving so that he stands still once he gets respawned
			self.velocity = '0 0 0';
			self.avelocity = '0 0 0';
			self.movement = '0 0 0';
			PutClientInServer();
		}
	}

	self = oldself;
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
	defer_for(world, t, callback);
}

vector RandomSpreadVector(float side, float up, float up_min, float up_min_rand) {
    vector v;
	v_x = crandom() * 2 * side;
	v_y = crandom() * 2 * side;
	v_z = max(up * random(), up_min + up_min_rand * crandom() * 2);
	return v;
}

vector CircleSpreadVector(float side, float up, float sangle) {
    return  side * v_forward * cos(sangle) +
            side * v_right   * sin(sangle) +
            up   * v_up;
}
