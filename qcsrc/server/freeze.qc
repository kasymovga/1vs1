float g_freeze_enddelay;
float g_freeze_startdelay;
entity freeze_controller;
#define SP_REVIVE SP_GAME_SCORE1

void Freeze_PlayerClear(float killed);
float Freeze_HandleFrags(entity attacker, entity targ, float f);

void Freeze_Think()
{
	self.nextthink = time;
	Roundbased_TeamArenaThink();
}

var void(entity spot) Freeze_Spawn_NextLink;
void Freeze_Spawn(entity spot)
{
	Roundbased_NeedCheckTeams();
	Freeze_Spawn_NextLink(spot);
}

var void(float killed) Freeze_PlayerClear_NextLink;
void Freeze_PlayerClear(float killed)
{
	PlayerScore_Set(self, SP_STATUS, 0);
	Roundbased_NeedCheckTeams();
	Freeze_PlayerClear_NextLink(killed);
}

float Freeze_FragLimitOverride() {
	return cvar("g_freeze_winlimit");
}

float Freeze_IceSkipThink() {
	return !Roundbased_Active;
}

void Freeze_IceUnfroze(entity unfrozer) {
	PlayerScore_Set(self.owner, SP_STATUS, 0);
	PlayerScore_Add(unfrozer, SP_SCORE, 1);
	PlayerScore_Add(unfrozer, SP_REVIVE, 1);
}

void Freeze_IceFrozenStatus() {
	PlayerScore_Set(self, SP_STATUS, 1);
}

void Freeze_Init()
{
	IceHook_SkipThink = Freeze_IceSkipThink;
	IceHook_SkipDeathHandle = Freeze_IceSkipThink;
	IceHook_Unfroze = Freeze_IceUnfroze;
	IceHook_FrozenStatus = Freeze_IceFrozenStatus;
	Ice_Init();
	CACHE_CVAR(g_freeze);
	CACHE_CVAR(g_freeze_enddelay);
	CACHE_CVAR(g_freeze_startdelay);
	Freeze_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = Freeze_Spawn;
	Freeze_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = Freeze_PlayerClear;
	GameHook_FragsHandle = Freeze_HandleFrags;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Freeze_FragLimitOverride;
	freeze_controller = spawn();
	freeze_controller.think = Freeze_Think;
	freeze_controller.nextthink = time;
	Roundbased_Init(g_freeze_enddelay, g_freeze_startdelay);
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	ScoreInfo_SetLabel_PlayerScore(SP_REVIVE, "revs", SFL_SORT_PRIO_SECONDARY);
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status", 0);
}

float Freeze_HandleFrags(entity attacker, entity targ, float f) {
	PlayerScore_Add(attacker, SP_SCORE, f);
	attacker.totalfrags += f;
	return 0;
}
