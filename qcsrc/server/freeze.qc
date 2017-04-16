float g_freeze_enddelay;
float g_freeze_slowdown;
float g_freeze_startdelay;
float g_freeze_unfroze_time;
float sv_model_ice_scale;
float sv_model_ice_z;
float sv_model_ice_alpha;
string ice_model;
entity freeze_controller;
.entity ice;
.entity last_unfrozer;
.float unfroze_progress;
.entity unfroze_pb;
#define ICE_FRAME_TIME 0.2

float Freeze_SpeedMod();
float Freeze_DeathHandle(entity attacker, entity inflictor, float deathtype);
void Freeze_PlayerClear(entity plr, entity attacker, float killed);
float Freeze_HandleFrags(entity attacker, entity targ, float f);

void Freeze_Think()
{
	self.nextthink = time;
	Roundbased_TeamArenaThink();
}

void Freeze_Spawn(entity spot)
{
	Roundbased_NeedCheckTeams();
	if (Roundbased_Active)
		Freeze_DeathHandle(world, world, 0);
}

void Freeze_IceThink()
{
	self.nextthink = time + ICE_FRAME_TIME;
	if (self.owner.deadflag != DEAD_FREEZE || self.owner.ice != self)
	{
		if (self.unfroze_pb) //for self.owner.ice != self case
			remove(self.unfroze_pb);
		self.unfroze_pb = world;

		Freeze_PlayerClear(self.owner, world, 0);
		return;
	}

	if not(Roundbased_Active)
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
			self.unfroze_pb = ProgressBar_Create("Reviving", unfrozer);
			if not(self.owner.unfroze_pb)
				self.owner.unfroze_pb = ProgressBar_Create("Reviving", self.owner);
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
		self.unfroze_progress += ICE_FRAME_TIME;
		if (clienttype(unfrozer) == CLIENTTYPE_REAL)
			if (self.unfroze_pb)
				ProgressBar_SetValue(self.unfroze_pb, self.unfroze_progress / g_freeze_unfroze_time);

		if (clienttype(self.owner) == CLIENTTYPE_REAL)
			if (self.owner.unfroze_pb)
				ProgressBar_SetValue(self.owner.unfroze_pb, self.unfroze_progress / g_freeze_unfroze_time);

		unfrozer.bot_dontmove = time + ICE_FRAME_TIME * 1.5;
	}
	if (self.unfroze_progress >= g_freeze_unfroze_time)
	{
		if (clienttype(unfrozer) == CLIENTTYPE_REAL)
			centerprint(unfrozer, strcat("^4You revive ^7", self.owner.netname, "\n"));

		if (clienttype(self.owner) == CLIENTTYPE_REAL)
			centerprint(self.owner, strcat("^4You revived by ^7", unfrozer.netname, "\n"));

		bprint ("^1", self.owner.netname, "^1 was revived by ", unfrozer.netname, "\n");
		PlayerScore_Add(unfrozer, SP_SCORE, 1);
		self.owner.deadflag = DEAD_NO;
		return;
	}

	if (self.unfroze_progress == oldprogress)
	if (oldprogress != 0)
		self.unfroze_progress = min(0, oldprogress - ICE_FRAME_TIME);

	if (self.unfroze_progress != oldprogress)
		self.alpha = sv_model_ice_alpha * max(0.01, (g_freeze_unfroze_time - self.unfroze_progress));
}

float Freeze_DeathHandle(entity attacker, entity inflictor, float deathtype)
{
	if not(Roundbased_Active)
		return FALSE;

	PlayerClear(FALSE, world);
	Roundbased_NeedCheckTeams();

	if (self.deadflag == DEAD_FREEZE)
		return TRUE;

	if (deathtype)
		Obituary(attacker, inflictor, self, deathtype);

	self.deadflag = DEAD_FREEZE;
	self.health = start_health;
	PlayerScore_Set(self, SP_STATUS, 1);
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

float Freeze_PlayerDamageHandle(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
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

void Freeze_PlayerClear(entity plr, entity attacker, float killed)
{
	if (plr.ice)
		remove(plr.ice);

	if (plr.unfroze_pb)
		remove(plr.unfroze_pb);

	if (plr.ice.unfroze_pb)
		remove(plr.ice.unfroze_pb);

	PlayerScore_Set(plr, SP_STATUS, 0);
	plr.unfroze_pb = world;
	plr.ice = world;
	WaypointSprite_DetachCarrier(plr);
	Roundbased_NeedCheckTeams();
}

float Freeze_FragLimitOverride() {
	return cvar("g_freeze_winlimit");
}

void Freeze_Init()
{
	CACHE_CVAR(g_freeze);
	CACHE_CVAR(g_freeze_enddelay);
	CACHE_CVAR(g_freeze_slowdown);
	CACHE_CVAR(g_freeze_startdelay);
	CACHE_CVAR(g_freeze_unfroze_time);
	if (g_freeze_unfroze_time <= 0)
		g_freeze_unfroze_time = 1;
	CACHE_CVAR(sv_model_ice_alpha);
	CACHE_CVAR(sv_model_ice_scale);
	CACHE_CVAR(sv_model_ice_z);
	GameHook_DeathHandle = Freeze_DeathHandle;
	GameHook_Spawn = Freeze_Spawn;
	GameHook_PlayerClear = Freeze_PlayerClear;
	GameHook_SpeedMod = Freeze_SpeedMod;
	GameHook_PlayerDamageHandle = Freeze_PlayerDamageHandle;
	GameHook_FragsHandle = Freeze_HandleFrags;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Freeze_FragLimitOverride;
	freeze_controller = spawn();
	freeze_controller.think = Freeze_Think;
	freeze_controller.nextthink = time;
	Roundbased_Init(g_freeze_enddelay, g_freeze_startdelay);
	ice_model = strzone(cvar_string("sv_model_ice")); //strzone once and never strunzone
	precache_model(ice_model);
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status",     SFL_LOWER_IS_BETTER);
	ScoreRules_basics_end();
}

float Freeze_SpeedMod() {
	if (self.deadflag == DEAD_FREEZE)
		return g_freeze_slowdown;

	return 1;
}

float Freeze_HandleFrags(entity attacker, entity targ, float f) {
	PlayerScore_Add(attacker, SP_SCORE, f);
	attacker.totalfrags += f;
	return 0;
}
