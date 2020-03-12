float hint_count;
float sv_hints;

void(string hint) hint_add {
	if (hint_count >= 100)
		return;

	string s = strcat("_hint", ftos(hint_count));
	registercvar(s, hint);
	cvar_set(s, hint);
	hint_count++;
}

void(float n, float p) hint_send {
	if (n < 0)
		n = hint_count - 1;

	if (n >= hint_count)
		n = 0;

	string s = cvar_string(strcat("_hint", ftos(n)));
	msg_entity = self;
	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, TE_CSQC_HINT);
	WriteByte(MSG_ONE, p);
	WriteByte(MSG_ONE, n);
	WriteString(MSG_ONE, s);
}

var void(void(string item, string cmd) Add_Item) hint_GameMenuAddItems_next;
void hint_GameMenuAddItems(void(string item, string cmd) item_add) {
	item_add("Hints", "cmd hint 0;");
	hint_GameMenuAddItems_next(item_add);
}

var void(void) hint_RealClientConnect_next;
void(void) hint_RealClientConnect {
	if (hint_count <= 0)
		return;

	if (sv_hints > 1)
		hint_send(floor(random() * hint_count), 0);

	hint_RealClientConnect_next();
}

var float(string cmd, float tokens) hint_ClientCommandHandle_next;
float(string cmd, float tokens) hint_ClientCommandHandle {
	if (cmd == "hint" && tokens == 2) {
		hint_send(stof(argv(1)), 1);
		return TRUE;
	}
	return hint_ClientCommandHandle_next(cmd, tokens);
}

void(void) hint_init {
	CACHE_CVAR(sv_hints);
	hint_RealClientConnect_next = GameHookChain_RealClientConnect;
	GameHookChain_RealClientConnect = hint_RealClientConnect;
	hint_GameMenuAddItems_next = GameHookChain_GameMenuAddItems;
	GameHookChain_GameMenuAddItems = hint_GameMenuAddItems;
	hint_ClientCommandHandle_next = GameHookChain_ClientCommandHandle;
	GameHookChain_ClientCommandHandle = hint_ClientCommandHandle;
}
