void Warmup_Note_Message() {
	if (!other.ready && (other.classname == "player" || other.team > 0))
		self.message = "^2Currently in ^1warmup^2 stage!\n^2Press ^3{ready}^2 to finish warmup!";
	else
		self.message = "^2Currently in ^1warmup^2 stage!\n^2Waiting for others to ready up...";
}

void Warmup_UpdateNote() {
	if (warmup_note)
		warmup_note.SendFlags = 1;
}

var void(entity ignore) Warmup_Spawn_NextLink;
void Warmup_Spawn(entity ignore) {
	Warmup_UpdateNote();
	Warmup_Spawn_NextLink(ignore);
}

var void() Warmup_ObserverSpawn_NextLink;
void Warmup_ObserverSpawn() {
	Warmup_UpdateNote();
	Warmup_ObserverSpawn_NextLink();
}

void Warmup_Init() {
	inWarmupStage = cvar("g_warmup");
	if (!GameHook_WarmupAllowed() || g_campaign)
		inWarmupStage = 0; // these modes cannot work together, sorry

	if (inWarmupStage) {
		Warmup_Spawn_NextLink = GameHookChain_Spawn;
		GameHookChain_Spawn = Warmup_Spawn;
		Warmup_ObserverSpawn_NextLink = GameHookChain_ObserverSpawn;
		GameHookChain_ObserverSpawn = Warmup_ObserverSpawn;
		warmup_note = NoteLine_New(Warmup_Note_Message);
		Warmup_UpdateNote();
	}
}

void Warmup_Finish() {
	if (inWarmupStage) {
		inWarmupStage = 0; //once the game is restarted the game is in match stage
		remove(warmup_note);
	}
}
