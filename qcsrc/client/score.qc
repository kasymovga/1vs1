void(float ignore) score_info_read {
	float i, j, t;
	entity o;
	self.classname = "ent_client_scores_info";
	game_type = net_read_byte();
	string s;
	SP_CLIENTVERSION_FIELD = -1;
	SP_COUNTRY_FIELD = -1;
	SP_STATUS_FIELD = -1;
	SP_NADGET_FIELD = -1;
	SP_NADGET_SECONDARY_FIELD = -1;
	SP_BESTWEP_FIELD = -1;
	for (i = 0; i < SCORE_FILEDS_MAX; ++i) {
		s = strzone(net_read_string());
		if (s == "country")
			SP_COUNTRY_FIELD = i;
		else if (s == "kills")
			SP_KILLS_FIELD = i;
		else if (s == "bestwep")
			SP_BESTWEP_FIELD = i;
		else if (s == "suicides")
			SP_SUICIDES_FIELD = i;
		else if (s == "deaths")
			SP_DEATHS_FIELD = i;
		else if (s == "nade")
			SP_NADGET_FIELD = i;
		else if (s == "nade2")
			SP_NADGET_SECONDARY_FIELD = i;
		else if (s == "team") {
			SP_TEAM_BIT = 1;
			SP_TEAM_FIELD = i;
			for (j = 0; j < i; j++) SP_TEAM_BIT = SP_TEAM_BIT * 2;
			for (o = player_list.sort_next; o; o = o.sort_next)
				if (o.gotscores) {
					t = o.scores[SP_TEAM_FIELD];
					if (t < 0)
						t = TEAM_COLOR_SPECTATOR;

					team_set(o, t);
				}
		} else if (s == "status")
			SP_STATUS_FIELD = i;
		else if (s == "cv")
			SP_CLIENTVERSION_FIELD = i;

		scores_label[i] = s;
		scores_flags[i] = net_read_byte();
	}
	for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
		teamscores_label[i] = strzone(net_read_string());
		teamscores_flags[i] = net_read_byte();
	}
	sbar_scores_init();
	game_type_init();
}

void(void) score_player_remove {
	float i;
	if (self.owner) {
		for (entity e = find(NULL, classname, "score_receiver"); e; e = find(e, classname, "score_receiver")) // Not the last score receiver
			if (e != self)
			if (e.owner == self.owner)
			if (e.entremove == score_player_remove)
				return;

		team_set(self.owner, -1);
		player_remove(self.owner);
		self.owner.gotscores = 0;
		for (i = 0; i < SCORE_FILEDS_MAX; ++i)
			self.owner.(scores[i]) = 0; // clear all scores
	}
}

void(float ignore) score_player_read {
	float i, n;
	entity o;
	n = net_read_byte() - 1;
	if (self.owner && n != self.sv_entnum) { // workaround for DP bug
		//print("A CSQC entity changed its owner!\n");
		csqc_entity_clean();
		self.enttype = NET_CSQC_SCORES;
	}
	self.sv_entnum = n;
	if not(player_slots[self.sv_entnum])
		player_slots[self.sv_entnum] = spawn();

	o = self.owner = player_slots[self.sv_entnum];
	o.sv_entnum = self.sv_entnum;
	o.gotscores = 1;
	if not(o.sort_prev)
		player_register(o);

	float sf, lf;
	float l = net_read_byte();
	self.classname = "score_receiver";
	if (l == 4) {
		n = SCORE_FILEDS_MAX;
		sf = net_read_coord();
		lf = net_read_coord();
	} else if (l == 2) {
		n = 16;
		sf = net_read_short();
		lf = net_read_short();
	} else {
		n = 8;
		sf = net_read_byte();
		lf = net_read_byte();
	}
	float p;
	for (i = 0, p = 1; i < n; ++i, p *= 2)
		if (sf & p) {
			if (lf & p)
				o.(scores[i]) = net_read_int24();
			else
				o.(scores[i]) = net_read_char();
		}
	if (sf & SP_TEAM_BIT) {
		float t = o.scores[SP_TEAM_FIELD];
		if (t < 0)
			t = TEAM_COLOR_SPECTATOR;

		team_set(o, t);
	}
	if (o.sort_prev)
		sbar_scores_player_position_update(o); // if not registered, we cannot do this yet!

	self.entremove = score_player_remove;
}

void(float ignore) score_team_read {
	float i, t;
	entity o;
	self.team = net_read_byte();
	o = self.owner = team_get(self.team, TRUE); // these team numbers can always be trusted
	float sf, lf;
#if SCORE_TEAM_FIELDS_MAX <= 8
	sf = net_read_byte();
	lf = net_read_byte();
#else
	sf = net_read_short();
	lf = net_read_short();
#endif
	float p;
	for (i = 0, p = 1; i < SCORE_TEAM_FIELDS_MAX; ++i, p *= 2)
		if (sf & p) {
			if (lf & p)
				o.(teamscores[i]) = net_read_int24();
			else
				o.(teamscores[i]) = net_read_char();
		}
	sbar_scores_team_position_update(o);
	if (SP_TEAM_BIT)
		for (o = player_list.sort_next; o; o = o.sort_next)
			if (o.gotscores) {
				t = o.scores[SP_TEAM_FIELD];
				if (t < 0)
					t = TEAM_COLOR_SPECTATOR;

				team_set(o, t);
			}
}

