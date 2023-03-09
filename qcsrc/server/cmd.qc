void(entity e, string s) cmd_print_to {
    if (e)
        sprint(e, strcat("\{1}", s, "\n"));
    else
        print(s, "\n");
}

void(void) cmd_make_mapinfo_think {
	if (map_info_filter_game_type(MAP_INFO_TYPE_ALL, 0, 0, 1)) {
		print("Done rebuiling mapinfos.\n");
		map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), map_info_required_flags(), map_info_forbidden_flags(), 0);
		remove(self);
	} else {
		self.nextthink = time;
	}
}

void(float db, string pFilename) cmd_db_dump {
	float fh, i, j, n, m;
	fh = fopen(pFilename, FILE_WRITE);
	if (fh < 0)
		error(strcat("Can't dump DB to ", pFilename));

	n = buf_getsize(db);
	fputs(fh, "0\n");
	for(i = 0; i < n; ++i) {
		m = tokenizebyseparator(bufstr_get(db, i), "\\");
		for(j = 2; j < m; j += 2)
			fputs(fh, strcat("\\", argv(j-1), "\\", argv(j), "\n"));
	}
	fclose(fh);
}

void(string command) cmd_game {
	float argc;
	entity client, e;
	vector v;
	float entno, i;
	string s;
	entity plr;
	argc = tokenize_console(command);
	string cmd = argv(0);
	if (cmd == "help" || argc == 0) {
		print("Usage: sv_cmd COMMAND..., where possible commands are:\n");
		print("  adminmsg clientnumber \"message\"\n");
		print("  teamstatus\n");
		print("  printstats\n");
		print("  make_mapinfo\n");
		print("  gametype dm|ctf|...\n");
		print("  savedb filename\n");
		print("  dumpdb filename\n");
		print("  loaddb filename\n");
		print("  allready\n");
		print("  cvar_changes\n");
		print("  find classname\n");
		print("  records\n");
		vote_cmd("help", world);
		ban_cmd("help");
		cmd_generic("help");
		IP2C_GameCommand("help", argc);
		return;
	}
	if (vote_cmd(command, world))
		return;

	if (ban_cmd(command))
		return;

	if (cmd_generic(command))
		return;

	if (plugin_chain_cmd_game_handle(cmd, argc))
		return;

	if (cmd == "printstats") {
		world_dump_stats(FALSE);
		return;
	}
	if (cmd == "make_mapinfo") {
		e = spawn();
		e.classname = "make_mapinfo";
		e.think = cmd_make_mapinfo_think;
		e.nextthink = time;
		map_info_enumerate();
		return;
	}
	if (cmd == "gotomap") if (argc == 2) {
		print(map_goto(argv(1)), "\n");
		return;
	}
	if (cmd == "gametype") if (argc == 2) {
		float t, tsave;
		s = argv(1);
		t = game_type_from_name(s);
		tsave = game_type_current();
		if (t) {
			game_type_switch(t);
			map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), map_info_required_flags(), map_info_forbidden_flags(), 0);
			if (map_info_count > 0) {
				bprint("Game type successfully switched to ", s, "\n");
			} else {
				bprint("Cannot use this game type: no map for it found\n");
				game_type_switch(tsave);
				map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), map_info_required_flags(), map_info_forbidden_flags(), 0);
			}
		} else
			bprint("Game type switch to ", s, " failed: this type does not exist!\n");

		return;
	}
	if (cmd == "adminmsg") if (argc == 3) {
		entno = stof(argv(1));
		client = world;
		if (entno <= client_max_count)
			client = edict_num(entno);
		if (client.flags & FL_CLIENT) {
			centerprint_atprio(client, CENTERPRINT_PRIO_ADMIN, strcat("^3SERVER ADMIN:\n\n^7", argv(2)));
			sprint(client, strcat("\{1}\{13}^3SERVER ADMIN^7: ", argv(2), "\n"));
			print("Message sent to ", client.netname, "\n");
		} else
			print("Client not found\n");

		return;
	}
	if (cmd == "savedb") if (argc == 2) {
		db_save(db_server, argv(1));
		print("DB saved.\n");
		return;
	}
	if (cmd == "dumpdb") if (argc == 2) {
		cmd_db_dump(db_server, argv(1));
		print("DB dumped.\n");
		return;
	}
	if (cmd == "loaddb") if (argc == 2) {
		db_close(db_server);
		db_server = db_load(argv(1));
		print("DB loaded.\n");
		return;
	}
	if (cmd == "nospectators") {
		spectator_block = 1;
		FOR_EACH_CLIENT(plr) { //give every spectator <g_maxplayers_spectator_blocktime> seconds time to become a player
			if (plr.classname == "spectator" || plr.classname == "observer") {
				plr.spectatortime = time;
				sprint(plr, strcat("^7You have to become a player within the next ", ftos(cvar("g_maxplayers_spectator_blocktime")), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));
			}
		}
		bprint(strcat("^7All spectators will be automatically kicked when not joining the game after ", ftos(cvar("g_maxplayers_spectator_blocktime")), " seconds!\n"));
		return;
	}
	if (cmd == "team_lock") {
		if (team_mode) {
			team_lock = 1;
			bprint("^1The teams are now locked.\n");
		} else
			bprint("That command can only be used in a team-based gamemode.\n");

		return;
	}
	if (cmd == "unteam_lock") {
		if (team_mode) {
			team_lock = 0;
			bprint("^1The teams are now unlocked.\n");
		} else
			bprint("That command can only be used in a team-based gamemode.\n");

		return;
	}
	if (cmd == "movetoteam") if (argc == 3) {
		entno = stof(argv(1));
		client = world;
		if (entno <= client_max_count)
			client = edict_num(entno);

		if (client.flags & FL_CLIENT) {
			float lt;
			lt = team_lock;
			team_lock = 0;
			self = client;
			cmd_client(strcat("selectteam ", argv(2)));
			team_lock = lt;
		} else
			print("Client not found\n");

		return;
	}
	if (cmd == "teamstatus") {
		score_nice_print(world);
		return;
	}
	if (cmd == "allready") {
		ready_restart();
		return;
	}
	if (cmd == "cvar_changes") {
		print(cvar_changes);
		return;
	}
	if (cmd == "find") if (argc == 2) {
		for(client = world; (client = find(client, classname, argv(1))); )
			print(etos(client), "\n");

		return;
	}
	if (cmd == "records") {
		world_getrecords();
		for (i = 0; i <= cmd_records_reply_extra; i++)
			print(cmd_records_reply[i]);

		return;
	}
	if (cmd == "cointoss") {
		bprint("^3Throwing coin... Result: ");
		if (random() > 0.5)
			bprint("^1heads ^3!\n");
		else
			bprint("^1tails ^3!\n");

		return;
	}
	if (cmd == "__FORCE_READY_RESTART") {
		world_reset(FALSE);
		return;
	}
	if (cmd == "gettaginfo") if (argc >= 4) {
		e = spawn();
		if (argv(1) == "w")
			setmodel(e, (nextent(world)).weaponentity.model);
		else
			setmodel(e, argv(1));
		e.frame = stof(argv(2));
		i = gettagindex(e, argv(3));
		if (i) {
			v = gettaginfo(e, i);
			print("model ", e.model, " frame ", ftos(e.frame), " tag ", argv(3));
			print(" index = ", ftos(i));
			print(" vector = ", ftos(v_x), " ", ftos(v_y), " ", ftos(v_z), "\n");
			if (argc >= 6) {
				v_y = -v_y;
				localcmd(strcat(argv(4), vtos(v), argv(5), "\n"));
			}
		} else
			print("bone not found\n");

		remove(e);
		return;
	}
	if (cmd == "time") {
		print("time = ", ftos(time), "\n");
		print("frame start = ", ftos(gettime(GETTIME_FRAMESTART)), "\n");
		print("realtime = ", ftos(gettime(GETTIME_REALTIME)), "\n");
		print("hires = ", ftos(gettime(GETTIME_HIRES)), "\n");
		print("uptime = ", ftos(gettime(GETTIME_UPTIME)), "\n");
		print("localtime = ", strftime(TRUE, "%a %b %e %H:%M:%S %Z %Y"), "\n");
		print("gmtime = ", strftime(FALSE, "%a %b %e %H:%M:%S %Z %Y"), "\n");
		return;
	}
	if (cmd == "onslaught_updatelinks") {
		onslaught_updatelinks();
		print("ONS links updated\n");
		return;
	}
	if (cmd == "bot_cmd") {
		entity bot;
		if (argv(1) == "help") {
			if (argc==2) {
				bot_cmd_list();
				print("\nsv_cmd bot_cmd reset          #Clear the cmd queues of all bots\n");
				print("sv_cmd bot_cmd load <file>    #Load script file\n");
				print("\nUse sv_cmd bot_cmd help <command> for more\n\n");
				return;
			}
			bot_cmdhelp(argv(2));
			return;
		}
		// Clear all bot queues
		if (argv(1) == "reset") {
			bot_cmd_resetqueues();
			return;
		}
		// Load cmds from file
		if (argv(1) == "load" && argc == 3) {
			float fh;
			fh = fopen(argv(2), FILE_READ);
			if (fh < 0) {
				print("cannot open the file\n");
				return;
			}
			i = 0;
			while((s = fgets(fh))) {
				argc = tokenize_console(s);

				if (argc >= 3 && cmd == "sv_cmd" && argv(1) == "bot_cmd") {
					// let's start at token 2 so we can skip sv_cmd bot_cmd
					bot = bot_cmd_find_bot_by_number(stof(argv(2)));
					if (bot == world)
						bot = bot_cmd_find_bot_by_name(argv(2));

					if (bot)
						bot_queuecommand(bot, strcat(argv(3), " ", argv(4)));
				} else
					localcmd(strcat(s, "\n"));

				++i;
			}
			print(ftos(i), " commands read\n");
			fclose(fh);
			return;
		}
		if (argc < 3) {
			print("Usage: sv_cmd bot_cmd <bot name or number> <command> [argument]\n");
			print("Examples: bot_cmd <id> cc \"say something\"\n");
			print("          bot_cmd <id> presskey jump\n");
			print("          .. or sv_cmd bot_cmd help <command> for more\n");
			return;
		}
		bot = bot_cmd_find_bot_by_number(stof(argv(1)));
		if (bot == world)
			bot = bot_cmd_find_bot_by_name(argv(1));

		if (bot)
			bot_queuecommand(bot, strcat(argv(2), " ", argv(3)));
		else
			print(strcat("Error: Unable to find a bot with the name or number '",argv(1),"'\n"));

		return;
	}
	if (cmd == "alltospec") {
		FOR_EACH_PLAYER(plr) {
			player_to_spec(plr);
		}
		return;
	}
	if (team_mode)
	if (cmd == "shuffleteams") {
		float t = COLOR_TEAM4;
		random_queue_start();
		FOR_EACH_TEAMPLAYER(plr)
			random_queue_push(plr, 0, "");

		for(; random_queue_next();) {
			plr = random_queue_ent();
			team_teams_allowed(plr);
			if (t == COLOR_TEAM4)
				t = COLOR_TEAM1;
			else if (t == COLOR_TEAM1)
				t = COLOR_TEAM2;
			else if (t == COLOR_TEAM2)
				t = COLOR_TEAM3;
			else if (t == COLOR_TEAM3)
				t = COLOR_TEAM4;

			for (i = 0; i < 4; i++) {
				if (t == COLOR_TEAM1 && team1 < 0)
					t = COLOR_TEAM2;

				if (t == COLOR_TEAM2 && team2 < 0)
					t = COLOR_TEAM3;

				if (t == COLOR_TEAM3 && team3 < 0)
					t = COLOR_TEAM4;

				if (t == COLOR_TEAM4 && team4 < 0)
					t = COLOR_TEAM1;
			}
			if (t != plr.team) {
				player_set_team(plr, team_index(t), team_index(t), FALSE);
				e = self;
				self = plr;
				client_put();
				self = e;
				if (clienttype(plr) == CLIENTTYPE_REAL)
					centerprint(plr, strcat("You have been moved into a different team\nYou are now on: ", team_colored_name(t)));
			}
		}
		random_queue_end();
		return;
	}
	if (cmd == "extendmatchtime") {
		cvar_set("timelimit", ftos(min(cvar("timelimit_max"), cvar("timelimit") + cvar("timelimit_increment"))));
		bprint("\{1}^2Time limit extended to ", (ftos(cvar("timelimit"))), "\n");
		return;
	}
	if (cmd == "reducematchtime") {
		cvar_set("timelimit", ftos(max(cvar("timelimit_min"), cvar("timelimit") - cvar("timelimit_decrement"))));
		bprint("\{1}^2Time limit reduced to ", (ftos(cvar("timelimit"))), "\n");
		return;
	}
	if (cmd == "increasefraglimit") {
		cvar_set("fraglimit", ftos(min(cvar("fraglimit_max"), cvar("fraglimit") + cvar("fraglimit_increment"))));
		bprint("\{1}^2Frag limit increased to ", (ftos(cvar("fraglimit"))), "\n");
		return;
	}
	if (cmd == "decreasefraglimit") {
		cvar_set("fraglimit", ftos(max(cvar("fraglimit_min"), cvar("fraglimit") - cvar("fraglimit_decrement"))));
		bprint("\{1}^2Frag limit decreased to ", (ftos(cvar("fraglimit"))), "\n");
		return;
	}
	if (cmd == "stuffcmd") {
		e = edict_num(stof(argv(1)));
		if (clienttype(e) == CLIENTTYPE_REAL)
			stuffcmd(e, strcat(substring(command, argv_start_index(2), -1), "\n"));

		return;
	}
	if (cmd == "bprint") {
		FOR_EACH_REALCLIENT(e) {
			if (e.netaddress != "local")
				sprint(e, strcat(substring(command, argv_start_index(1), -1), "\n"));
		}
		return;
	}
	if (cmd == "rereadcvars") {
		world_dynamic_init();
		return;
	}
	if (cmd == "generatewaypoints") {
		waypoint_generate_waypoints();
		return;
	}
	print("Invalid command. For a list of supported commands, try sv_cmd help.\n");
}

.float cmd_floodtime;
.float cmd_floodcount;
float(void) cmd_floodcheck {
	if (timeout_status != 2) {
		if (time == self.cmd_floodtime) {
			self.cmd_floodcount += 1;
			if (self.cmd_floodcount > 8)
				return TRUE;
		} else {
			self.cmd_floodtime = time;
			self.cmd_floodcount = 1;
		}
	}
	return FALSE;
}

void(void) cmd_records_print_think {
	self.cnt = self.cnt + 1;
	sprint(self.enemy, cmd_records_reply[self.cnt]);
	if (self.cnt >= cmd_records_reply_extra) {
		remove(self);
	} else
		self.nextthink = time + sys_ticrate;
}

void(string s) cmd_client {
	string cmd;
	float tokens;
	entity e;
	if not(self.flags & FL_CLIENT)
	if (client_preconnect_abort())
		return;

	tokens = tokenize_console(s);
	cmd = argv(0);
	if (cmd != "sentcvar")
	if (cmd != "pause")
	if (cmd != "prespawn")
	if (cmd != "spawn")
	if (cmd != "begin") {
		if (cmd_floodcheck())
			return;
	}
	if (plugin_chain_cmd_client_handle(cmd, tokens))
		return;

	if (vote_cmd(s, self)) {
		return;
	} else if (map_vote_client_command(argv(0))) {
		return;
	} else if (cmd == "autoswitch") {
		// be backwards compatible with older clients (enabled)
		string autoswitchmsg;
		if (stof(argv(1))) {
			self.client_flags |= CLIENT_FLAG_AUTOSWITCH;
			autoswitchmsg = "on";
		} else {
			self.client_flags &= ~CLIENT_FLAG_AUTOSWITCH;
			autoswitchmsg = "off";
		}
		sprint(self, strcat("^1autoswitch turned ", autoswitchmsg, "\n"));
	} else if (cmd == "sentcvar") { // new system
		if (tokens == 2) { // undefined cvar: use the default value on the server then
			s = strcat(substring(s, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
			tokens = tokenize_console(s);
		}
		client_cvars_parse();
	} else if (cmd == "spectate") {
		if not(self.flags & FL_CLIENT)
			return;

		client_team_change_kill(-2);
	} else if (cmd == "join") {
		if not(self.flags & FL_CLIENT)
			return;
		if (self.classname != "player" && !team_lock)
			spectator_to_player();
	} else if ( cmd == "selectteam" ) {
		if not(self.flags & FL_CLIENT)
			return;
		if not(team_mode) {
			sprint( self, "selecteam can only be used in teamgames\n");
		} else if (g_campaign) {
		} else if (team_lock) {
			sprint( self, "^7The game has already begun, you must wait until the next map to be able to join a team.\n");
		} else if ( argv(1) == "red" ) {
			client_team_change(COLOR_TEAM1);
		} else if ( argv(1) == "blue" ) {
			client_team_change(COLOR_TEAM2);
		} else if ( argv(1) == "yellow" ) {
			client_team_change(COLOR_TEAM3);
		} else if ( argv(1) == "pink" ) {
			client_team_change(COLOR_TEAM4);
		} else if ( argv(1) == "auto" ) {
			client_team_change(-1);
		} else {
			sprint( self, strcat( "selectteam none/red/blue/yellow/pink/auto - \"", argv(1), "\" not recognised\n" ) );
		}
	} else if (cmd == "ready") {
		if not(self.flags & FL_CLIENT)
			return;

		if (warmup_active || cvar("sv_ready_restart") || plugin_ReadyAllowed()) {
			if (!ready_restart_happened || cvar("sv_ready_restart_repeatable")) {
				if (self.ready) { // toggle
					self.ready = FALSE;
					bprint(self.netname, "^2 is ^1NOT^2 ready\n");
				} else {
					self.ready = TRUE;
					bprint(self.netname, "^2 is ready\n");
				}
				warmup_note_update();
				// cannot reset the game while a timeout is active!
				if (!timeout_status)
					ready_count();
			} else {
				sprint(self, "^1Game has already been restarted\n");
			}
		}
	} else if (cmd == "maplist") {
		sprint(self, cmd_maplist_reply);
	} else if (cmd == "lsmaps") {
		sprint(self, cmd_lsmaps_reply);
	} else if (cmd == "lsmaps2") {
		msg_entity = self;
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_MAPLIST);
		net_write_string(MSG_ONE, map_list);
	} else if (cmd == "records") {
		if (cmd_records_reply[0] == "")
			sprint(self, "No records are available on this server.\n");
		else {
			sprint(self, "Records on this server:\n");
			sprint(self, cmd_records_reply[0]);
			if (cmd_records_reply_extra) {
				e = spawn();
				e.nextthink = time + sys_ticrate;
				e.enemy = self;
				e.think = cmd_records_print_think;
			}
		}
	} else if (cmd == "voice") {
		if (tokens >= 3)
			player_sound_voice_message(argv(1), substring(s, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));
		else
			player_sound_voice_message(argv(1), "");
	} else if (cmd == "say") {
		if (tokens >= 2) {
			chat_say(self, FALSE, world, substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
			if (substring(argv(1), 0, 1) == "/")
				vote_cmd(strcat("vote call ", substring(s, strstrofs(s, "/", 0) + 1, -1)), self);
		}
	} else if (cmd == "say_team") {
		if (tokens >= 2)
			chat_say(self, TRUE, world, substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
	} else if (cmd == "tell") {
		e = client_entity_from_argv(tokens, 1);
		if (e && tokens > client_entity_from_argv_firsttoken) {
			chat_say(self, FALSE, e, substring(s, argv_start_index(client_entity_from_argv_firsttoken), argv_end_index(-1) - argv_start_index(client_entity_from_argv_firsttoken)), TRUE);
		} else {
			if (tokens > client_entity_from_argv_firsttoken)
				trigger_magicear_processmessage_forallears(self, -1, world, substring(s, argv_start_index(client_entity_from_argv_firsttoken), argv_end_index(-1) - argv_start_index(client_entity_from_argv_firsttoken)));
			sprint(self, "ERROR: usage: tell # playerid text...\n");
		}
	} else if (cmd == "teamstatus") {
		score_nice_print(self);
	} else if (cmd == "cvar_changes") {
		sprint(self, cvar_changes);
	} else if (cmd == "menu_select") {
		menu_select(argv(1), stof(argv(2)));
	} else if (cmd == "location_select") {
		LocationRequest_Select(stof(argv(1)), stof(argv(2)));
	} else if (cmd == "mylocation") {
		sprint(self, strcat("your location: ", vtos(self.origin), "\n"));
	} else if (cmd == "recordlistchunk" && tokens == 3) {
		float n1 = floor(stof(argv(1))), n2 = floor(stof(argv(2)));
		if (n1 >= 0 && n1 <= CMD_RECORDS_REPLY_STRINGS_COUNT && n2 >= 0 && n2 < 16 && !map_finished) {
			msg_entity = self;
			net_write_byte(MSG_ONE, SVC_TEMPENTITY);
			net_write_byte(MSG_ONE, NET_TE_CSQC_RECORDLISTCHUNK);
			net_write_byte(MSG_ONE, n1);
			net_write_byte(MSG_ONE, n2);
			if (n1 < CMD_RECORDS_REPLY_STRINGS_COUNT) {
				string s2 = substring(cmd_records_reply[n1], 1024 * n2, 1024);
				net_write_string(MSG_ONE, s2);
			} else {
				net_write_string(MSG_ONE, "");
			}
		}

	} else {
		if (cmd != "status")
		if (cmd != "max")
		if (cmd != "monster")
		if (cmd != "scrag")
		if (cmd != "wraith")
		if (cmd != "gimme")
		if (cmd != "god")
		if (cmd != "notarget")
		if (cmd != "fly")
		if (cmd != "noclip")
		if (cmd != "give")
		if (cmd != "kill")
		if (cmd != "pause")
		if (cmd != "ping")
		if (cmd != "name")
		if (cmd != "color")
		if (cmd != "rate")
		if (cmd != "pmodel")
		if (cmd != "playermodel")
		if (cmd != "playerskin")
		if (cmd != "prespawn")
		if (cmd != "spawn")
		if (cmd != "begin")
		if (cmd != "pings")
		if (cmd != "sv_startdownload")
		if (cmd != "download")
		if (cmd != "rate_burstsize") {
			print("WARNING: Invalid clientcommand by ", self.netname, ": ", s, "\n");
			return;
		}
		if (cmd == "name") {
			string name = substring(s, argv_start_index(1), -1);
			if (self.abuser > 0)
				return;

			if (chat_message_forbidden(self, name)) {
				self.netname = "Empty Name";
				self.muted = 1;
				return;
			}
			client_mute_ifneeded(name);
			IRC_Announce_Name(self, name);
			if (strlen(strdecolorize(name)) > 48) {
				name = substring(name, 0, 47);
				s = strcat("name ", substring(name, 0, 47), "~");
			}
		}
		clientcommand(self,s);
	}
}
