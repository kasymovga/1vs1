float freeze_active;
float freeze_activate_time;
float freeze_countdown_last;
float freeze_winner_team;
float g_tdm_freeze_enddelay;
float g_tdm_freeze_slowdown;
float g_tdm_freeze_startdelay;
float g_tdm_freeze_unfroze_time;
float sv_model_ice_scale;
float sv_model_ice_z;
float sv_model_ice_alpha;
string ice_model;
entity freeze_controller;
.entity ice;
.entity last_unfrozer;
.float unfroze_progress;
.entity unfroze_pb;

void Freeze_Think()
{
	self.nextthink = time;
	if (gameover)
		return;
	if (time < game_starttime)
		return;
	entity plr;
	float team_alive, have_death_players, team_check;
	team_check = 0;
	FOR_EACH_PLAYER(plr) {
		if not(team_check)
			team_check = plr.team;
		else if (plr.team != team_check) {
			team_check = -1;
			break;
		}
	}
	if (team_check >= 0) {
		FOR_EACH_PLAYER(plr)
		{
			plr.deadflag = DEAD_NO;
			Freeze_PlayerClear(plr);
			if (clienttype(plr) == CLIENTTYPE_REAL)
				centerprint(plr, "^2Awaiting players...\n");
		}
		freeze_active = 0;
		freeze_activate_time = time + g_tdm_freeze_enddelay;
		return;
	}
	if not(freeze_active)
	{
		if (time >= freeze_activate_time)
		{
			game_starttime = freeze_activate_time + g_tdm_freeze_startdelay;
			freeze_countdown_last = 0;
			reset_map(TRUE);
			FOR_EACH_PLAYER(plr)
				Freeze_PlayerClear(plr);
			freeze_active = 1;
			FOR_EACH_REALPLAYER(plr) {
				centerprint(plr, "^2Starting new round\n");
			}
			return;
		}
		else
		{
			FOR_EACH_REALPLAYER(plr)
			{
				float countdown = ceil(freeze_activate_time - time);
				if (freeze_countdown_last != countdown)
				{
					string winner_message;
					if (freeze_winner_team > 0)
						winner_message = strcat(Team_ColorName(freeze_winner_team), " Team wins!");
					else
						winner_message = "";
					centerprint(plr, strcat("^2Round finished!\n^2", winner_message, "\n^2Restarting in ", ftos(countdown), "\n"));
					freeze_countdown_last = countdown;
				}
			}
		}
	}
	if not(freeze_active)
		return;

	team_alive = 0;
	have_death_players = 0;
    FOR_EACH_PLAYER(plr)
    {
        if (plr.deadflag == DEAD_FREEZE)
		{
			have_death_players = 1;
			continue;
		}
		
		if (team_alive > 0) {
			if (plr.team != team_alive)
			{
				team_alive = -1;
			}
		}
		else if not(team_alive)
		{
			team_alive = plr.team;
		}
    }
	if (team_alive > 0 && have_death_players)
		TeamScore_AddToTeam(team_alive, ST_SCORE, 1);
	else if (team_alive < 0)
		return;

	if (have_death_players)
	{
		freeze_winner_team = team_alive;
		freeze_active = 0;
		freeze_activate_time = time + g_tdm_freeze_enddelay;
	}
}

void Freeze_FreezePlayer()
{
}

void Freeze_SpawnHook()
{
	if (freeze_active)
		Freeze_DeathHandle(world, world, 0);
}

void Freeze_IceThink()
{
	self.nextthink = time;
	if (self.owner.deadflag != DEAD_FREEZE || self.owner.ice != self)
	{
		if (self.unfroze_pb) //for self.owner.ice != self case
			remove(self.unfroze_pb);
		self.unfroze_pb = world;

		Freeze_PlayerClear(self.owner);
		return;
	}

	if not(freeze_active)
		return;

	float oldprogress = self.unfroze_progress;
	entity e, unfrozer;
	unfrozer = world;
	if (self.last_unfrozer && self.last_unfrozer.deadflag == DEAD_NO && vlen(self.last_unfrozer.origin - self.owner.origin) <= 100)
	{
		unfrozer = self.last_unfrozer;
	}
	else FOR_EACH_PLAYER(e)
	{
		if (e == self.owner || e.team != self.owner.team || e.deadflag != DEAD_NO || vlen(e.origin - self.owner.origin) > 100)
			continue;

		unfrozer = e;
		break;
	}
	if (unfrozer != self.last_unfrozer)
	{
		if (self.unfroze_pb)
			remove(self.unfroze_pb);

		if (unfrozer) {
			self.unfroze_pb = ProgressBar_Create("Unfrozing", unfrozer);
			if not(self.owner.unfroze_pb)
				self.owner.unfroze_pb = ProgressBar_Create("Unfrozing", self.owner);
		} else {
			if (self.owner.unfroze_pb)
				remove(self.owner.unfroze_pb);

			self.owner.unfroze_pb = world;
			self.unfroze_pb = world;
		}
	}

	self.last_unfrozer = unfrozer;
	if (unfrozer)
	{
		self.unfroze_progress += frametime;
		if (clienttype(unfrozer) == CLIENTTYPE_REAL)
			if (self.unfroze_pb)
				ProgressBar_SetValue(self.unfroze_pb, self.unfroze_progress / g_tdm_freeze_unfroze_time);

		if (clienttype(self.owner) == CLIENTTYPE_REAL)
			if (self.owner.unfroze_pb)
				ProgressBar_SetValue(self.owner.unfroze_pb, self.unfroze_progress / g_tdm_freeze_unfroze_time);
	}
	if (self.unfroze_progress >= g_tdm_freeze_unfroze_time)
	{
		if (clienttype(unfrozer) == CLIENTTYPE_REAL)
			centerprint(unfrozer, strcat("^4You revive ^7", self.owner.netname, "\n"));

		if (clienttype(self.owner) == CLIENTTYPE_REAL)
			centerprint(self.owner, strcat("^4You revived by ^7", unfrozer.netname, "\n"));

		PlayerScore_Add(unfrozer, SP_SCORE, 1);
		self.owner.deadflag = DEAD_NO;
		return;
	}

	if (self.unfroze_progress == oldprogress)
	if (oldprogress != 0)
		self.unfroze_progress = min(0, oldprogress - frametime);

	if (self.unfroze_progress != oldprogress)
		self.alpha = sv_model_ice_alpha * max(0.01, (g_tdm_freeze_unfroze_time - self.unfroze_progress));
}

float Freeze_DeathHandle(entity attacker, entity inflictor, float deathtype)
{
	if not(g_tdm)
		return FALSE;

	if not(g_tdm_freeze)
		return FALSE;

	if (self.deadflag == DEAD_FREEZE)
		return TRUE;

	if (freeze_active)
	if (deathtype)
		Obituary(attacker, inflictor, self, deathtype);

	self.deadflag = DEAD_FREEZE;
	self.health = start_health;
	if (self.ice)
		return TRUE;

	self.ice = spawn();
	self.ice.alpha = sv_model_ice_alpha;
	self.ice.scale = sv_model_ice_scale;
	self.ice.owner = self;
	self.ice.think = Freeze_IceThink;
	self.ice.nextthink = time;
	self.ice.colormod = TeamColor(self.team);
	WaypointSprite_AttachCarrier("helpme", self);
	setattachment(self.ice, self, "");
	setorigin(self.ice, '0 0 1' * sv_model_ice_z);
	setmodel(self.ice, ice_model);
	return TRUE;
}

float Freeze_DamageHandle(float deathtype)
{
	if not(self.deadflag == DEAD_FREEZE)
		return FALSE;

	if (deathtype == DEATH_SLIME ||
			deathtype == DEATH_LAVA ||
			deathtype == DEATH_HURTTRIGGER)
		PutClientInServer();

	self.unfroze_progress = 0;

	return TRUE;
}

void Freeze_PlayerClear(entity plr)
{
	if (plr.ice)
		remove(plr.ice);
	if (plr.unfroze_pb)
		remove(plr.unfroze_pb);
	if (plr.ice.unfroze_pb)
		remove(plr.ice.unfroze_pb);
	plr.unfroze_pb = world;
	plr.ice = world;
	WaypointSprite_DetachCarrier(plr);
}

void Freeze_Init()
{
	CACHE_CVAR(g_tdm_freeze);
	CACHE_CVAR(g_tdm_freeze_enddelay);
	CACHE_CVAR(g_tdm_freeze_slowdown);
	CACHE_CVAR(g_tdm_freeze_startdelay);
	CACHE_CVAR(g_tdm_freeze_unfroze_time);
	if (g_tdm_freeze_unfroze_time <= 0)
		g_tdm_freeze_unfroze_time = 1;
	CACHE_CVAR(sv_model_ice_alpha);
	CACHE_CVAR(sv_model_ice_scale);
	CACHE_CVAR(sv_model_ice_z);
	addstat(STAT_PLAYER_STATE, AS_INT, deadflag);
	if not(g_tdm)
		return;
	if not(g_tdm_freeze)
		return;
	freeze_activate_time = time + g_tdm_freeze_startdelay;
	freeze_controller = spawn();
	freeze_controller.think = Freeze_Think;
	freeze_controller.nextthink = time;
	ice_model = strzone(cvar_string("sv_model_ice")); //strzone once and never strunzone
	precache_model(ice_model);
}

float Freeze_SpeedMod() {
	if (self.deadflag == DEAD_FREEZE)
		return g_tdm_freeze_slowdown;

	return 1;
}

float Freeze_HandleFrags(entity attacker, entity targ, float f) {
	PlayerScore_Add(attacker, SP_SCORE, f);
	attacker.totalfrags += f;
	return 0;
}
