float _GameHook_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	return FALSE;
}

void _GameHook_DoNothing() {
}

float _GameHook_Return1() {
	return 1;
}

float _GameHook_PlayerCanFire(entity plr) {
	return 1;
}

void _GameHook_PlayerClear(entity plr, entity attacker, float killed) {
}

float _GameHook_FragsHandle(entity attacker, entity targ, float f) {
	return f;
}

float _GameHook_DamageHandle(float deathtype) {
	return FALSE;
}

void GameHook_Init() {
	GameHook_DeathHandle = _GameHook_DeathHandle;
	GameHook_Spawn = _GameHook_DoNothing;
	GameHook_PlayerClear = _GameHook_PlayerClear;
	GameHook_SpeedMod = _GameHook_Return1;
	GameHook_FragsHandle = _GameHook_FragsHandle;
	GameHook_DamageHandle = _GameHook_DamageHandle;
	GameHook_PlayerCanFire = _GameHook_PlayerCanFire;
	GameHook_PlayerAllowedToMove = _GameHook_Return1;
	GameHook_PlayerPreThink = _GameHook_DoNothing;
}
