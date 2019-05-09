float SP_REVIVE;

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
	scores_player_set(self.owner, SP_STATUS, 0);
	if (unfrozer.classname == "player") {
		scores_player_add(unfrozer, SP_SCORE, 1);
		scores_player_add(unfrozer, SP_REVIVE, 1);
	}
}

void Freeze_IceFrozenStatus() {
	scores_player_set(self, SP_STATUS, 1);
}

var void(float killed) Freeze_PlayerClear_NextLink;
void Freeze_PlayerClear(float killed)
{
	scores_player_set(self, SP_STATUS, 0);
	Roundbased_NeedCheckTeams();
	Freeze_PlayerClear_NextLink(killed);
}

float Freeze_HandleFrags(entity attacker, entity targ, float f) {
	scores_player_add(attacker, SP_SCORE, f);
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
	SP_REVIVE = scores_register_score("revs", SFL_SORT_PRIO_SECONDARY);
	SP_STATUS = scores_register_score("status", 0);
}
