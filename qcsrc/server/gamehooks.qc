float _GameHook_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	return FALSE;
}

void _GameHook_Spawn() {
}

float _GameHook_SpeedMod() {
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
	GameHook_Spawn = _GameHook_Spawn;
	GameHook_PlayerClear = _GameHook_PlayerClear;
	GameHook_SpeedMod = _GameHook_SpeedMod;
	GameHook_FragsHandle = _GameHook_FragsHandle;
	GameHook_DamageHandle = _GameHook_DamageHandle;
}
