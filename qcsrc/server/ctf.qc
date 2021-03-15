#define FLAG_MIN (PL_MIN + '0 0 -13')
#define FLAG_MAX (PL_MAX + '0 0 -13')

float ST_CTF_CAPS;
float SP_CTF_CAPS;
float SP_CTF_PICKUPS;
float SP_CTF_DROPS;
float SP_CTF_FCKILLS;
float SP_CTF_RETURNS;

float g_ctf;
float g_ctf_damageforcescale;
float g_ctf_delay_collect;
float g_ctf_allow_drop;
float g_ctf_captimerecord_always;
float g_ctf_default_teams;
float g_ctf_flag_capture_effects;
float g_ctf_flag_pickup_effects;
float g_ctf_flag_returntime;
float g_ctf_personalpenalty_drop;
float g_ctf_personalpenalty_returned;
float g_ctf_personalpenalty_suicidedrop;
float g_ctf_personalscore_capture;
float g_ctf_personalscore_pickup_base;
float g_ctf_personalscore_pickup_dropped_early;
float g_ctf_personalscore_pickup_dropped_late;
float g_ctf_personalscore_return;
float g_ctf_personalscore_return_by_killer;
float g_ctf_personalscore_return_rogue;
float g_ctf_personalscore_return_rogue_by_killer;
float g_ctf_reverse;
float g_ctf_flagpenalty_drop;
float g_ctf_flagpenalty_returned;
float g_ctf_flagpenalty_suicidedrop;
float g_ctf_flagscore_capture;
float g_ctf_flagscore_pickup_base;
float g_ctf_flagscore_pickup_dropped_early;
float g_ctf_flagscore_pickup_dropped_late;
float g_ctf_flagscore_return;
float g_ctf_flagscore_return_by_killer;
float g_ctf_flagscore_return_rogue;
float g_ctf_flagscore_return_rogue_by_killer;
float g_ctf_win_mode;
float g_ctf_ignore_frags;
float g_ctf_flagcarrier_selfdamage;
float g_ctf_flagcarrier_selfforce;
float g_ctf_flagscore_kill;
float g_ctf_personalscore_kill;
float g_ctf_showenemycarrier;
float g_ctf_showenemycarrier_delay;

#define CTF_SCORE_VALUE(x) ((g_ctf_win_mode != 2 ) ? g_ctf_personal##x : g_ctf_flag##x)

.entity basewaypoint;
.entity sprite;
entity ctf_worldflaglist; // CTF flags in the map
.entity ctf_worldflagnext;
.float dropperid;
.float ctf_droptime;

.float next_take_time;			// the next time a player can pick up a flag (time + blah)
								/// I used this, in part, to fix the looping score bug. - avirox
//float FLAGSCORE_PICKUP        =  1;
//float FLAGSCORE_RETURN        =  5; // returned by owner team
//float FLAGSCORE_RETURNROGUE   = 10; // returned by rogue team
//float FLAGSCORE_CAPTURE       =  5;

#define FLAG_CARRY_POS '-15 0 7'

.float ctf_captureshielded; // set to 1 if the player is too bad to be allowed to capture

float captureshield_min_negscore; // punish at -20 points
float captureshield_max_ratio; // punish at most 30% of each team
float captureshield_force; // push force of the shield

void() ctf_flag_think;
void() ctf_flag_touch;

var void() ctf_PlayerPreThink_NextLink;
void ctf_PlayerPreThink();

float(entity attacker, entity targ, float f) ctf_handle_frags {
	if(g_ctf_ignore_frags)
		return 0;

	if (f < 0)
		return f;

	if (targ.flagcarried) {
		score_player_add(attacker, SP_CTF_FCKILLS, 1);
		f = ((g_ctf_win_mode != 2 ) ? g_ctf_personalscore_kill : g_ctf_flagscore_kill);
		if not(f)
			score_player_team_add_score(attacker, f);
	}
	return f;
}

float(entity p) ctf_captureshield_shielded {
	float s, se;
	entity e;
	float players_worseeq, players_total;

	if(captureshield_max_ratio <= 0)
		return FALSE;

	s = score_player_add(p, SP_SCORE, 0);
	if(s >= -captureshield_min_negscore)
		return FALSE;

	players_total = players_worseeq = 0;
	FOR_EACH_PLAYER(e)
	{
		if(e.team != p.team)
			continue;
		se = score_player_add(e, SP_SCORE, 0);
		if(se <= s)
			++players_worseeq;
		++players_total;
	}

	// player is in the worse half, if >= half the players are better than him, or consequently, if < half of the players are worse
	// use this rule here
	
	if(players_worseeq >= players_total * captureshield_max_ratio)
		return FALSE;

	return TRUE;
}

void(entity p, float dir) ctf_captureshield_update {
	float should;
	if(dir == p.ctf_captureshielded) // 0: shield only, 1: unshield only
	{
		should = ctf_captureshield_shielded(p);
		if(should != dir)
		{
			if(should)
			{
				centerprint_atprio(p, CENTERPRIO_SHIELDING, "^3You are now ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Make some defensive scores before trying again.");
				// TODO csqc notifier for this
			}
			else
			{
				centerprint_atprio(p, CENTERPRIO_SHIELDING, "^3You are now free.\n\n^3Feel free to ^1try to capture^3 the flag again\n^3if you think you will succeed.");
				// TODO csqc notifier for this
			}
			p.ctf_captureshielded = should;
		}
	}
}

float() ctf_captureshield_customize {
	if not(other.ctf_captureshielded)
		return FALSE;
	if(self.team == other.team)
		return FALSE;
	return TRUE;
}

void() ctf_captureshield_touch {
	if not(other.ctf_captureshielded)
		return;
	if(self.team == other.team)
		return;
	vector mymid;
	vector othermid;
	mymid = (self.absmin + self.absmax) * 0.5;
	othermid = (other.absmin + other.absmax) * 0.5;
	damage(other, self, self, 0, DEATH_HURTTRIGGER, mymid, normalize(othermid - mymid) * captureshield_force);
	centerprint_atprio(other, CENTERPRIO_SHIELDING, "^3You are ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Get some defensive scores before trying again.");
}

void() ctf_captureshield_spawn {
	entity e;
	e = spawn();
	e.enemy = self;
	e.team = self.team;
	e.touch = ctf_captureshield_touch;
	e.customizeentityforclient = ctf_captureshield_customize;
	e.classname = "ctf_captureshield";
	e.effects = EF_ADDITIVE;
	e.movetype = MOVETYPE_NOCLIP;
	e.solid = SOLID_TRIGGER;
	e.avelocity = '7 0 11';
	setorigin(e, self.origin);
	setmodel(e, "models/ctf/shield.md3");
	e.scale = 0.5;
	setsize(e, e.scale * e.mins, e.scale * e.maxs);
}

float   flagcaptimerecord;
.float  flagpickuptime;
//.float  iscommander;
//.float  ctf_state;

void() ctf_flag_place {
	if(self.classname != "ctf_flag_team")
	{
		backtrace("PlaceFlag a non-flag");
		return;
	}

	if(!self.t_width)
		self.t_width = 0.1; // frame animation rate
	if(!self.t_length)
		self.t_length = 58; // maximum frame

	setattachment(self, world, "");
	self.mdl = self.model;
	self.flags = FL_ITEM;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	self.think = ctf_flag_think;
	self.touch = ctf_flag_touch;
	self.nextthink = time + 0.1;
	self.cnt = FLAG_BASE;
	self.mangle = self.angles;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	//self.effects = self.effects | EF_DIMLIGHT;
	if(self.noalign)
	{
		self.dropped_origin = self.origin;
	}
	else
	{
		entity_droptofloor();
		self.movetype = MOVETYPE_TOSS;
	}
	entity_initialize(self, ctf_captureshield_spawn, INITPRIO_SETLOCATION);
}

void(entity e) ctf_flag_regen {
	if(e.classname != "ctf_flag_team")
	{
		backtrace("RegenFlag a non-flag");
		return;
	}

	setattachment(e, world, "");
	e.damageforcescale = 0;
	e.takedamage = DAMAGE_NO;
	e.movetype = MOVETYPE_NONE;
	if(!e.noalign)
		e.movetype = MOVETYPE_TOSS;
	e.velocity = '0 0 0';
	e.solid = SOLID_TRIGGER;
	// TODO: play a sound here
	setorigin(e, e.dropped_origin);
	e.angles = e.mangle;
	e.cnt = FLAG_BASE;
	e.owner = world;
	e.flags = FL_ITEM; // clear FL_ONGROUND and any other junk
}

void(entity e) ctf_flag_return {
	if(e.classname != "ctf_flag_team")
	{
		backtrace("ReturnFlag a non-flag");
		return;
	}

	if (e.owner)
	if (e.owner.flagcarried == e)
	{
		WaypointSprite_DetachCarrier(e.owner);
		e.owner.flagcarried = world;
	}
	e.owner = world;
	ctf_flag_regen(e);
}

void(entity e, entity penalty_receiver, entity attacker) ctf_flag_drop {
	entity p;

	if(e.classname != "ctf_flag_team")
	{
		backtrace("DropFlag a non-flag");
		return;
	}

	if (!e.owner)
		return;

	p = e.owner;
	if (p.flagcarried != e)
		return;

	bprint(p.netname, "^7 lost the ", e.netname, "\n");

	if(penalty_receiver)
		score_player_team_add_score(penalty_receiver, -CTF_SCORE_VALUE(penalty_suicidedrop));
	else
		score_player_team_add_score(p, -CTF_SCORE_VALUE(penalty_drop));
	score_player_add(p, SP_CTF_DROPS, +1);
	ctf_captureshield_update(p, 0); // shield only
	e.playerid = attacker.playerid;
	e.ctf_droptime = time;
	
	if(p.waypointsprite_attachedforcarrier)
	{
		WaypointSprite_Ping(p.waypointsprite_attachedforcarrier);
		WaypointSprite_DetachCarrier(p);
	}
	//else
	//{
	//	bprint("\{1}^1Flag carrier had no flag sprite?!?\n");
	//	backtrace("Flag carrier had no flag sprite?!?");
	//}
	GameStatus_Set(strcat(team_color_code(e.team), team_color_name(e.team), " Flag^7 dropped"), 1);
	sound (e, CHAN_TRIGGER, e.noise4, VOL_BASE, ATTN_NONE);

	setattachment(e, world, "");
	e.damageforcescale = g_ctf_damageforcescale;
	e.takedamage = DAMAGE_YES;

	if (p.flagcarried == e)
		p.flagcarried = world;
	e.owner = world;

	e.flags = FL_ITEM; // clear FL_ONGROUND and any other junk
	e.solid = SOLID_TRIGGER;
	e.movetype = MOVETYPE_TOSS;
	// setsize(e, '-16 -16 0', '16 16 74');
	setorigin(e, p.origin - '0 0 24' + '0 0 37');
	e.cnt = FLAG_DROPPED;
	e.velocity = '0 0 300';
	e.pain_finished = time + g_ctf_flag_returntime;//30;

	trace_startsolid = FALSE;
	trace_box(e.origin, e.mins, e.maxs, e.origin, TRUE, e);
}

void() ctf_animate_flag {
	if(self.delay > time)
		return;
	self.delay = time + self.t_width;
	if(self.nextthink > self.delay)
		self.nextthink = self.delay;

	self.frame = self.frame + 1;
	if(self.frame > self.t_length)
		self.frame = 0;
}

void() ctf_flag_think {
	entity e;

	self.nextthink = time + 0.1;

	// sorry, we have to reset the flag size if it got squished by something
	if(self.mins != FLAG_MIN || self.maxs != FLAG_MAX)
	{
		// if we can grow back, grow back
		trace_box(self.origin, FLAG_MIN, FLAG_MAX, self.origin, MOVE_NOMONSTERS, self);
		if(!trace_startsolid)
			setsize(self, FLAG_MIN, FLAG_MAX);
	}

	if(self == ctf_worldflaglist) // only for the first flag
	{
		FOR_EACH_CLIENT(e)
			ctf_captureshield_update(e, 1); // release shield only
	}
	ctf_animate_flag();
	if (self.cnt == FLAG_BASE)
		return;

	if (self.cnt == FLAG_DROPPED)
	{
		// flag fallthrough? FIXME remove this if bug is really fixed now
		if(self.origin_z < -131072)
			self.pain_finished = 0;

		setattachment(self, world, "");
		if (time > self.pain_finished)
		{
			bprint("The ", self.netname, " has returned to base\n");
			sound (self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NONE);
			ctf_flag_return(self);
		}
		return;
	}

	e = self.owner;
	if (e.classname != "player" || (e.deadflag) || (e.flagcarried != self))
	{
		ctf_flag_drop(self, world, world);
		return;
	}

	if(g_ctf_allow_drop)
	if(e.BUTTON_DROP)
		ctf_flag_drop(self, e, world);
}

void(vector org) ctf_flag_cap_ring_spawn {
	effect_shockwave_spawn("models/ctf/shockwavetransring.md3", org - '0 0 15', -0.8, 0, 1);
}

float() ctf_flagcarrier_visible {
	if (other.team == self.owner.team)
		return TRUE;

	if (g_ctf_showenemycarrier)
	if (time > self.owner.flagcarried.flagpickuptime + g_ctf_showenemycarrier_delay) {
		return TRUE;
	}
	return FALSE;
}

void() ctf_flag_touch {
	if(map_finished) return;
	if (game == GAME_CATF || game == GAME_CTFT)
	if not(Roundbased_Active)
		return;

	float t;
	entity player;
	string s, s0, h0, h1;
	if (other.classname != "player")
		return;
	if (PLAYER_DEAD(other)) // ignore dead players
		return;

	if (other.saboteur) //ignore saboteurs
	if (other.team != self.team)
		return;

	if not(gamehook_chain_PlayerCanBeCarrier(other))
		return;

	if (self.cnt == FLAG_CARRY)
		return;

	if (self.cnt == FLAG_BASE)
	if (other.team == self.team)
	if (other.flagcarried) // he's got a flag
	if (other.flagcarried.team != self.team) // capture
	{
		if (other.flagcarried == world)
		{
			return;
		}
		if(g_ctf_captimerecord_always || player_count - bot_count <= 1) // at most one human
		{
			t = time - other.flagcarried.flagpickuptime;
			s = str_float_decimals(t, 2);
			s0 = str_float_decimals(flagcaptimerecord, 2);
			h0 = db_get(db_server, strcat(mapname, "/captimerecord/netname"));
			h1 = other.netname;
			if(h0 == h1)
				h0 = "their";
			else
				h0 = strcat(h0, "^7's"); // h0: display text for previous netname
			if (flagcaptimerecord == 0)
			{
				bprint(other.netname, "^7 captured the ", other.flagcarried.netname, " in ", s, " seconds\n");
				flagcaptimerecord = t;
				db_put(db_server, strcat(mapname, "/captimerecord/time"), ftos(t));
				db_put(db_server, strcat(mapname, "/captimerecord/netname"), h1);
				client_write_recordmarker(other, time - t, t);
			}
			else if (t < flagcaptimerecord)
			{
				bprint(other.netname, "^7 captured the ", other.flagcarried.netname, " in ", s, ", breaking ", strcat(h0, " previous record of ", s0, " seconds\n"));
				flagcaptimerecord = t;
				db_put(db_server, strcat(mapname, "/captimerecord/time"), ftos(t));
				db_put(db_server, strcat(mapname, "/captimerecord/netname"), h1);
				client_write_recordmarker(other, time - t, t);
			}
			else
			{
				bprint(other.netname, "^7 captured the ", other.flagcarried.netname, " in ", s, ", failing to break ", strcat(h0, " record of ", s0, " seconds\n"));
			}
		}
		else
			bprint(other.netname, "^7 captured the ", other.flagcarried.netname, "\n");

		score_player_team_add(other, SP_CTF_CAPS, ST_CTF_CAPS, 1);
		if (game == GAME_CATF || game == GAME_CTFT)
			Roundbased_SetRoundStartWithWinner(other.team);

		// give credit to the individual player
		score_player_team_add_score(other, CTF_SCORE_VALUE(score_capture));

		if (g_ctf_flag_capture_effects) {
			if (other.team == COLOR_TEAM1) { // red team scores effect
				pointparticles(particleeffectnum("red_ground_quake"), self.origin, '0 0 0', 1);
				ctf_flag_cap_ring_spawn(self.origin);
			}
			if (other.team == COLOR_TEAM2) { // blue team scores effect
				pointparticles(particleeffectnum("blue_ground_quake"), self.origin, '0 0 0', 1);
				ctf_flag_cap_ring_spawn(self.origin);
			}
		}

		sound (other, CHAN_AUTO, self.noise2, VOL_BASE, ATTN_NONE);
		GameStatus_Set(strcat(team_color_code(self.team), team_color_name(self.team), " Team^7 scores"), 1);
		WaypointSprite_DetachCarrier(other);
		ctf_flag_regen (other.flagcarried);
		other.flagcarried = world;
		other.next_take_time = time + 1;
	}
	if (self.cnt == FLAG_BASE)
	if (other.team == COLOR_TEAM1 || other.team == COLOR_TEAM2) // only red and blue team can steal flags
	if (other.team != self.team)
	if (!other.flagcarried)
	if (!other.ctf_captureshielded)
	{
		if (other.next_take_time > time)
			return;
			
		if (g_ctf_flag_pickup_effects) // pickup effect
			pointparticles(particleeffectnum("smoke_ring"), 0.5 * (self.absmin + self.absmax), '0 0 0', 1);
			
		// pick up
		self.flagpickuptime = time; // used for timing runs
		self.solid = SOLID_NOT;
		setorigin(self, self.origin); // relink
		self.owner = other;
		other.flagcarried = self;
		self.cnt = FLAG_CARRY;
		self.angles = '0 0 0';
		bprint(other.netname, "^7 got the ", self.netname, "\n");
		score_player_team_add_score(other, CTF_SCORE_VALUE(score_pickup_base));
		self.dropperid = other.playerid;
		score_player_add(other, SP_CTF_PICKUPS, 1);
		GameStatus_Set(strcat(team_color_code(self.team), team_color_name(self.team), " Flag^7 taken"), 1);
		centerprint(other, "You have the flag!");
		sound (other, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NONE);

		FOR_EACH_PLAYER(player)
			if(player.team == self.team)
				centerprint(player, "The enemy got your flag! Retrieve it!");

		self.movetype = MOVETYPE_NONE;
		setorigin(self, FLAG_CARRY_POS);
		setattachment(self, other.body, "");
		WaypointSprite_AttachCarrier("flagcarrier", other);
		WaypointSprite_UpdateRule(other.waypointsprite_attachedforcarrier, other.team, SPRITERULE_TEAMPLAY);
		WaypointSprite_UpdateSprites(other.waypointsprite_attachedforcarrier, "flagcarrier", "flagcarrier", "flagcarrier");
		other.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = ctf_flagcarrier_visible;
		WaypointSprite_UpdateTeamRadar(other.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '1 1 0');
		WaypointSprite_Ping(self.sprite);

		return;
	}

	if (self.cnt == FLAG_DROPPED)
	{
		self.flags = FL_ITEM; // clear FL_ONGROUND and any other junk
		if (other.team == self.team || (other.team != COLOR_TEAM1 && other.team != COLOR_TEAM2))
		{
			// return flag
			bprint(other.netname, "^7 returned the ", self.netname, "\n");

			// punish the player who last had it
			FOR_EACH_PLAYER(player)
				if(player.playerid == self.dropperid)
				{
					score_player_add(player, SP_SCORE, -CTF_SCORE_VALUE(penalty_returned));
					ctf_captureshield_update(player, 0); // shield only
				}

			// punish the team who was last carrying it
			if(self.team == COLOR_TEAM1)
				score_team_add_to(COLOR_TEAM2, ST_SCORE, -CTF_SCORE_VALUE(penalty_returned));
			else
				score_team_add_to(COLOR_TEAM1, ST_SCORE, -CTF_SCORE_VALUE(penalty_returned));

			// reward the player who returned it
			if(other.playerid == self.playerid) // is this the guy who killed the FC last?
			{
				if (other.team == COLOR_TEAM1 || other.team == COLOR_TEAM2)
					score_player_team_add_score(other, CTF_SCORE_VALUE(score_return_by_killer));
				else
					score_player_team_add_score(other, CTF_SCORE_VALUE(score_return_rogue_by_killer));
			}
			else
			{
				if (other.team == COLOR_TEAM1 || other.team == COLOR_TEAM2)
					score_player_team_add_score(other, CTF_SCORE_VALUE(score_return));
				else
					score_player_team_add_score(other, CTF_SCORE_VALUE(score_return_rogue));
			}
			score_player_add(other, SP_CTF_RETURNS, 1);
			GameStatus_Set(strcat(team_color_code(self.team), team_color_name(self.team), " Flag^7 returned"), 1);
			sound (other, CHAN_AUTO, self.noise1, VOL_BASE, ATTN_NONE);
			ctf_flag_return(self);
		}
		else if (!other.flagcarried && (other.playerid != self.dropperid || time > self.ctf_droptime + g_ctf_delay_collect))
		{
			if (g_ctf_flag_pickup_effects) // field pickup effect
				pointparticles(particleeffectnum("smoke_ring"), 0.5 * (self.absmin + self.absmax), '0 0 0', 1);
			
			// pick up
			self.solid = SOLID_NOT;
			setorigin(self, self.origin); // relink
			self.owner = other;
			other.flagcarried = self;
			self.cnt = FLAG_CARRY;
			bprint(other.netname, "^7 picked up the ", self.netname, "\n");

			float f;
			f = bound(0, (self.pain_finished - time) / g_ctf_flag_returntime, 1);
			//print("factor is ", ftos(f), "\n");
			f = CTF_SCORE_VALUE(score_pickup_dropped_late) * (1-f)
			  + CTF_SCORE_VALUE(score_pickup_dropped_early) * f;
			f = floor(f + 0.5);
			self.dropperid = other.playerid;
			//print("score is ", ftos(f), "\n");

			score_player_team_add_score(other, f);
			score_player_add(other, SP_CTF_PICKUPS, 1);
			GameStatus_Set(strcat(team_color_code(self.team), team_color_name(self.team), " Flag^7 taken"), 1);
			centerprint(other, "You have the flag!");
			sound (other, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NONE);

			FOR_EACH_PLAYER(player)
				if(player.team == self.team)
					centerprint(player, "The enemy got your flag! Retrieve it!");

			self.movetype = MOVETYPE_NONE;	// flag must have MOVETYPE_NONE here, otherwise it will drop through the floor...
			setorigin(self, FLAG_CARRY_POS);
			setattachment(self, other.body, "");
			self.damageforcescale = 0;
			self.takedamage = DAMAGE_NO;
			WaypointSprite_AttachCarrier("flagcarrier", other);
			WaypointSprite_UpdateRule(other.waypointsprite_attachedforcarrier, other.team, SPRITERULE_TEAMPLAY);
			WaypointSprite_UpdateSprites(other.waypointsprite_attachedforcarrier, "flagcarrier", "flagcarrier", "flagcarrier");
			other.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = ctf_flagcarrier_visible;
			WaypointSprite_UpdateTeamRadar(other.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '1 1 0');
		}
	}
}

void() ctf_flag_reset {
	ctf_flag_drop(self, world, world);
	ctf_flag_return(self);
}

void() ctf_flag_postspawn { // Check CTF Item Flag Post Spawn

	// Flag Glow Trail Support
	if(cvar("g_ctf_flag_glowtrails"))
	{ // Provide Flag Glow Trail
		if(self.team == COLOR_TEAM1)
			// Red
			self.glow_color = 251;
		else
		if(self.team == COLOR_TEAM2)
			// Blue
			self.glow_color = 210;
			
		self.glow_size = 25;
		self.glow_trail = 1;
	}
}

float() ctf_runhere_visibility {
	if (other.flagcarried)
	if (other.team == self.owner.team)
	if (self.owner.cnt == FLAG_BASE)
		return TRUE;

	return FALSE;
}

float() ctf_base_visibility {
	return !ctf_runhere_visibility();
}

float() ctf_flag_visibility {
	if (self.owner.cnt == FLAG_DROPPED)
		return TRUE;

	return FALSE;
}

/*QUAKED spawnfunc_ctf_flag_team1 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag for team one (Red).
Multiple are allowed.

Keys:
"angle"
 Angle the flag will point
(minus 90 degrees)
"model"
 model to use, note this needs red and blue as skins 0 and 1
 (default models/ctf/flag.md3)
"noise"
 sound played when flag is picked up
 (default ctf/take.wav)
"noise1"
 sound played when flag is returned by a teammate
 (default ctf/return.wav)
"noise2"
 sound played when flag is captured
 (default ctf/redcapture.wav)
"noise3"
 sound played when flag is lost in the field and respawns itself
 (default ctf/respawn.wav)
*/
void() spawnfunc_ctf_flag_team1 {
	if (!g_ctf)
	{
		remove(self);
		return;
	}

	// link flag into ctf_worldflaglist
	self.ctf_worldflagnext = ctf_worldflaglist;
	ctf_worldflaglist = self;

	self.classname = "ctf_flag_team";
	if(g_ctf_reverse)
	{
		self.team = COLOR_TEAM2; // color 13 team (blue)
		self.items = IT_KEY1; // silver key (bluish enough)
	}
	else
	{
		self.team = COLOR_TEAM1; // color 4 team (red)
		self.items = IT_KEY2; // gold key (redish enough)
	}
	self.netname = "^1RED^7 flag";
	self.message2 = "###item###";
	self.skin = cvar("g_ctf_flag_red_skin");
	if(self.spawnflags & 1)
		self.noalign = 1;
	if (!self.model)
		self.model = cvar_string("g_ctf_flag_red_model");
	if (!self.noise)
		self.noise = "ctf/red_taken.wav";
	if (!self.noise1)
		self.noise1 = "ctf/red_returned.wav";
	if (!self.noise2)
		self.noise2 = "ctf/red_capture.wav"; // blue team scores by capturing the red flag
	if (!self.noise3)
		self.noise3 = "ctf/flag_respawn.wav";
	if (!self.noise4)
		self.noise4 = "ctf/red_dropped.wav";
	precache_model (self.model);
	setmodel (self, self.model); // precision set below
	precache_sound (self.noise);
	precache_sound (self.noise1);
	precache_sound (self.noise2);
	precache_sound (self.noise3);
	precache_sound (self.noise4);
	//setsize(self, '-16 -16 -37', '16 16 37');
	setsize(self, FLAG_MIN, FLAG_MAX);
	setorigin(self, self.origin + '0 0 37');
	self.nextthink = time + 0.2; // start after doors etc
	self.think = ctf_flag_place;

	if(!self.scale)
		self.scale = 0.6;
	//if(!self.glow_size)
	//	self.glow_size = 50;

	self.effects = self.effects | EF_LOWPRECISION;
	if(cvar("g_ctf_fullbrightflags"))
		self.effects |= EF_FULLBRIGHT;
	if(cvar("g_ctf_dynamiclights"))
		self.effects |= EF_RED;

	// From Spidflisk
	ctf_flag_postspawn();

	waypoint_spawnforitem_force(self, self.origin);
	self.nearestwaypointtimeout = 0; // activate waypointing again
	self.basewaypoint = self.nearestwaypoint;

	WaypointSprite_SpawnFixed("redbase", self.origin + '0 0 37', self, sprite);
	self.sprite.waypointsprite_visible_for_player = ctf_base_visibility;
	WaypointSprite_SpawnFixed("keycarrier-finish", self.origin + '0 0 37', self, waypointsprite_deployed_fixed);
	self.waypointsprite_deployed_fixed.waypointsprite_visible_for_player = ctf_runhere_visibility;
	WaypointSprite_Spawn("flagdropped", 0, 0, self, '0 0 50', world, 0, self, waypointsprite_attached, FALSE);
	self.waypointsprite_attached.waypointsprite_visible_for_player = ctf_flag_visibility;
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_FLAG, colormap_palette_color(COLOR_TEAM1 - 1, FALSE));

	precache_model("models/ctf/shield.md3");
	precache_model("models/ctf/shockwavetransring.md3");

	self.reset = ctf_flag_reset;
}

/*QUAKED spawnfunc_ctf_flag_team2 (0 0.5 0.8) (-48 -48 -24) (48 48 64)
CTF flag for team two (Blue).
Multiple are allowed.

Keys:
"angle"
 Angle the flag will point
(minus 90 degrees)
"model"
 model to use, note this needs red and blue as skins 0 and 1
 (default models/ctf/flag.md3)
"noise"
 sound played when flag is picked up
 (default ctf/take.wav)
"noise1"
 sound played when flag is returned by a teammate
 (default ctf/return.wav)
"noise2"
 sound played when flag is captured
 (default ctf/bluecapture.wav)
"noise3"
 sound played when flag is lost in the field and respawns itself
 (default ctf/respawn.wav)
*/
void() spawnfunc_ctf_flag_team2 {
	if (!g_ctf)
	{
		remove(self);
		return;
	}

	// link flag into ctf_worldflaglist
	self.ctf_worldflagnext = ctf_worldflaglist;
	ctf_worldflaglist = self;

	self.classname = "ctf_flag_team";
	if(g_ctf_reverse)
	{
		self.team = COLOR_TEAM1; // color 4 team (red)
		self.items = IT_KEY2; // gold key (redish enough)
	}
	else
	{
		self.team = COLOR_TEAM2; // color 13 team (blue)
		self.items = IT_KEY1; // silver key (bluish enough)
	}
	self.netname = "^4BLUE^7 flag";
	self.message2 = "###item###";
	self.skin = cvar("g_ctf_flag_blue_skin");
	if(self.spawnflags & 1)
		self.noalign = 1;
	if (!self.model)
		self.model = cvar_string("g_ctf_flag_blue_model");
	if (!self.noise)
		self.noise = "ctf/blue_taken.wav";
	if (!self.noise1)
		self.noise1 = "ctf/blue_returned.wav";
	if (!self.noise2)
		self.noise2 = "ctf/blue_capture.wav"; // blue team scores by capturing the red flag
	if (!self.noise3)
		self.noise3 = "ctf/flag_respawn.wav";
	if (!self.noise4)
		self.noise4 = "ctf/blue_dropped.wav";
	precache_model (self.model);
	setmodel (self, self.model); // precision set below
	precache_sound (self.noise);
	precache_sound (self.noise1);
	precache_sound (self.noise2);
	precache_sound (self.noise3);
	precache_sound (self.noise4);
	//setsize(self, '-16 -16 -37', '16 16 37');
	setsize(self, FLAG_MIN, FLAG_MAX);
	setorigin(self, self.origin + '0 0 37');
	self.nextthink = time + 0.2; // start after doors etc
	self.think = ctf_flag_place;

	if(!self.scale)
		self.scale = 0.6;
	//if(!self.glow_size)
	//	self.glow_size = 50;

	self.effects = self.effects | EF_LOWPRECISION;
	if(cvar("g_ctf_fullbrightflags"))
		self.effects |= EF_FULLBRIGHT;
	if(cvar("g_ctf_dynamiclights"))
		self.effects |= EF_BLUE;

	// From Spidflisk
	ctf_flag_postspawn();

	waypoint_spawnforitem_force(self, self.origin);
	self.nearestwaypointtimeout = 0; // activate waypointing again
	self.basewaypoint = self.nearestwaypoint;

	WaypointSprite_SpawnFixed("bluebase", self.origin + '0 0 37', self, sprite);
	self.sprite.waypointsprite_visible_for_player = ctf_base_visibility;
	WaypointSprite_SpawnFixed("keycarrier-finish", self.origin + '0 0 37', self, waypointsprite_deployed_fixed);
	self.waypointsprite_deployed_fixed.waypointsprite_visible_for_player = ctf_runhere_visibility;
	WaypointSprite_Spawn("flagdropped", 0, 0, self, '0 0 50', world, 0, self, waypointsprite_attached, FALSE);
	self.waypointsprite_attached.waypointsprite_visible_for_player = ctf_flag_visibility;
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_FLAG, colormap_palette_color(COLOR_TEAM2 - 1, FALSE));

	precache_model("models/ctf/shield.md3");

	self.reset = ctf_flag_reset;
}

/*QUAKED spawnfunc_ctf_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for CTF gameplay, this allows you to decide what team
names and control point models are used in your map.

Note: If you use spawnfunc_ctf_team entities you must define at least 2!  However, unlike
domination, you don't need to make a blank one too.

Keys:
"netname"
 Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)
"cnt"
 Scoreboard color of the team (for example 4 is red and 13 is blue)

*/

void() spawnfunc_ctf_team {
	if (!g_ctf) {
		remove(self);
		return;
	}
	self.classname = "ctf_team";
	self.team = self.cnt + 1;
	team_teams_set_allowed(self.team);
}

// code from here on is just to support maps that don't have control point and team entities
void(string teamname, float teamcolor) ctf_spawnteam {
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "ctf_team";
	self.netname = teamname;
	self.cnt = teamcolor;
	spawnfunc_ctf_team();
	self = oldself;
}

// spawn some default teams if the map is not set up for ctf
void() ctf_spawnteams {
	float numteams;
	numteams = 2;//cvar("g_ctf_default_teams");
	ctf_spawnteam("Red", COLOR_TEAM1 - 1);
	ctf_spawnteam("Blue", COLOR_TEAM2 - 1);
}

void() ctf_delayedinit {
	CVAR_CACHE(g_ctf_damageforcescale);
	CVAR_CACHE(g_ctf_delay_collect);
	CVAR_CACHE(g_ctf_allow_drop);
	CVAR_CACHE(g_ctf_captimerecord_always);
	CVAR_CACHE(g_ctf_default_teams);
	CVAR_CACHE(g_ctf_flag_capture_effects);
	CVAR_CACHE(g_ctf_flag_pickup_effects);
	CVAR_CACHE(g_ctf_flag_returntime);
	CVAR_CACHE(g_ctf_personalpenalty_drop);
	CVAR_CACHE(g_ctf_personalpenalty_returned);
	CVAR_CACHE(g_ctf_personalpenalty_suicidedrop);
	CVAR_CACHE(g_ctf_personalscore_capture);
	CVAR_CACHE(g_ctf_personalscore_pickup_base);
	CVAR_CACHE(g_ctf_personalscore_pickup_dropped_early);
	CVAR_CACHE(g_ctf_personalscore_pickup_dropped_late);
	CVAR_CACHE(g_ctf_personalscore_return);
	CVAR_CACHE(g_ctf_personalscore_return_by_killer);
	CVAR_CACHE(g_ctf_personalscore_return_rogue);
	CVAR_CACHE(g_ctf_personalscore_return_rogue_by_killer);
	CVAR_CACHE(g_ctf_flagpenalty_drop);
	CVAR_CACHE(g_ctf_flagpenalty_returned);
	CVAR_CACHE(g_ctf_flagpenalty_suicidedrop);
	CVAR_CACHE(g_ctf_flagscore_capture);
	CVAR_CACHE(g_ctf_flagscore_pickup_base);
	CVAR_CACHE(g_ctf_flagscore_pickup_dropped_early);
	CVAR_CACHE(g_ctf_flagscore_pickup_dropped_late);
	CVAR_CACHE(g_ctf_flagscore_return);
	CVAR_CACHE(g_ctf_flagscore_return_by_killer);
	CVAR_CACHE(g_ctf_flagscore_return_rogue);
	CVAR_CACHE(g_ctf_flagscore_return_rogue_by_killer);
	CVAR_CACHE(g_ctf_ignore_frags);
	CVAR_CACHE(g_ctf_flagcarrier_selfdamage);
	CVAR_CACHE(g_ctf_flagcarrier_selfforce);
	CVAR_CACHE(g_ctf_flagscore_kill);
	CVAR_CACHE(g_ctf_personalscore_kill);
	CVAR_CACHE(g_ctf_showenemycarrier);
	CVAR_CACHE(g_ctf_showenemycarrier_delay);
	// if no teams are found, spawn defaults
	if (find(world, classname, "ctf_team") == world)
		ctf_spawnteams();

	float sp_score, sp_caps;
	sp_score = sp_caps = 0;
	switch(g_ctf_win_mode)
	{
		case 0: // caps only
			sp_caps = SFL_SORT_PRIO_PRIMARY;
			break;
		case 1: // caps, then score
			sp_caps = SFL_SORT_PRIO_PRIMARY;
			sp_score = SFL_SORT_PRIO_SECONDARY;
			break;
		case 2: // score only
		default:
			sp_caps = SFL_SORT_PRIO_SECONDARY; // looks better ;)
			sp_score = SFL_SORT_PRIO_PRIMARY;
			break;
	}
	score_basics(SFL_SORT_PRIO_PRIMARY, sp_score, TRUE); // NOTE this assumes that the rogue team is team 3
	ST_CTF_CAPS = score_register_team_score("caps", sp_caps);
	SP_CTF_CAPS = score_register("caps", SFL_SORT_PRIO_SECONDARY);
	SP_CTF_PICKUPS = score_register("pickups", 0);
	SP_CTF_FCKILLS = score_register("fckills", 0);
	SP_CTF_RETURNS = score_register("returns", 0);
	SP_CTF_DROPS = score_register("drops", SFL_LOWER_IS_BETTER);
	if (game == GAME_CATF) {
		Clanarena_Init_Shared("catf");
		Roundbased_SetScoreField(ST_CTF_CAPS);
	} else if (game == GAME_CTFT) {
		Freeze_Init_Shared("ctft");
		Roundbased_SetScoreField(ST_CTF_CAPS);
	}
}

var void(float killed) ctf_PlayerClear_NextLink;
void(float killed) ctf_PlayerClear {
	if(self.flagcarried)
		ctf_flag_drop(self.flagcarried, world, world);

	ctf_PlayerClear_NextLink(killed);
}

float(entity attacker, entity inflictor, float deathtype) ctf_DeathHandle {
	if (self.flagcarried) {
		if(attacker.classname != "player")
			ctf_flag_drop(self.flagcarried, self, attacker); // penalty for flag loss by suicide
		else if(attacker.team == self.team)
			ctf_flag_drop(self.flagcarried, attacker, attacker); // penalty for flag loss by suicide/teamkill
	}
	return FALSE;
}

string(string bspname) ctf_RecordForMap {
	float r = stof(db_get(db_server, strcat(bspname, "/captimerecord/time")));
	if (r == 0)
		return "";

	return strcat(strpad(32, bspname), " ", strpad(-6, str_float_decimals(r, 2)), " ", db_get(db_server, strcat(bspname, "/captimerecord/netname")), "\n");
}

var void(entity targ, entity attacker, float deathtype) ctf_DamageForceModsSet_NextLink;
void(entity targ, entity attacker, float deathtype) ctf_DamageForceModsSet {
	if(targ == attacker)
	if(targ.flagcarried) {
		gamehook_chain_damage_mod_force *= g_ctf_flagcarrier_selfforce;
		gamehook_chain_damage_mod *= g_ctf_flagcarrier_selfdamage;
	}

	ctf_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

float(entity plr) ctf_PlayerIsCarrier { return plr.flagcarried != world; }
void(entity plr) ctf_DropCarried { ctf_flag_drop(plr.flagcarried, world, world); }
float(entity e) ctf_TeleportationForbiddenFor { return e.classname == "ctf_flag_team"; }

void() ctf_init {
	CVAR_CACHE(g_ctf_reverse);
	g_ctf = 1;
	if (game == GAME_CATF || game == GAME_CTFT)
		g_ctf_win_mode = 0;
	else
		g_ctf_win_mode = cvar("g_ctf_win_mode");

	entity_initialize(world, ctf_delayedinit, INITPRIO_GAMETYPE);
	flagcaptimerecord = stof(db_get(db_server, strcat(mapname, "/captimerecord/time")));
	captureshield_min_negscore = cvar("g_ctf_shield_min_negscore");
	captureshield_max_ratio = cvar("g_ctf_shield_max_ratio");
	captureshield_force = cvar("g_ctf_shield_force");
	gamehook_FragsHandle = ctf_handle_frags;
	ctf_PlayerClear_NextLink = gamehook_chain_player_clear;
	gamehook_chain_player_clear = ctf_PlayerClear;
	ctf_PlayerPreThink_NextLink = gamehook_chain_player_think;
	gamehook_chain_player_think = ctf_PlayerPreThink;
	gamehook_WinCountDown = stub_WinCountDown;
	gamehook_RecordForMap = ctf_RecordForMap;
	ctf_DamageForceModsSet_NextLink = gamehook_chain_damage_mods_set;
	gamehook_chain_damage_mods_set = ctf_DamageForceModsSet;
	gamehook_PlayerIsCarrier = ctf_PlayerIsCarrier;
	gamehook_DropCarried = ctf_DropCarried;
	gamehook_TeleportationForbiddenFor = ctf_TeleportationForbiddenFor;
	gamehook_BotChooseRole = ctf_role_choose;
}

void(entity flag, float shift) ctf_setstatus2 {
	if (flag.cnt ==	FLAG_CARRY)
		if (flag.owner == self)
			self.items |= shift * 3;
		else
			self.items |= shift * 1;
	else if (flag.cnt == FLAG_DROPPED)
		self.items |= shift * 2;
	else
	{
		// no status bits
	}
}

void() ctf_PlayerPreThink {
	self.items &~= IT_RED_FLAG_TAKEN;
	self.items &~= IT_RED_FLAG_LOST;
	self.items &~= IT_BLUE_FLAG_TAKEN;
	self.items &~= IT_BLUE_FLAG_LOST;
	self.items &~= IT_CTF_SHIELDED;

	entity flag;
	float redflags, blueflags;

	if(self.ctf_captureshielded)
		self.items |= IT_CTF_SHIELDED;

	redflags = 0;
	blueflags = 0;

	for (flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext) if(flag.cnt != FLAG_BASE)
	{
		if(flag.items & IT_KEY2) // blue
			++redflags;
		else if(flag.items & IT_KEY1) // red
			++blueflags;
	}

	// blinking magic: if there is more than one flag, show one of these in a clever way
	if(redflags)
		redflags = math_mod(floor(time * redflags * 0.75), redflags);
	if(blueflags)
		blueflags = math_mod(floor(time * blueflags * 0.75), blueflags);

	for (flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext) if(flag.cnt != FLAG_BASE)
	{
		if(flag.items & IT_KEY2) // blue
		{
			if(--redflags == -1) // happens exactly once (redflags is in 0..count-1, and will --'ed count times)
				ctf_setstatus2(flag, IT_RED_FLAG_TAKEN);
		}
		else if(flag.items & IT_KEY1) // red
		{
			if(--blueflags == -1) // happens exactly once
				ctf_setstatus2(flag, IT_BLUE_FLAG_TAKEN);
		}
	}
	ctf_PlayerPreThink_NextLink();
}
