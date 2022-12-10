float VOIP_SCORE;

var void(void) voip_score_basics_end_next;
void(void) voip_score_basics_end {
	voip_score_basics_end_next();
	VOIP_SCORE = score_register("voip", SCORE_FLAG_NOCLEAR);
}

void(entity pl) voip_setup {
	float vg = pl.voipgroup;
	if (!vg)
		return;

	if (clienttype(pl) == CLIENTTYPE_BOT)
		pl.voipgroup = 0;

	if (team_mode && g_voice_chat_public < 2 && team_teams > 1) {
		pl.voipgroup = pl.team;
	} else {
		if (pl.team < 0 || g_voice_chat_public)
			pl.voipgroup = -1;
		else
			pl.voipgroup = 1;
	}
	if (pl.muted) {
		pl.voipgroup = -256 - num_for_edict(pl);
	}
	if (pl.retard > 0) {
		pl.voipgroup = -512 - num_for_edict(pl);
	}
	if (vg != pl.voipgroup)
		print(player_name(pl), "^7 switched to VOIP channel #", ftos(pl.voipgroup), "\n");

	if (pl.scorekeeper) {
		score_player_set(pl, VOIP_SCORE, pl.voipgroup);
	}
}

void(entity pl) voip_disable {
	pl.voipgroup = 0;
	if (pl.scorekeeper)
		score_player_set(pl, VOIP_SCORE, 0);
}

void(entity pl) voip_enable {
	if (clienttype(pl) == CLIENTTYPE_REAL) {
		pl.voipgroup = -768 - num_for_edict(pl);
		if (pl.scorekeeper)
			voip_setup(pl);
	} else
		pl.voipgroup = 0;
}

void(void) voip_setup_all {
	entity e;
	FOR_EACH_REALCLIENT(e)
		if (e.voipgroup)
			voip_setup(e);
}

var void(void) voip_client_connect_next;
void(void) voip_client_connect {
	score_player_set(self, VOIP_SCORE, self.voipgroup);
}

void(void) voip_init {
	voip_score_basics_end_next = plugin_chain_score_basics_end;
	plugin_chain_score_basics_end = voip_score_basics_end;
	voip_client_connect_next = plugin_chain_client_connect;
	plugin_chain_client_connect = voip_client_connect;
}
