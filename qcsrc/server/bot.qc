float bot_ai_dangerdetectioninterval;
float bot_ai_dangerdetectionupdates;
float bot_ai_thinkinterval;
float bot_god;
float bot_join_empty;
float bot_navigation_ignoreplayers;
float bot_number;
float bot_usemodelnames;
float bot_vs_human;
float waypoint_benchmark;
float skill_auto;
float skill_auto_min;
float skill_auto_max;

entity(void) bot_spawn {
	entity oldself, bot;
	bot = spawnclient();
	if (bot) {
		bot_count = bot_count + 1;
		oldself = self;
		self = bot;
		bot_setnameandstuff();
		client_connect();
		PutClientInServer();
		self = oldself;
	}
	return bot;
}

void(void) bot_think {
	if (self.bot_nextthink > time)
		return;

	self.flags &= ~FL_GODMODE;
	if (bot_god)
		self.flags |= FL_GODMODE;

	self.bot_nextthink = self.bot_nextthink + bot_ai_thinkinterval * pow(0.5, bot_aiskill);
	if (self.fixangle) {
		self.v_angle = self.angles;
		self.v_angle_z = 0;
		self.fixangle = FALSE;
	}
	if (time < map_starttime || ((g_campaign && !campaign_bots_may_start))) {
		self.bot_nextthink = time + 0.5;
		return;
	}
	// calculate an aiming latency based on the skill setting
	// (simulated network latency + naturally delayed reflexes)
	// minimum ping 20+10 random
	self.ping = bound(0,0.07 - bound(0, (skill + bot_pingskill) * 0.005,0.05)+random()*0.01,0.65); // Now holds real lag to server, and higer skill players take a less laggy server
	// skill 10 = ping 0.2 (adrenaline)
	// skill 0 = ping 0.7 (slightly drunk)
	// clear buttons
	self.BUTTON_ATCK = 0;
	self.button1 = 0;
	self.BUTTON_JUMP = 0;
	self.BUTTON_ATCK2 = 0;
	self.BUTTON_ZOOM = 0;
	self.BUTTON_CROUCH = 0;
	self.BUTTON_HOOK = 0;
	self.BUTTON_INFO = 0;
	self.button8 = 0;
	self.BUTTON_CHAT = 0;
	self.BUTTON_USE = 0;
	// if dead, just wait until we can respawn
	if (self.deadflag) {
		if (self.deadflag == DEAD_DEAD) {
			self.BUTTON_JUMP = 1; // press jump to respawn
			self.bot_strategytime = 0;
		}
	}
	// now call the current bot AI (havocbot for example)
	self.bot_ai();
}

void(void) bot_setnameandstuff {
	string bot_cfg = "", s;
	float tokens, prio, i;
	entity p;
	string bot_name, bot_model, bot_skin, bot_shirt, bot_pants;
	string name, prefix, suffix;
	if (g_campaign) {
		prefix = "";
		suffix = "";
	} else {
		prefix = cvar_string("bot_prefix");
		suffix = cvar_string("bot_suffix");
	}
	random_selection_init();
	for(i = 1;; i++) {
		bot_cfg = cvar_string(strcat("bot", ftos(i)));
		if (bot_cfg == "") break;
		tokens = tokenizebyseparator(bot_cfg, " ");
		s = argv(0);
		prio = 1;
		CLIENT_FOR_EACH_BOT(p) {
			if (strcat(prefix, s, suffix) == p.netname) {
				prio = 0;
				break;
			}
		}
		random_selection_add(NULL, 0, bot_cfg, 1, prio);
	}
	bot_cfg = random_selection_chosen_string;
	if (bot_cfg == "") bot_cfg = "bot marine 1 1 1";
	tokens = tokenizebyseparator(bot_cfg, " ");
	if (argv(0) != "") bot_name = argv(0);
	else bot_name = "Bot";
	if (argv(1) != "") bot_model = argv(1);
	else bot_model = "marine";
	if (argv(2) != "") bot_skin = argv(2);
	else bot_skin = "0";
	if (argv(3) != "" && stof(argv(3)) >= 0) bot_shirt = argv(3);
	else bot_shirt = ftos(floor(random() * 15));
	if (argv(4) != "" && stof(argv(4)) >= 0) bot_pants = argv(4);
	else bot_pants = ftos(floor(random() * 15));
	//print(bot_name, ": ping=", argv(9), "\n");
	self.bot_config_loaded = TRUE;
	// this is really only a default, JoinBestTeam is called later
	setcolor(self, stof(bot_shirt) * 16 + stof(bot_pants));
	self.bot_preferredcolors = self.clientcolors;
	// pick the name
	if (bot_usemodelnames)
		name = bot_model;
	else
		name = bot_name;

	// pick the model and skin
	if (substring(bot_model, -4, 1) != ".")
		bot_model = strcat(bot_model, ".dpm");

	self.playermodel = self.playermodel_freeme = strzone(strcat("models/player/", bot_model));
	self.playerskin = self.playerskin_freeme = strzone(bot_skin);
	self.netname = self.netname_freeme = strzone(strcat(prefix, name, suffix));
}

float(string s) bot_custom_weapon_id {
	float f = stof(s);
	if (f > 0) return f;
	entity e = weapon_info_by_name(s);
	if (e) return e.weapon;
	return -1;
}

void(void) bot_custom_weapon_priority_setup {
	float tokens, i, c, w;
	bot_custom_weapon = FALSE;
	if (cvar_string("bot_ai_custom_weapon_priority_far") == "" ||
			cvar_string("bot_ai_custom_weapon_priority_mid") == "" ||
			cvar_string("bot_ai_custom_weapon_priority_close") == "" ||
			cvar_string("bot_ai_custom_weapon_priority_distances") == "")
		return;

	// Parse distances
	tokens = tokenizebyseparator(cvar_string("bot_ai_custom_weapon_priority_distances")," ");
	if (tokens!=2)
		return;

	bot_distance_far = stof(argv(0));
	bot_distance_close = stof(argv(1));
	if (bot_distance_far < bot_distance_close){
		bot_distance_far = stof(argv(1));
		bot_distance_close = stof(argv(0));
	}
	// Initialize list of weapons
	bot_weapons_far[0] = -1;
	bot_weapons_mid[0] = -1;
	bot_weapons_close[0] = -1;
	// Parse far distance weapon priorities
	tokens = tokenizebyseparator(cvar_string("bot_ai_custom_weapon_priority_far")," ");
	c = 0;
	for (i=0; i < tokens && c < WEAPON_COUNT_EXTRA; ++i){
		w = bot_custom_weapon_id(argv(i));
		if (WEAPON_VALID(w)) {
			bot_weapons_far[c] = w;
			++c;
		}
	}
	if (c < WEAPON_COUNT)
		bot_weapons_far[c] = -1;

	// Parse mid distance weapon priorities
	tokens = tokenizebyseparator(cvar_string("bot_ai_custom_weapon_priority_mid")," ");
	c = 0;
	for (i=0; i < tokens && c < WEAPON_COUNT_EXTRA; ++i){
		w = bot_custom_weapon_id(argv(i));
		if (WEAPON_VALID(w)) {
			bot_weapons_mid[c] = w;
			++c;
		}
	}
	if (c < WEAPON_COUNT)
		bot_weapons_mid[c] = -1;

	// Parse close distance weapon priorities
	tokens = tokenizebyseparator(cvar_string("bot_ai_custom_weapon_priority_close")," ");
	c = 0;
	for (i=0; i < tokens && i < WEAPON_COUNT_EXTRA; ++i){
		w = bot_custom_weapon_id(argv(i));
		if (WEAPON_VALID(w)) {
			bot_weapons_close[c] = w;
			++c;
		}
	}
	if (c < WEAPON_COUNT_EXTRA)
		bot_weapons_close[c] = -1;

	bot_custom_weapon = TRUE;
}

void(void) bot_endgame {
	entity e;
	e = bot_list;
	while (e) {
		setcolor(e, e.bot_preferredcolors);
		e = e.nextbot;
	}
	// if dynamic waypoints are ever implemented, save them here
}

void(void) bot_relinkplayerlist {
	entity e;
	entity prevbot;
	player_count = 0;
	bot_count = 0;
	e = findchainflags(flags, FL_CLIENT);
	bot_list = world;
	prevbot = world;
	while (e)
	{
		player_count = player_count + 1;
		e.nextplayer = e.chain;
		if (clienttype(e) == CLIENTTYPE_BOT)
		{
			e.nextbot = world;
			if (prevbot)
				prevbot.nextbot = e;
			else
				bot_list = e;

			prevbot = e;
			bot_count = bot_count + 1;
		}
		e = e.chain;
	}
	bot_strategytoken = bot_list;
	bot_strategytoken_taken = TRUE;
}

void(void) bot_clientdisconnect {
	if (clienttype(self) != CLIENTTYPE_BOT)
		return;

	if (self.netname_freeme)
		strunzone(self.netname_freeme);

	if (self.playermodel_freeme)
		strunzone(self.playermodel_freeme);

	if (self.playerskin_freeme)
		strunzone(self.playerskin_freeme);

	self.netname_freeme = NULL;
	self.playermodel_freeme = NULL;
	self.playerskin_freeme = NULL;
	remove(self.bot_cmd_current);
}

void(void) bot_clientconnect {
	if (clienttype(self) != CLIENTTYPE_BOT)
		return;

	self.bot_preferredcolors = self.clientcolors;
	self.bot_nextthink = time - random();
	self.lag_func = bot_lagfunc;
	self.createdtime = self.bot_nextthink;
	if (!self.bot_config_loaded) // This is needed so team overrider doesn't break between matches
		bot_setnameandstuff();

	havocbot_setupbot();
}

void(void) bot_removefromlargestteam {
	float besttime, bestcount, thiscount;
	entity best, head;
	team_teams_allowed(world);
	team_teams_count(world);
	CLIENT_FOR_EACH_BOT(head) { break; }
	if (clienttype(head) != CLIENTTYPE_BOT)
		return;

	best = head;
	besttime = head.createdtime;
	bestcount = 0;
	CLIENT_FOR_EACH_BOT(head) {
		if (head.team == COLOR_TEAM1)
			thiscount = team1;
		else if (head.team == COLOR_TEAM2)
			thiscount = team2;
		else if (head.team == COLOR_TEAM3)
			thiscount = team3;
		else if (head.team == COLOR_TEAM4)
			thiscount = team4;
		else
			thiscount = 0;

		if (thiscount > bestcount) {
			bestcount = thiscount;
			besttime = head.createdtime;
			best = head;
		} else if (thiscount == bestcount && besttime < head.createdtime) {
			besttime = head.createdtime;
			best = head;
		}
	}
	bot_count = bot_count - 1;
	dropclient(best);
}

void(void) bot_removenewest {
	float besttime;
	entity best, head;
	if (team_mode) {
		bot_removefromlargestteam();
		return;
	}
	CLIENT_FOR_EACH_BOT(head) { break; }
	if (clienttype(head) != CLIENTTYPE_BOT)
		return;

	best = head;
	besttime = head.createdtime;
	CLIENT_FOR_EACH_BOT(head) {
		if (besttime < head.createdtime) {
			besttime = head.createdtime;
			best = head;
		}
	}
	bot_count = bot_count - 1;
	dropclient(best);
}

float bot_skill_auto_last_difference;
float bot_skill_auto_nextthink;
void(void) bot_skill_auto {
	float bestbot;
	float bestplayer;
	float havebot, haveplayer;
	float _kills;
	entity head;
	bestbot = -100;
	bestplayer = -100;
	havebot = haveplayer = 0;
	PLAYER_FOR_EACH(head) {
		_kills = head.scorekeeper.scores[SP_KILLS];
		if (clienttype(head) == CLIENTTYPE_REAL) {
			bestplayer = max(bestplayer, _kills);
			haveplayer = 1;
		} else {
			bestbot = max(bestbot, _kills);
			havebot = 1;
		}
	}
	float difference = bestbot - bestplayer;
	if (difference == bot_skill_auto_last_difference)
		return;

	if (!havebot || !haveplayer) {
		return;
	} else if (difference < 0 && difference < bot_skill_auto_last_difference) {
		if (skill < skill_auto_max) {
			skill = skill + 1;
			cvar_set("skill", ftos(skill));
			print_all(PRINT_INFO, "^2SKILL UP!^7 Now at level {1}", ftos(skill), "", "");
		}
	} else if (difference > 0 && difference > bot_skill_auto_last_difference) {
		if (skill > skill_auto_min) {
			skill = skill - 1;
			cvar_set("skill", ftos(skill));
			print_all(PRINT_INFO, "^1SKILL DOWN!^7 Now at level {1}", ftos(skill), "", "");
		}
	}
	bot_skill_auto_last_difference = difference;
}

entity bot_dangerwaypoint;
void(float maxupdate) bot_updatedangerousobjects {
	entity head, bot_dodgelist;
	vector m1, m2, v;
	float c, d, danger;
	c = 0;
	bot_dodgelist = findchainfloat(bot_dodge, TRUE);
	bot_dangerwaypoint = find(bot_dangerwaypoint, classname, "waypoint");
	while (bot_dangerwaypoint != world) {
		danger = 0;
		m1 = bot_dangerwaypoint.mins;
		m2 = bot_dangerwaypoint.maxs;
		head = bot_dodgelist;
		while (head) {
			v = head.origin;
			v_x = bound(m1_x, v_x, m2_x);
			v_y = bound(m1_y, v_y, m2_y);
			v_z = bound(m1_z, v_z, m2_z);
			d = head.bot_dodgerating - vlen(head.origin - v);
			if (d > 0) {
				trace_line(head.origin, v, TRUE, world);
				if (trace_fraction == 1)
					danger = danger + d;
			}
			head = head.chain;
		}
		bot_dangerwaypoint.dmg = danger;
		c = c + 1;
		if (c >= maxupdate)
			break;

		bot_dangerwaypoint = find(bot_dangerwaypoint, classname, "waypoint");
	}
}

float bot_serverframe_nextthink;
float bot_serverframe_nextdangertime;
void(void) bot_serverframe {
	float realplayers, bots, activerealplayers;
	entity head;
	if (map_intermission_running)
		return;

	if (time < 2)
		return;

	skill = cvar("skill");
	bot_skill10 = sqrt(skill * 2.5);
	stepheightvec = sv_stepheight * '0 0 1';
	bot_navigation_movemode = ((bot_navigation_ignoreplayers) ? TRACE_MOVE_NOMONSTERS : TRACE_MOVE_NORMAL);
	if (time > bot_skill_auto_nextthink) {
		if (skill_auto)
			bot_skill_auto();

		bot_skill_auto_nextthink = time + 5;
	}
	activerealplayers = 0;
	realplayers = 0;
	CLIENT_FOR_EACH_REAL(head) {
		if (head.classname == "player" || head.team >= 0)
			++activerealplayers;
		++realplayers;
	}
	// add/remove bots if needed to make sure there are at least
	// minplayers+bot_number, or remove all bots if no one is playing
	// But don't remove bots immediately on level change, as the real players
	// usually haven't rejoined yet
	bot_would_leave = FALSE;
	if ((realplayers || bot_join_empty || (bot_count > 0 && time < 5))) {
		float realminplayers, minplayers;
		realminplayers = cvar("minplayers");
		float realminbots, minbots;
		if (team_mode && bot_vs_human) {
			minbots = realminbots = ceil(fabs(bot_vs_human) * activerealplayers);
			minplayers = 0;
		} else {
			if (team_mode)
				realminplayers = ceil(realminplayers * cvar("minplayers_team_factor")) * team_teams;

			realminbots = bot_number;
			minplayers = max(0, floor(realminplayers));
			minbots = max(0, floor(realminbots));
		}
		bots = min(max(minbots, minplayers - activerealplayers), client_max_count - realplayers);
		if (bots > minbots)
			bot_would_leave = TRUE;
	} else {
		// if there are no players, remove bots
		bots = 0;
	}
	// only add one bot per frame to avoid utter chaos
	if (time > bot_serverframe_nextthink) {
		while (bot_count < bots) {
			if (bot_spawn() == world) {
				print_all(PRINT_INFO, "Can not add bot, server full.", "" , "", "");
				bot_serverframe_nextthink = time + 10;
				break;
			}
		}
		while (bot_count > bots)
			bot_removenewest();
	}
	if (bot_list) {
		// cycle the goal token from one bot to the next each frame
		// (this prevents them from all doing spawnfunc_waypoint searches on the same
		//  frame, which causes choppy framerates)
		if (bot_strategytoken_taken) {
			bot_strategytoken_taken = FALSE;
			if (bot_strategytoken)
				bot_strategytoken = bot_strategytoken.nextbot;

			if (!bot_strategytoken)
				bot_strategytoken = bot_list;
		}
		if (bot_serverframe_nextdangertime < time) {
			float interval;
			interval = bot_ai_dangerdetectioninterval;
			if (bot_serverframe_nextdangertime < time - interval * 1.5)
				bot_serverframe_nextdangertime = time;

			bot_serverframe_nextdangertime = bot_serverframe_nextdangertime + interval;
			bot_updatedangerousobjects(bot_ai_dangerdetectionupdates);
		}
	}
	if (g_waypointeditor)
		waypoint_show_links();

	if (time > bot_cvar_nextthink) {
		bot_cvar_nextthink = time + 5;
	}
}

void(entity source, float teamsay, entity privatesay, string msglist, string prefix) bot_say {
	float n;
	if (msglist == "")
		return;

	n = floor(random() * tokenizebyseparator(msglist, "|"));
	chat_say(source, teamsay, privatesay, strcat(prefix, argv(n)), FALSE);
}

void(void) bot_init {
	CVAR_CACHE(bot_ai_dangerdetectioninterval);
	CVAR_CACHE(bot_ai_dangerdetectionupdates);
	CVAR_CACHE(bot_ai_thinkinterval);
	CVAR_CACHE(bot_god);
	CVAR_CACHE(bot_ignore_bots);
	CVAR_CACHE(bot_join_empty);
	CVAR_CACHE(bot_navigation_ignoreplayers);
	CVAR_CACHE(bot_number);
	CVAR_CACHE(bot_usemodelnames);
	CVAR_CACHE(bot_vs_human);
	CVAR_CACHE(waypoint_benchmark);
	CVAR_CACHE(skill_auto);
	CVAR_CACHE(skill_auto_min);
	CVAR_CACHE(skill_auto_max);
	CVAR_CACHE(bot_moveskill);
	CVAR_CACHE(bot_dodgeskill);
	CVAR_CACHE(bot_pingskill);
	CVAR_CACHE(bot_weaponskill);
	CVAR_CACHE(bot_aggresskill);
	CVAR_CACHE(bot_rangepreference);
	CVAR_CACHE(bot_aimskill);
	CVAR_CACHE(bot_offsetskill);
	CVAR_CACHE(bot_mouseskill);
	CVAR_CACHE(bot_thinkskill);
	CVAR_CACHE(bot_aiskill);
	bot_aim_init();
	navigation_init();
	bot_cmd_init();
	havocbot_init();
	bot_custom_weapon_priority_setup();
}

void(entity bot, float _delay) bot_stay {
	bot.bot_dontmove = max(time, bot.bot_nextthink) + _delay + 2 * sys_ticrate;
}
