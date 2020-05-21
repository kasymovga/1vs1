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
	score_player_set(self.owner, SP_STATUS, 0);
	if (unfrozer.classname == "player") {
		score_player_add(unfrozer, SP_SCORE, 1);
		score_player_add(unfrozer, SP_REVIVE, 1);
	}
}

void Freeze_IceFrozenStatus() {
	score_player_set(self, SP_STATUS, 1);
}

var void(float killed) Freeze_PlayerClear_NextLink;
void Freeze_PlayerClear(float killed)
{
	score_player_set(self, SP_STATUS, 0);
	Roundbased_NeedCheckTeams();
	Freeze_PlayerClear_NextLink(killed);
}

float Freeze_HandleFrags(entity attacker, entity targ, float f) {
	score_player_add(attacker, SP_SCORE, f);
	return 0;
}

void Freeze_Init_Shared(string gt) {
	hint_add("You can revive frozen teammates standing close to him");
	Roundbased_Init(cvar(strcat("g_", gt, "_enddelay")), cvar(strcat("g_", gt, "_startdelay")));
	IceHook_SkipThink = Freeze_IceSkipThink;
	IceHook_SkipDeathHandle = Freeze_IceSkipThink;
	IceHook_Unfroze = Freeze_IceUnfroze;
	IceHook_FrozenStatus = Freeze_IceFrozenStatus;
	Ice_Init();
	Freeze_Spawn_NextLink = gamehook_chain_spawn;
	gamehook_chain_spawn = Freeze_Spawn;
	Freeze_PlayerClear_NextLink = gamehook_chain_player_clear;
	gamehook_chain_player_clear = Freeze_PlayerClear;
	GameHook_FragsHandle = Freeze_HandleFrags;
	SP_REVIVE = score_register("revs", SFL_SORT_PRIO_SECONDARY);
	SP_STATUS = score_register("status", 0);
}
