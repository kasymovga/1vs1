#define MAX_CHECKPOINTS 255

.float race_penalty_accumulator;
.string race_penalty_reason;
.float race_checkpoint; // player: next checkpoint that has to be reached
.float race_laptime;
.entity race_lastpenalty;
.float race_penalty;
.float race_movetime; // for reading
.float race_movetime_frac; // fractional accumulator for higher accuracy (helper for writing)
.float race_movetime_count; // integer accumulator

float g_race_qualifying;

float race_fraglimit;
float race_leadlimit;
float race_timelimit;

.entity sprite;

float race_checkpoint_records[MAX_CHECKPOINTS];
string race_checkpoint_recordholders[MAX_CHECKPOINTS];
float race_checkpoint_lasttimes[MAX_CHECKPOINTS];
float race_checkpoint_lastlaps[MAX_CHECKPOINTS];
entity race_checkpoint_lastplayers[MAX_CHECKPOINTS];
float race_spawns;
float race_highest_place_spawn; // number of places; a place higher gets spawned at 0
float race_lowest_place_spawn; // where to spawn in qualifying
.float race_place;
void race_ImposePenaltyTime(entity pl, float penalty, string reason);
void race_StartCompleting();

float race_highest_checkpoint;
float race_timed_checkpoint;

void race_ClearTime(entity e);

#define ST_RACE_LAPS ST_GAME_SCORE1
#define SP_RACE_LAPS SP_GAME_SCORE1
#define SP_RACE_FASTEST SP_GAME_SCORE2
#define SP_RACE_TIME SP_GAME_SCORE3
void ScoreRules_race()
{
	ScoreRules_basics(race_teams, 0, 0, FALSE);
	if(race_teams)
	{
		ScoreInfo_SetLabel_TeamScore(  ST_RACE_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_TIME,    "time",      SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	else if(g_race_qualifying)
	{
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_FASTEST, "fastest",   SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	else
	{
		//ScoreInfo_SetLabel_TeamScore(  ST_RACE_LAPS,    "laps",      0);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_TIME,    "time",      SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
	}
}

float race_NextCheckpoint(float f)
{
	if(f >= race_highest_checkpoint)
		return 0;
	else
		return f + 1;
}

float race_PreviousCheckpoint(float f)
{
	if(f == -1)
		return 0;
	else if(f == 0)
		return race_highest_checkpoint;
	else
		return f - 1;
}

// encode as:
//   0 = common start/finish
// 254 = start
// 255 = finish
float race_CheckpointNetworkID(float f)
{
	if(race_timed_checkpoint)
	{
		if(f == 0)
			return 254; // start
		else if(f == race_timed_checkpoint)
			return 255; // finish
	}
	return f;
}

void race_SendNextCheckpoint(entity e, float spec) // qualifying only
{
	float recordtime;
	string recordholder;
	float cp;

	if(!e.race_laptime)
		return;

	cp = e.race_checkpoint;
	recordtime = race_checkpoint_records[cp];
	recordholder = race_checkpoint_recordholders[cp];
	if(recordholder == e.netname)
		recordholder = "";

	if(!spec)
		msg_entity = e;
	WRITESPECTATABLE_MSG_ONE({
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_RACE);
		if(spec)
		{
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING);
			//WriteCoord(MSG_ONE, e.race_laptime - e.race_penalty_accumulator);
			WriteCoord(MSG_ONE, time - e.race_movetime - e.race_penalty_accumulator);
		}
		else
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_NEXT_QUALIFYING);
		WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player will be at next
		WriteInt24_t(MSG_ONE, recordtime);
		WriteString(MSG_ONE, recordholder);
	});
}

void race_InitSpectator()
{
	if(g_race_qualifying) {
		if(self.enemy.race_laptime)
			race_SendNextCheckpoint(self.enemy, 1);
		else
			race_ClearTime(self);
	}
}

void race_SendTime(entity e, float cp, float t, float tvalid)
{
	float snew, l;
	entity p;

	if(g_race_qualifying)
		t += e.race_penalty_accumulator;

	t = TIME_ENCODE(t); // make integer
	// adding just 0.4 so it rounds down in the .5 case (matching the timer display)

	if(tvalid)
	if(cp == race_timed_checkpoint) // finish line
	if not(e.race_completed)
	{
		float s;
		if(g_race_qualifying)
		{
			s = PlayerScore_Add(e, SP_RACE_FASTEST, 0);
			if(!s || t < s)
				PlayerScore_Add(e, SP_RACE_FASTEST, t - s);
		}
		else
		{
			s = PlayerScore_Add(e, SP_RACE_TIME, 0);
			snew = TIME_ENCODE(time - game_starttime);
			PlayerScore_Add(e, SP_RACE_TIME, snew - s);
			l = PlayerTeamScore_Add(e, SP_RACE_LAPS, ST_RACE_LAPS, 1);

			if(cvar("fraglimit"))
				if(l >= cvar("fraglimit"))
					race_StartCompleting();

			if(race_completing)
			{
				e.race_completed = 1;
				MAKE_INDEPENDENT_PLAYER(e);
				bprint(e.netname, "^7 has finished the race.\n");
			}
		}
	}

	float recordtime;
	string recordholder;

	if(g_race_qualifying)
	{
		if(tvalid)
		{
			recordtime = race_checkpoint_records[cp];
			recordholder = strcat1(race_checkpoint_recordholders[cp]); // make a tempstring copy, as we'll possibly strunzone it!
			if(recordholder == e.netname)
				recordholder = "";

			if(t != 0)
			if(t < recordtime || recordtime == 0)
			{
				race_checkpoint_records[cp] = t;
				if(race_checkpoint_recordholders[cp])
					strunzone(race_checkpoint_recordholders[cp]);
				race_checkpoint_recordholders[cp] = strzone(e.netname);
				if(cp == race_timed_checkpoint)
				{
					float grecordtime;
					string grecordholder;
					string rr;
					if(g_cts)
						rr = CTS_RECORD;
					else
						rr = RACE_RECORD;
					grecordtime = stof(db_get(ServerProgsDB, strcat(GetMapname(), rr, "time")));
					grecordholder = db_get(ServerProgsDB, strcat(GetMapname(), rr, "netname"));
					if(grecordholder == e.netname)
						grecordholder = "";
					if(grecordtime == 0)
					{
						bprint(e.netname, "^7 set the all-time fastest lap record with ", TIME_ENCODED_TOSTRING(t), "\n");
						db_put(ServerProgsDB, strcat(GetMapname(), rr, "time"), ftos(t));
						db_put(ServerProgsDB, strcat(GetMapname(), rr, "netname"), e.netname);
						write_recordmarker(e, time - TIME_DECODE(t), TIME_DECODE(t));
					}
					else if(t < grecordtime)
					{
						if(grecordholder == "")
							bprint(e.netname, "^7 broke his all-time fastest lap record with ", TIME_ENCODED_TOSTRING(t), "\n");
						else
							bprint(e.netname, "^7 broke ", grecordholder, "^7's all-time fastest lap record with ", TIME_ENCODED_TOSTRING(t), "\n");
						db_put(ServerProgsDB, strcat(GetMapname(), rr, "time"), ftos(t));
						db_put(ServerProgsDB, strcat(GetMapname(), rr, "netname"), e.netname);
						write_recordmarker(e, time - TIME_DECODE(t), TIME_DECODE(t));
					}
					else
					{
						if(grecordholder == "")
							bprint(e.netname, "^7's new fastest lap could not break his all-time fastest lap record of ", TIME_ENCODED_TOSTRING(grecordtime), "\n");
						else
							bprint(e.netname, "^7's new fastest lap could not break ", grecordholder, "^7's all-time fastest lap record of ", TIME_ENCODED_TOSTRING(grecordtime), "\n");
					}
				}

				if(g_race_qualifying)
				{
					FOR_EACH_REALPLAYER(p)
						if(p.race_checkpoint == cp)
							race_SendNextCheckpoint(p, 0);
				}
			}
		}
		else
		{
			// dummies
			t = 0;
			recordtime = 0;
			recordholder = "";
		}

		msg_entity = e;
		if(g_race_qualifying)
		{
			WRITESPECTATABLE_MSG_ONE_VARNAME(dummy1, {
				WriteByte(MSG_ONE, SVC_TEMPENTITY);
				WriteByte(MSG_ONE, TE_CSQC_RACE);
				WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_QUALIFYING);
				WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player now is at
				WriteInt24_t(MSG_ONE, t); // time to that intermediate
				WriteInt24_t(MSG_ONE, recordtime); // previously best time
				WriteString(MSG_ONE, recordholder); // record holder
			});
		}
	}
	else // RACE! Not Qualifying
	{
		float lself, lother, othtime;
		entity oth;
		oth = race_checkpoint_lastplayers[cp];
		if(oth)
		{
			lself = PlayerScore_Add(e, SP_RACE_LAPS, 0);
			lother = race_checkpoint_lastlaps[cp];
			othtime = race_checkpoint_lasttimes[cp];
		}
		else
			lself = lother = othtime = 0;

		msg_entity = e;
		WRITESPECTATABLE_MSG_ONE_VARNAME(dummy2, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_RACE);
			WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player now is at
			if(e == oth)
			{
				WriteInt24_t(MSG_ONE, 0);
				WriteByte(MSG_ONE, 0);
				WriteString(MSG_ONE, "");
			}
			else
			{
				WriteInt24_t(MSG_ONE, TIME_ENCODE(time - race_checkpoint_lasttimes[cp]));
				WriteByte(MSG_ONE, lself - lother);
				WriteString(MSG_ONE, oth.netname); // record holder
			}
		});

		race_checkpoint_lastplayers[cp] = e;
		race_checkpoint_lasttimes[cp] = time;
		race_checkpoint_lastlaps[cp] = lself;

		msg_entity = oth;
		WRITESPECTATABLE_MSG_ONE_VARNAME(dummy3, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT);
			WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player now is at
			if(e == oth)
			{
				WriteInt24_t(MSG_ONE, 0);
				WriteByte(MSG_ONE, 0);
				WriteString(MSG_ONE, "");
			}
			else
			{
				WriteInt24_t(MSG_ONE, TIME_ENCODE(time - othtime));
				WriteByte(MSG_ONE, lother - lself);
				WriteString(MSG_ONE, e.netname); // record holder
			}
		});
	}
}

void race_ClearTime(entity e)
{
	e.race_checkpoint = -1;
	e.race_laptime = 0;
	e.race_movetime = e.race_movetime_frac = e.race_movetime_count = 0;
	e.race_penalty_accumulator = 0;
	e.race_lastpenalty = world;

	msg_entity = e;
	WRITESPECTATABLE_MSG_ONE({
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_RACE);
		WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_CLEAR); // next
	});
}

void dumpsurface(entity e)
{
	float n, si, ni;
	vector norm, vec;
	print("Surfaces of ", etos(e), ":\n");

	print("TEST = ", ftos(getsurfacenearpoint(e, '0 0 0')), "\n");

	for(si = 0; ; ++si)
	{
		n = getsurfacenumpoints(e, si);
		if(n <= 0)
			break;
		print("  Surface ", ftos(si), ":\n");
		norm = getsurfacenormal(e, si);
		print("    Normal = ", vtos(norm), "\n");
		for(ni = 0; ni < n; ++ni)
		{
			vec = getsurfacepoint(e, si, ni);
			print("    Point ", ftos(ni), " = ", vtos(vec), " (", ftos(norm * vec), ")\n");
		}
	}
}

void checkpoint_passed()
{
	string oldmsg;

	if(other.classname == "porto")
	{
		// do not allow portalling through checkpoints
		trace_plane_normal = normalize(-1 * other.velocity);
		self = other;
		W_Porto_Fail();
		return;
	}

	/*
	 * Trigger targets
	 */
	if not(self.spawnflags & 2)
	{
		activator = other;
		oldmsg = self.message;
		self.message = "";
		SUB_UseTargets();
		self.message = oldmsg;
	}

	if(other.classname != "player")
		return;

	/*
	 * Remove unauthorized equipment
	 */
	Portal_ClearAll(other);

	other.porto_forbidden = 2; // decreased by 1 each StartFrame

	if(other.race_checkpoint == -1 || other.race_checkpoint == self.race_checkpoint)
	{
		if(self.race_penalty)
		{
			if(other.race_lastpenalty != self)
			{
				other.race_lastpenalty = self;
				race_ImposePenaltyTime(other, self.race_penalty, self.race_penalty_reason);
			}
		}

		if(other.race_penalty)
			return;

		/*
		 * Trigger targets
		 */
		if(self.spawnflags & 2)
		{
			activator = other;
			oldmsg = self.message;
			self.message = "";
			SUB_UseTargets();
			self.message = oldmsg;
		}

		other.race_checkpoint = race_NextCheckpoint(self.race_checkpoint);

		race_SendTime(other, self.race_checkpoint, other.race_movetime, !!other.race_laptime);

		if(!self.race_checkpoint) // start line
		{
			other.race_laptime = time;
			other.race_movetime = other.race_movetime_frac = other.race_movetime_count = 0;
			other.race_penalty_accumulator = 0;
			other.race_lastpenalty = world;
		}

		if(g_race_qualifying)
			race_SendNextCheckpoint(other, 0);
	}
	else if(other.race_checkpoint == race_NextCheckpoint(self.race_checkpoint))
	{
		// ignored
	}
	else
	{
		if(self.spawnflags & 4)
			Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
	}
}

void checkpoint_touch()
{
	EXACTTRIGGER_TOUCH;
	checkpoint_passed();
}

void checkpoint_use()
{
	if(other.classname == "info_player_deathmatch") // a spawn, a spawn
		return;

	other = activator;
	checkpoint_passed();
}

float race_waypointsprite_visible_for_player(entity e)
{
	if(e.race_checkpoint == -1)
		return TRUE;
	else if(e.race_checkpoint == self.owner.race_checkpoint)
		return TRUE;
	else
		return FALSE;
}

float have_verified;
void trigger_race_checkpoint_verify()
{
	entity oldself, cp;
	float i, p;
	float qual;

	if(have_verified)
		return;
	have_verified = 1;

	qual = g_race_qualifying;

	oldself = self;
	self = spawn();
	self.classname = "player";

	if(g_race)
	{
		for(i = 0; i <= race_highest_checkpoint; ++i)
		{
			self.race_checkpoint = race_NextCheckpoint(i);

			// race only (middle of the race)
			g_race_qualifying = 0;
			self.race_place = 0;
			if(!Spawn_FilterOutBadSpots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
				error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for respawning in race) - bailing out"));

			if(i == 0)
			{
				// qualifying only
				g_race_qualifying = 1;
				self.race_place = race_lowest_place_spawn;
				if(!Spawn_FilterOutBadSpots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
					error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for qualifying) - bailing out"));

				// race only (initial spawn)
				g_race_qualifying = 0;
				for(p = 1; p <= race_highest_place_spawn; ++p)
				{
					self.race_place = p;
					if(!Spawn_FilterOutBadSpots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
						error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for initially spawning in race) - bailing out"));
				}
			}
		}
	}
	else
	{
		// qualifying only
		self.race_checkpoint = race_NextCheckpoint(0);
		g_race_qualifying = 1;
		self.race_place = race_lowest_place_spawn;
		if(!Spawn_FilterOutBadSpots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
			error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for qualifying) - bailing out"));
	}

	g_race_qualifying = qual;

	if(race_timed_checkpoint)
		for(cp = world; (cp = find(cp, classname, "trigger_race_checkpoint")); )
			if(cp.sprite)
			{
				if(cp.race_checkpoint == 0)
					WaypointSprite_UpdateSprites(cp.sprite, "race-start", "", "");
				else if(cp.race_checkpoint == race_timed_checkpoint)
					WaypointSprite_UpdateSprites(cp.sprite, "race-finish", "", "");
			}

	remove(self);
	self = oldself;
}

void spawnfunc_trigger_race_checkpoint()
{
	vector o;
	if(!g_race && !g_cts)
	{
		remove(self);
		return;
	}

	EXACTTRIGGER_INIT;

	self.use = checkpoint_use;
	if not(self.spawnflags & 1)
		self.touch = checkpoint_touch;

	o = (self.absmin + self.absmax) * 0.5;
	tracebox(o, PL_MIN, PL_MAX, o - '0 0 1' * (o_z - self.absmin_z), MOVE_NORMAL, self);
	waypoint_spawnforitem_force(self, trace_endpos);
	self.nearestwaypointtimeout = time + 1000000000;

	if(!self.message)
		self.message = "went backwards";
	if (!self.message2)
		self.message2 = "was pushed backwards by";
	if (!self.race_penalty_reason)
		self.race_penalty_reason = "missing a checkpoint";

	self.race_checkpoint = self.cnt;

	if(self.race_checkpoint > race_highest_checkpoint)
	{
		race_highest_checkpoint = self.race_checkpoint;
		if(self.spawnflags & 8)
			race_timed_checkpoint = self.race_checkpoint;
		else
			race_timed_checkpoint = 0;
	}

	if(!self.race_penalty)
	{
		if(self.race_checkpoint)
			WaypointSprite_SpawnFixed("race-checkpoint", o, self, sprite);
		else
			WaypointSprite_SpawnFixed("race-finish", o, self, sprite);
	}

	self.sprite.waypointsprite_visible_for_player = race_waypointsprite_visible_for_player;

	InitializeEntity(self, trigger_race_checkpoint_verify, INITPRIO_FINDTARGET);
}

void race_AbandonRaceCheck(entity p)
{
	if(race_completing && !p.race_completed)
	{
		p.race_completed = 1;
		MAKE_INDEPENDENT_PLAYER(p);
		bprint(p.netname, "^7 has abandoned the race.\n");
	}
}

void race_StartCompleting()
{
	entity p;
	race_completing = 1;
	FOR_EACH_PLAYER(p)
		if(p.deadflag != DEAD_NO)
			race_AbandonRaceCheck(p);
}

void race_PreparePlayer()
{
	race_ClearTime(self);
	self.race_place = 0;
}

void race_RetractPlayer()
{
	if(!g_race && !g_cts)
		return;
	self.race_checkpoint = race_PreviousCheckpoint(self.race_checkpoint);
	if(self.race_checkpoint == 0)
	{
		race_ClearTime(self);
		self.race_checkpoint = 0;
	}
}

var void(float killed) race_PlayerClear_NextLink;
void race_PlayerClear(float killed)
{
	if (killed)
		race_AbandonRaceCheck(self);

	race_PlayerClear_NextLink(killed);
}

entity race_PreSpawn()
{
	if(self.killcount == -666 || g_race_qualifying)
		race_PreparePlayer();

	race_AbandonRaceCheck(self);
	return SelectSpawnPoint(FALSE);
}

var void(entity spot) race_Spawn_NextLink;
void race_Spawn(entity spot)
{
	if(self.killcount != -666 && !g_race_qualifying)
	{
		if(spot.target == "")
			// let the player run without timing, if he did not spawn at a targetting spawnpoint
			race_PreparePlayer();
		else
			race_RetractPlayer();
	}

	if(spot.target != "" && self.race_checkpoint == -1)
		self.race_checkpoint = 0;

	self.race_place = 0;
	race_Spawn_NextLink(spot);
}

var void() race_GameHookChain_ObserverSpawn_Next;

void race_PreSpawnObserver()
{
	race_PreparePlayer();
	race_GameHookChain_ObserverSpawn_Next();
}

void spawnfunc_info_player_race (void)
{
	if(!g_race && !g_cts)
	{
		remove(self);
		return;
	}
	++race_spawns;
	spawnfunc_info_player_deathmatch();

	if(self.race_place > race_highest_place_spawn)
		race_highest_place_spawn = self.race_place;
	if(self.race_place < race_lowest_place_spawn)
		race_lowest_place_spawn = self.race_place;
}

void race_ClearRecords()
{
	float i;
	entity e;

	for(i = 0; i < MAX_CHECKPOINTS; ++i)
	{
		race_checkpoint_records[i] = 0;
		if(race_checkpoint_recordholders[i])
			strunzone(race_checkpoint_recordholders[i]);
		race_checkpoint_recordholders[i] = string_null;
	}

	FOR_EACH_CLIENT(e)
		race_ClearTime(e);
}

void race_Reset()
{
	float s;

	Score_NicePrint(world);

	race_ClearRecords();
	PlayerScore_Sort(race_place);

	entity e;
	FOR_EACH_CLIENT(e)
	{
		if(e.race_place)
		{
			s = PlayerScore_Add(e, SP_RACE_FASTEST, 0);
			if(!s)
				e.race_place = 0;
		}
		print(e.netname, " = ", ftos(e.race_place), "\n");
	}

	if(g_race_qualifying == 2)
	{
		g_race_qualifying = 0;
		independent_players = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		ScoreRules_race();
	}
}

void race_ImposePenaltyTime(entity pl, float penalty, string reason)
{
	if(g_race_qualifying)
	{
		pl.race_penalty_accumulator += penalty;
		msg_entity = pl;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_PENALTY_QUALIFYING);
			WriteShort(MSG_ONE, TIME_ENCODE(penalty));
			WriteString(MSG_ONE, reason);
		});
	}
	else
	{
		pl.race_penalty = time + penalty;
		msg_entity = pl;
		WRITESPECTATABLE_MSG_ONE_VARNAME(dummy, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_PENALTY_RACE);
			WriteShort(MSG_ONE, TIME_ENCODE(penalty));
			WriteString(MSG_ONE, reason);
		});
	}
}

void penalty_touch()
{
	EXACTTRIGGER_TOUCH;
	if(other.race_lastpenalty != self)
	{
		other.race_lastpenalty = self;
		race_ImposePenaltyTime(other, self.race_penalty, self.race_penalty_reason);
	}
}

void penalty_use()
{
	race_ImposePenaltyTime(activator, self.race_penalty, self.race_penalty_reason);
}

void spawnfunc_trigger_race_penalty()
{
	EXACTTRIGGER_INIT;

	self.use = penalty_use;
	if not(self.spawnflags & 1)
		self.touch = penalty_touch;

	if (!self.race_penalty_reason)
		self.race_penalty_reason = "missing a checkpoint";
	if (!self.race_penalty)
		self.race_penalty = 5;
}

float race_PlayerAllowedToMove() {
	if(self.race_penalty)
		if(time > self.race_penalty)
			self.race_penalty = 0;

	if(self.race_penalty)
		return FALSE;

	return TRUE;
}

var float(entity plr, float wep) race_PlayerCanFire_NextLink;
float race_PlayerCanFire(entity plr, float wep) {
	if (time < plr.race_penalty)
		return FALSE;

	return race_PlayerCanFire_NextLink(plr, wep);
}

void race_PhysicFrameBegin() {
	vector wishvel;
	float wishspeed, f;
	// if record times matter
	// ensure nothing EVIL is being done (i.e. strafebot)
	// this hinders joystick users though
	// but it still gives SOME analog control
	// TODO implement this for engine cl_movement code too (basically, clipping to the four axes)
	wishvel_x = fabs(self.movement_x);
	wishvel_y = fabs(self.movement_y);
	if(wishvel_x != 0 && wishvel_y != 0 && wishvel_x != wishvel_y)
	{
		wishvel_z = 0;
		wishspeed = vlen(wishvel);
		if(wishvel_x >= 2 * wishvel_y)
		{
			// pure X motion
			if(self.movement_x > 0)
				self.movement_x = wishspeed;
			else
				self.movement_x = -wishspeed;
			self.movement_y = 0;
		}
		else if(wishvel_y >= 2 * wishvel_x)
		{
			// pure Y motion
			self.movement_x = 0;
			if(self.movement_y > 0)
				self.movement_y = wishspeed;
			else
				self.movement_y = -wishspeed;
		}
		else
		{
			// diagonal
			if(self.movement_x > 0)
				self.movement_x = 0.70710678118654752440 * wishspeed;
			else
				self.movement_x = -0.70710678118654752440 * wishspeed;
			if(self.movement_y > 0)
				self.movement_y = 0.70710678118654752440 * wishspeed;
			else
				self.movement_y = -0.70710678118654752440 * wishspeed;
		}
	}

	self.race_movetime_frac += frametime;
	f = floor(self.race_movetime_frac);
	self.race_movetime_frac -= f;
	self.race_movetime_count += f;
	self.race_movetime = self.race_movetime_frac + self.race_movetime_count;
}

float race_WinningCondition_NonQualifying(float fraglimit)
{
	entity p;
	float n, c;

	n = 0;
	c = 0;
	FOR_EACH_PLAYER(p)
	{
		++n;
		if(p.race_completed)
			++c;
	}
	if(n && (n == c))
		return TRUE;

	return WinningCondition_Scores(fraglimit, 0);
}

float race_WinningCondition(float fraglimit, float ignore) {
	if(!g_race_qualifying)
		return race_WinningCondition_NonQualifying(fraglimit);
	else if(g_race_qualifying == 2)
		return WinningCondition_Scores(fraglimit, 0);

	return FALSE;
}

float race_OvertimeHandle() {
	if (g_race_qualifying == 2) {
		float totalplayers;
		float playerswithlaps;
		float readyplayers;
		entity head;
		totalplayers = playerswithlaps = readyplayers = 0;
		FOR_EACH_PLAYER(head)
		{
			++totalplayers;
			if(PlayerScore_Add(head, SP_RACE_FASTEST, 0))
				++playerswithlaps;
			if(head.ready)
				++readyplayers;
		}

		// at least 2 of the players have completed a lap: start the RACE
		// otherwise, the players should end the qualifying on their own
		if(readyplayers || playerswithlaps >= 2)
		{
			checkrules_suddendeathend = 0;
			ReadyRestart(); // go to race
			return TRUE;
		}
	}
	if(!checkrules_suddendeathend)
	{
		checkrules_suddendeathend = time + 60 * cvar("timelimit_suddendeath");
		if(g_race && !g_race_qualifying)
			race_StartCompleting();
	}
	return TRUE;
}

float race_SpawnPointGood(entity spot) {
	if(race_spawns)
		if(spot.target == "")
			return FALSE;

	if(spot.target == "")
		return TRUE;

	local entity ent;
	float good, found;
	ent = find(world, targetname, spot.target);
	while(ent) {
		if(ent.classname == "trigger_race_checkpoint")
		{
			found = 1;
			if(self.classname == "player") // spectators may spawn everywhere
			{
				if(g_race_qualifying)
				{
					// spawn at first
					if(ent.race_checkpoint != 0)
						return FALSE;

					if(spot.race_place != race_lowest_place_spawn)
						return FALSE;
				}
				else
				{
					if(ent.race_checkpoint != race_PreviousCheckpoint(self.race_checkpoint))
						return FALSE;

					float pl;
					pl = self.race_place;
					if(pl > race_highest_place_spawn)
						pl = 0;
					if(spot.race_place != pl)
						return FALSE;
				}
			}
			good = 1;
		}
		ent = find(ent, targetname, spot.target);
	}
	if(found && !good)
		return FALSE;

	return TRUE;
}

var void(float remain_frags) race_WinCountDown_orig;

void race_WinCountDown(float remain_frags) {
	if (g_race)
	if not(g_race_qualifying)
		race_WinCountDown_orig(remain_frags);
}

float race_KillDelayMod(float f) {
	if (g_race_qualifying)
		return 0;

	return f;
}

string race_SuddenDeathMod(string s) {
	if (g_race_qualifying)
		return s;

	return "^3Everyone, finish your lap! The race is over!";
}

float race_WarmupAllowed() {
	if (g_race_qualifying == 2)
		return FALSE;

	return TRUE;
}

string race_FixClientCvars() {
	return "cl_cmd settemp cl_movecliptokeyboard 2";
}

string race_RecordForMap(string bspname) {
	string recid = (g_race ? RACE_RECORD : CTS_RECORD);
	float r = stof(db_get(ServerProgsDB, strcat(bspname, recid, "time")));
	if (r == 0)
		return "";

	return strcat(strpad(32, bspname), " ", strpad(-8, TIME_ENCODED_TOSTRING(r)), " ", db_get(ServerProgsDB, strcat(bspname, recid, "netname")), "\n");
}

float race_ReadyAllowed() {
	return (g_race_qualifying == 2);
}

float race_ClearScoresAllowed() {
	return g_race_qualifying;
}

float race_TelefragsAllowed() {
	return FALSE;
}

float race_ReadyRestartHard() { return race_completing; }

float race_FragLimitOverride() {
	if (g_race)
		return cvar("g_race_laps_limit");

	return 0;
}

float race_LeadLimitOverride() {
	return 0;
}

void race_init() {
	if (g_race) {
		float qualifying_override;
		qualifying_override = -1;
		if(cvar("g_race_teams"))
		{
			ActivateTeamplay();
			race_teams = bound(2, cvar("g_race_teams"), 4);
		}
		else
			race_teams = 0;

		qualifying_override = cvar("g_race_qualifying_timelimit_override");
		if(qualifying_override >= 0)
			cvar_set("g_race_qualifying_timelimit", ftos(qualifying_override));

		if (g_campaign) {
			g_race_qualifying = 1;
		} else {
			if (cvar("g_race_qualifying_timelimit") > 0) {
				race_fraglimit = cvar("fraglimit");
				race_leadlimit = cvar("leadlimit");
				race_timelimit = cvar("timelimit");
				cvar_set("fraglimit", "0");
				cvar_set("leadlimit", "0");
				cvar_set("timelimit", cvar_string("g_race_qualifying_timelimit"));
				g_race_qualifying = 2;
			} else
				g_race_qualifying = 0;
		}
	}
	if (g_cts)
		g_race_qualifying = 1;

	if (g_race_qualifying)
		independent_players = 1;

	if (g_race) {
		GameHook_WinningCondition = race_WinningCondition;
		GameHook_OvertimeHandle = race_OvertimeHandle;
		GameHook_KillDelayMod = race_KillDelayMod;
		GameHook_WarmupAllowed = race_WarmupAllowed;
		GameHook_ClearScoreAllowed = race_ClearScoresAllowed;
	}
	ScoreRules_race();
	GameHook_InitSpectator = race_InitSpectator;
	GameHook_Reset = race_Reset;
	GameHook_PlayerAllowedToMove = race_PlayerAllowedToMove;
	race_PlayerCanFire_NextLink = GameHookChain_PlayerCanFire;
	GameHookChain_PlayerCanFire = race_PlayerCanFire;
	GameHook_PhysicFrameBegin = race_PhysicFrameBegin;
	GameHook_SelectSpawnPoint = race_PreSpawn;
	race_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = race_Spawn;
	race_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = race_PlayerClear;
	race_GameHookChain_ObserverSpawn_Next = GameHookChain_ObserverSpawn;
	GameHookChain_ObserverSpawn = race_PreSpawnObserver;
	GameHook_SpawnPointGood = race_SpawnPointGood;
	race_WinCountDown_orig = GameHook_WinCountDown;
	GameHook_WinCountDown = race_WinCountDown;
	GameHook_FixClientCvars = race_FixClientCvars;
	GameHook_RecordForMap = race_RecordForMap;
	GameHook_ReadyAllowed = race_ReadyAllowed;
	GameHook_TelefragsAllowed = race_TelefragsAllowed;
	GameHook_ReadyRestartHard = race_ReadyRestartHard;
	GameHook_LeadLimitOverride = race_LeadLimitOverride;
	GameHook_FragLimitOverride = race_FragLimitOverride;
}
