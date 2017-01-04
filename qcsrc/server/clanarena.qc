entity ca_controller;

float g_clanarena_enddelay;
float g_clanarena_startdelay;

void Clanarena_Think()
{
	self.nextthink = time;
	Roundbased_TeamArenaThink();
}

void Clanarena_SpawnHook() {
	Roundbased_NeedCheckTeams();
	if not(Roundbased_Active)
		return;

	PutObserverInServer(FALSE);
}

float Clanarena_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	Roundbased_NeedCheckTeams();
	if not(Roundbased_Active)
		PutClientInServer();

	return FALSE;
}

float Clanarena_HandleFrags(entity attacker, entity targ, float f) {
	if (Roundbased_Active) {
		PlayerScore_Add(attacker, SP_SCORE, f);
		attacker.totalfrags += f;
	}
	return 0;
}

void Clanarena_Init()
{
	CACHE_CVAR(g_clanarena);
	if not(g_clanarena)
		return;

	CACHE_CVAR(g_clanarena_startdelay);
	CACHE_CVAR(g_clanarena_enddelay);

	GameHook_Spawn = Clanarena_SpawnHook;
	GameHook_FragsHandle = Clanarena_HandleFrags;
	GameHook_DeathHandle = Clanarena_DeathHandle;
	Roundbased_Init(g_clanarena_enddelay, g_clanarena_startdelay);
	ca_controller = spawn();
	ca_controller.think = Clanarena_Think;
	ca_controller.nextthink = time;
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
}
