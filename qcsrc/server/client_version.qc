var void(void) client_version_basics_end_next;
void(void) client_version_basics_end {
	var .float oldclientversionfield = clientversion;
	CLIENT_SCORE_VERSION = score_register((cvar("sv_clientversion_hidden") ? "cvhidden" : "cv"), SCORE_FLAG_NOCLEAR);
	clientversion = scores[CLIENT_SCORE_VERSION];
	if (oldclientversionfield) {
		entity e;
		FOR_EACH_REALPLAYER(e) {
			score_player_set(e, CLIENT_SCORE_VERSION, e.oldclientversionfield);
			e.clientversion = e.oldclientversionfield;
		}
	}
	client_version_basics_end_next();
}

void(void) client_version_set_delayed {
	if (clienttype(self.owner) != CLIENTTYPE_REAL) {
		print("client_version_set_delayed: invalid client\n");
		remove(self);
		return;
	}
	if (self.owner.scorekeeper) {
		score_player_set(self.owner, CLIENT_SCORE_VERSION, self.cnt);
		self.owner.clientversion = self.cnt;
		remove(self);
		return;
	}
	self.nextthink = time + 0.1;
}

void(entity cl, string s) client_version_set {
	float v;
	if (s == "newrexuiz") {
		v = CLIENT_VERSION_NEWREXUIZ;
	} else if (s == "rexuiz") {
		v = CLIENT_VERSION_REXUIZ;
	} else if (s == "nexuiz") {
		v = CLIENT_VERSION_NEXUIZ;
	} else if (s == "oldnexuiz") {
		v = CLIENT_VERSION_OLDNEXUIZ;
	} else {
		v = CLIENT_VERSION_UNKNOWN;
	}
	if not(cl.scorekeeper) {
		entity e;
		for (e = world; (e = find(e, classname, "client_version_set")); ) {
			if (e.owner == self) {
				e.cnt = v;
				return;
			}
		}
		e = spawn();
		e.classname = "client_version_set";
		e.owner = self;
		e.think = client_version_set_delayed;
		e.nextthink = time + 0.1;
		e.cnt = v;
		return;
	}
	score_player_set(cl, CLIENT_SCORE_VERSION, v);
	cl.clientversion = v;
}

var float(string cmd, float tokens) client_version_cmd_client_handle_next;
float(string cmd, float tokens) client_version_cmd_client_handle {
	if (cmd == "clientversion" && tokens == 2) {
		string s = argv(1);
		print("Game client for ", self.netname, ": ", s, "\n");
		client_version_set(self, s);
		return TRUE;
	}
	return client_version_cmd_client_handle_next(cmd, tokens);
}

var void(void) client_version_client_connect_next;
void(void) client_version_client_connect {
	if (clienttype(self) == CLIENTTYPE_BOT)
		score_player_set(self, CLIENT_SCORE_VERSION, CLIENT_VERSION_BOT);

	client_version_client_connect_next();
}

float client_version_init_done;
void(void) client_version_init {
	if (client_version_init_done)
		return;

	client_version_init_done = TRUE;
	client_version_basics_end_next = plugin_chain_score_basics_end;
	plugin_chain_score_basics_end = client_version_basics_end;
	client_version_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = client_version_cmd_client_handle;
	client_version_client_connect_next = plugin_chain_client_connect;
	plugin_chain_client_connect = client_version_client_connect;
}
