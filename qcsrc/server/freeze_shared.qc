#define SP_REVIVE SP_GAME_SCORE6

var void(entity spot) Freeze_Spawn_NextLink;
void Freeze_Spawn(entity spot)
{
	Roundbased_NeedCheckTeams();
	Freeze_Spawn_NextLink(spot);
}

float Freeze_IceSkipThink() {
	return !Roundbased_Active;
}

void Freeze_IceUnfroze(entity unfrozer) {
	PlayerScore_Set(self.owner, SP_STATUS, 0);
	if (unfrozer.classname == "player") {
		PlayerScore_Add(unfrozer, SP_SCORE, 1);
		PlayerScore_Add(unfrozer, SP_REVIVE, 1);
	}
}

void Freeze_IceFrozenStatus() {
	PlayerScore_Set(self, SP_STATUS, 1);
}

var void(float killed) Freeze_PlayerClear_NextLink;
void Freeze_PlayerClear(float killed)
{
	PlayerScore_Set(self, SP_STATUS, 0);
	Roundbased_NeedCheckTeams();
	Freeze_PlayerClear_NextLink(killed);
}

float Freeze_HandleFrags(entity attacker, entity targ, float f) {
	PlayerScore_Add(attacker, SP_SCORE, f);
	attacker.totalfrags += f;
	return 0;
}

void Freeze_Init_Shared(string gt) {
	Roundbased_Init(cvar(strcat("g_", gt, "_enddelay")), cvar(strcat("g_", gt, "_startdelay")));
	IceHook_SkipThink = Freeze_IceSkipThink;
	IceHook_SkipDeathHandle = Freeze_IceSkipThink;
	IceHook_Unfroze = Freeze_IceUnfroze;
	IceHook_FrozenStatus = Freeze_IceFrozenStatus;
	Ice_Init();
	Freeze_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = Freeze_Spawn;
	Freeze_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = Freeze_PlayerClear;
	GameHook_FragsHandle = Freeze_HandleFrags;
	ScoreInfo_SetLabel_PlayerScore(SP_REVIVE, "revs", SFL_SORT_PRIO_SECONDARY);
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status", 0);
}
