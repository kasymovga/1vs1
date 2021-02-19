void(entity e, string s) cmd_print_to {
    if (e)
        sprint(e, strcat(s, "\n"));
    else
        print(s, "\n");
}

void cmd_make_mapinfo_think()
{
	if(MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 1))
	{
		print("Done rebuiling mapinfos.\n");
		MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		remove(self);
	}
	else
	{
		self.nextthink = time;
	}
}

void(float db, string pFilename) cmd_db_dump {
	float fh, i, j, n, m;
	fh = fopen(pFilename, FILE_WRITE);
	if(fh < 0)
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

	if(cmd == "help" || argc == 0)
	{
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
		GameCommand_Ban("help");
		cmd_generic("help");
		IP2C_GameCommand("help", argc);
		return;
	}

	if(vote_cmd(command, world))
		return;

	if(GameCommand_Ban(command))
		return;

	if(cmd_generic(command))
		return;

	if (gamehook_chain_GameCommandHandle(cmd, argc))
		return;

	if(cmd == "printstats")
	{
		world_dump_stats(FALSE);
		return;
	}

	if(cmd == "make_mapinfo")
	{
		e = spawn();
		e.classname = "make_mapinfo";
		e.think = cmd_make_mapinfo_think;
		e.nextthink = time;
		MapInfo_Enumerate();
		return;
	}

	if(cmd == "gotomap") if(argc == 2)
	{
		print(map_goto(argv(1)), "\n");
		return;
	}

	if(cmd == "gametype") if(argc == 2)
	{
		float t, tsave;
		s = argv(1);
		t = MapInfo_Type_FromString(s);
		tsave = MapInfo_CurrentGametype();
		if(t)
		{
			MapInfo_SwitchGameType(t);
			MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
			if(MapInfo_count > 0)
			{
				bprint("Game type successfully switched to ", s, "\n");
			}
			else
			{
				bprint("Cannot use this game type: no map for it found\n");
				MapInfo_SwitchGameType(tsave);
				MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
			}
		}
		else
			bprint("Game type switch to ", s, " failed: this type does not exist!\n");
		return;
	}

	if(cmd == "adminmsg") if(argc == 3)
	{
		entno = stof(argv(1));
		client = world;
		if(entno <= client_max_count)
			client = edict_num(entno);
		if(client.flags & FL_CLIENT)
		{
			centerprint_atprio(client, CENTERPRIO_ADMIN, strcat("^3SERVER ADMIN:\n\n^7", argv(2)));
			sprint(client, strcat("\{1}\{13}^3SERVER ADMIN^7: ", argv(2), "\n"));
			print("Message sent to ", client.netname, "\n");
		}
		else
			print("Client not found\n");
		return;
	}

	if(cmd == "savedb") if(argc == 2)
	{
		db_save(db_server, argv(1));
		print("DB saved.\n");
		return;
	}

	if(cmd == "dumpdb") if(argc == 2)
	{
		cmd_db_dump(db_server, argv(1));
		print("DB dumped.\n");
		return;
	}

	if(cmd == "loaddb") if(argc == 2)
	{
		db_close(db_server);
		db_server = db_load(argv(1));
		print("DB loaded.\n");
		return;
	}
	if (cmd == "nospectators")
	{
		spectator_block = 1;
		FOR_EACH_CLIENT(plr) //give every spectator <g_maxplayers_spectator_blocktime> seconds time to become a player
		{
			if(plr.classname == "spectator" || plr.classname == "observer")
			{
				plr.spectatortime = time;
				sprint(plr, strcat("^7You have to become a player within the next ", ftos(cvar("g_maxplayers_spectator_blocktime")), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));
			}
		}
		bprint(strcat("^7All spectators will be automatically kicked when not joining the game after ", ftos(cvar("g_maxplayers_spectator_blocktime")), " seconds!\n"));
		return;
	}
	if (cmd == "team_lock") {
		if(team_mode) {
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
	if (cmd == "movetoteam") if(argc == 3)
	{
		entno = stof(argv(1));
		client = world;
		if(entno <= client_max_count)
			client = edict_num(entno);
		if(client.flags & FL_CLIENT)
		{
			float lt;
			lt = team_lock;
			team_lock = 0;

			self = client;
			cmd_client(strcat("selectteam ", argv(2)));

			team_lock = lt;
		}
		else
			print("Client not found\n");
		return;
	}
	if (cmd == "teamstatus")
	{
		score_nice_print(world);
		return;
	}
	if (cmd == "allready")
	{
		ready_restart();
		return;
	}
	if (cmd == "cvar_changes")
	{
		print(cvar_changes);
		return;
	}
	if (cmd == "find") if(argc == 2)
	{
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
	if(cmd == "cointoss")
	{
		bprint("^3Throwing coin... Result: ");
		if (random() > 0.5)
			bprint("^1heads ^3!\n");
		else
			bprint("^1tails ^3!\n");
		return;
	}

	if(cmd == "__FORCE_READY_RESTART")
	{
		world_reset(FALSE);
		return;
	}

	if(cmd == "gettaginfo") if(argc >= 4)
	{
		e = spawn();
		if(argv(1) == "w")
			setmodel(e, (nextent(world)).weaponentity.model);
		else
			setmodel(e, argv(1));
		e.frame = stof(argv(2));
		i = gettagindex(e, argv(3));
		if(i)
		{
			v = gettaginfo(e, i);
			print("model ", e.model, " frame ", ftos(e.frame), " tag ", argv(3));
			print(" index = ", ftos(i));
			print(" vector = ", ftos(v_x), " ", ftos(v_y), " ", ftos(v_z), "\n");
			if(argc >= 6)
			{
				v_y = -v_y;
				localcmd(strcat(argv(4), vtos(v), argv(5), "\n"));
			}
		}
		else
			print("bone not found\n");
		remove(e);
		return;
	}

	if(cmd == "time")
	{
		print("time = ", ftos(time), "\n");
		print("frame start = ", ftos(gettime(GETTIME_FRAMESTART)), "\n");
		print("realtime = ", ftos(gettime(GETTIME_REALTIME)), "\n");
		print("hires = ", ftos(gettime(GETTIME_HIRES)), "\n");
		print("uptime = ", ftos(gettime(GETTIME_UPTIME)), "\n");
		print("localtime = ", strftime(TRUE, "%a %b %e %H:%M:%S %Z %Y"), "\n");
		print("gmtime = ", strftime(FALSE, "%a %b %e %H:%M:%S %Z %Y"), "\n");
		return;
	}

	if(cmd == "tracebug")
	{
		print("TEST CASE. If this returns the runaway loop counter error, possibly everything is oaky.\n");
		for(;;)
		{
			vector org, delta, start, end, p, pos;
			float safe, unsafe;

			org = world.mins;
			delta = world.maxs - world.mins;

			start_x = org_x + random() * delta_x;
			start_y = org_y + random() * delta_y;
			start_z = org_z + random() * delta_z;

			end_x = org_x + random() * delta_x;
			end_y = org_y + random() * delta_y;
			end_z = org_z + random() * delta_z;

			start = stov(vtos(start));
			end = stov(vtos(end));

			trace_box(start, PL_MIN, PL_MAX, end, MOVE_NOMONSTERS, world);
			if(!trace_startsolid)
			{
				p = trace_endpos;
				trace_box(p, PL_MIN, PL_MAX, p, MOVE_NOMONSTERS, world);
				if(trace_startsolid)
				{
					rint(42); // do an engine breakpoint on VM_rint so you can get the trace that errnoeously returns startsolid
					trace_box(start, PL_MIN, PL_MAX, end, MOVE_NOMONSTERS, world);
					trace_box(p, PL_MIN, PL_MAX, p, MOVE_NOMONSTERS, world);

					// how much do we need to back off?
					safe = 1;
					unsafe = 0;
					for(;;)
					{
						pos = p * (1 - (safe + unsafe) * 0.5) + start * ((safe + unsafe) * 0.5);
						trace_box(pos, PL_MIN, PL_MAX, pos, MOVE_NOMONSTERS, world);
						if(trace_startsolid)
						{
							if((safe + unsafe) * 0.5 == unsafe)
								break;
							unsafe = (safe + unsafe) * 0.5;
						}
						else
						{
							if((safe + unsafe) * 0.5 == safe)
								break;
							safe = (safe + unsafe) * 0.5;
						}
					}

					print("safe distance to back off: ", ftos(safe * vlen(p - start)), "qu\n");
					print("unsafe distance to back off: ", ftos(unsafe * vlen(p - start)), "qu\n");

					trace_box(p, PL_MIN + '0.1 0.1 0.1', PL_MAX - '0.1 0.1 0.1', p, MOVE_NOMONSTERS, world);
					if(trace_startsolid)
						print("trace_endpos much in solid when tracing from ", vtos(start), " to ", vtos(end), " endpos ", vtos(trace_endpos), "\n");
					else
						print("trace_endpos just in solid when tracing from ", vtos(start), " to ", vtos(end), " endpos ", vtos(trace_endpos), "\n");
					break;
				}
			}
		}
	}

	if(cmd == "tracewalk")
	{
		e = nextent(world);
		if(tracewalk(e, stov(argv(1)), e.mins, e.maxs, stov(argv(2)), MOVE_NORMAL))
			print("can walk\n");
		else
			print("cannot walk\n");
		return;
	}

	if(cmd == "onslaught_updatelinks")
	{
		onslaught_updatelinks();
		print("ONS links updated\n");
		return;
	}

	if(cmd == "bot_cmd")
	{
		local entity bot;

		if(argv(1) == "help")
		{
			if(argc==2)
			{
				bot_list_commands();
				print("\nsv_cmd bot_cmd reset          #Clear the cmd queues of all bots\n");
				print("sv_cmd bot_cmd load <file>    #Load script file\n");
				print("\nUse sv_cmd bot_cmd help <command> for more\n\n");
				return;
			}

			bot_cmdhelp(argv(2));
			return;
		}

		// Clear all bot queues
		if(argv(1) == "reset")
		{
			bot_resetqueues();
			return;
		}

		// Load cmds from file
		if(argv(1) == "load" && argc == 3)
		{
			float fh;
			fh = fopen(argv(2), FILE_READ);
			if(fh < 0)
			{
				print("cannot open the file\n");
				return;
			}

			i = 0;
			while((s = fgets(fh)))
			{
				argc = tokenize_console(s);

				if(argc >= 3 && cmd == "sv_cmd" && argv(1) == "bot_cmd")
				{
					// let's start at token 2 so we can skip sv_cmd bot_cmd
					bot = find_bot_by_number(stof(argv(2)));
					if(bot == world)
						bot = find_bot_by_name(argv(2));
					if(bot)
						bot_queuecommand(bot, strcat(argv(3), " ", argv(4)));
				}
				else
					localcmd(strcat(s, "\n"));

				++i;
			}

			print(ftos(i), " commands read\n");

			fclose(fh);

			return;
		}

		if(argc < 3)
		{
			print("Usage: sv_cmd bot_cmd <bot name or number> <command> [argument]\n");
			print("Examples: bot_cmd <id> cc \"say something\"\n");
			print("          bot_cmd <id> presskey jump\n");
			print("          .. or sv_cmd bot_cmd help <command> for more\n");
			return;
		}

		bot = find_bot_by_number(stof(argv(1)));
		if(bot == world)
			bot = find_bot_by_name(argv(1));

		if(bot)
			bot_queuecommand(bot, strcat(argv(2), " ", argv(3)));
		else
			print(strcat("Error: Unable to find a bot with the name or number '",argv(1),"'\n"));

		return;
	}

	if (cmd == "alltospec")
	{
		FOR_EACH_PLAYER(plr)
		{
			player_to_spec(plr);
		}
		return;
	}
	if (team_mode)
	if (cmd == "shuffleteams")
	{
		float t = COLOR_TEAM4;
		autoswap_last_best = world;
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

	if (cmd == "rereadcvars")
	{
		world_dynamic_init();
		return;
	}

	print("Invalid command. For a list of supported commands, try sv_cmd help.\n");
}

.float cmd_floodtime;
.float cmd_floodcount;
float cmd_floodcheck()
{
	if (timeoutStatus != 2)
	{
		if(time == self.cmd_floodtime)
		{
			self.cmd_floodcount += 1;
			if(self.cmd_floodcount > 8)
				return TRUE;
		}
		else
		{
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
	if(cmd != "sentcvar")
	if(cmd != "pause")
	if(cmd != "prespawn")
	if(cmd != "spawn")
	if(cmd != "begin")
	{
		if(cmd_floodcheck())
			return;
	}

	if (gamehook_chain_cmd_client_handle(cmd, tokens))
		return;

	if (vote_cmd(s, self)) {
		return;
	} else if(mapvote_client_command(argv(0))) {
		return;
	} else if(cmd == "autoswitch") {
		// be backwards compatible with older clients (enabled)
		self.autoswitch = ("0" != argv(1));
		local string autoswitchmsg;
		if (self.autoswitch) {
			autoswitchmsg = "on";
		} else {
			autoswitchmsg = "off";
		}
		sprint(self, strcat("^1autoswitch turned ", autoswitchmsg, "\n"));
	} else if(cmd == "sentcvar") { // new system
		if(tokens == 2) // undefined cvar: use the default value on the server then
		{
			s = strcat(substring(s, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
			tokens = tokenize_console(s);
		}
		client_cvars_parse();
	} else if(cmd == "spectate") {
		if not(self.flags & FL_CLIENT)
			return;

		client_team_change_kill(-2);
	} else if(cmd == "join") {
		if not(self.flags & FL_CLIENT)
			return;
		if (self.classname != "player" && !team_lock)
			spectator_to_player();
	} else if( cmd == "selectteam" ) {
		if not(self.flags & FL_CLIENT)
			return;
		if not(team_mode) {
			sprint( self, "selecteam can only be used in teamgames\n");
		} else if(g_campaign) {
		} else if(team_lock) {
			sprint( self, "^7The game has already begun, you must wait until the next map to be able to join a team.\n");
		} else if( argv(1) == "red" ) {
			client_team_change(COLOR_TEAM1);
		} else if( argv(1) == "blue" ) {
			client_team_change(COLOR_TEAM2);
		} else if( argv(1) == "yellow" ) {
			client_team_change(COLOR_TEAM3);
		} else if( argv(1) == "pink" ) {
			client_team_change(COLOR_TEAM4);
		} else if( argv(1) == "auto" ) {
			client_team_change(-1);
		} else {
			sprint( self, strcat( "selectteam none/red/blue/yellow/pink/auto - \"", argv(1), "\" not recognised\n" ) );
		}
	} else if(cmd == "ready") {
		if not(self.flags & FL_CLIENT)
			return;

		if(warmup_active || cvar("sv_ready_restart") || gamehook_ReadyAllowed()) {
			if(!ready_restart_happened || cvar("sv_ready_restart_repeatable"))
			{
				if (self.ready) // toggle
				{
					self.ready = FALSE;
					bprint(self.netname, "^2 is ^1NOT^2 ready\n");
				}
				else
				{
					self.ready = TRUE;
					bprint(self.netname, "^2 is ready\n");
				}
				warmup_note_update();
				// cannot reset the game while a timeout is active!
				if(!timeoutStatus)
					ready_count();
			} else {
				sprint(self, "^1Game has already been restarted\n");
			}
		}
	} else if(cmd == "maplist") {
		sprint(self, cmd_maplist_reply);
	} else if(cmd == "lsmaps") {
		sprint(self, cmd_lsmaps_reply);
	} else if(cmd == "lsmaps2") {
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_MAPLIST);
		WriteString(MSG_ONE, map_list);
	} else if(cmd == "gameclient") {
		s = argv(1);
		print("Game client for ", self.netname, ": ", s, "\n");
		client_version_set(self, s);
	} else if(cmd == "records") {
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
	} else if(cmd == "voice") {
		if(tokens >= 3)
			player_voice_message(argv(1), substring(s, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));
		else
			player_voice_message(argv(1), "");
	} else if(cmd == "say") {
		if(tokens >= 2)
		{
			chat_say(self, FALSE, world, substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
			if (substring(argv(1), 0, 1) == "/")
				vote_cmd(strcat("vote call ", substring(s, strstrofs(s, "/", 0) + 1, -1)), self);
		}
	} else if(cmd == "say_team") {
		if(tokens >= 2)
			chat_say(self, TRUE, world, substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
	} else if(cmd == "tell") {
		e = client_entity_from_argv(tokens, 1);
		if(e && tokens > client_entity_from_argv_firsttoken)
		{
			chat_say(self, FALSE, e, substring(s, argv_start_index(client_entity_from_argv_firsttoken), argv_end_index(-1) - argv_start_index(client_entity_from_argv_firsttoken)), TRUE);
		}
		else
		{
			if(tokens > client_entity_from_argv_firsttoken)
				trigger_magicear_processmessage_forallears(self, -1, world, substring(s, argv_start_index(client_entity_from_argv_firsttoken), argv_end_index(-1) - argv_start_index(client_entity_from_argv_firsttoken)));
			sprint(self, "ERROR: usage: tell # playerid text...\n");
		}
	} else if(cmd == "teamstatus") {
		score_nice_print(self);
	} else if(cmd == "cvar_changes") {
		sprint(self, cvar_changes);
	} else if(cmd == "menu_select") {
		menu_select(argv(1), stof(argv(2)));
	} else if(cmd == "location_select") {
		LocationRequest_Select(stof(argv(1)), stof(argv(2)));
	} else if(cmd == "mylocation") {
		sprint(self, strcat("your location: ", vtos(self.origin), "\n"));
	} else if(cmd == "recordlistchunk" && tokens == 3) {
		float n1 = floor(stof(argv(1))), n2 = floor(stof(argv(2)));
		if (n1 >= 0 && n1 <= CMD_RECORDS_REPLY_STRINGS_COUNT && n2 >= 0 && n2 < 16) {
			msg_entity = self;
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_RECORDLISTCHUNK);
			WriteByte(MSG_ONE, n1);
			WriteByte(MSG_ONE, n2);
			if (n1 < CMD_RECORDS_REPLY_STRINGS_COUNT) {
				string s2 = substring(cmd_records_reply[n1], 1024 * n2, 1024);
				WriteString(MSG_ONE, s2);
			} else {
				WriteString(MSG_ONE, "");
			}
		}

	} else {
		if(cmd != "status")
		if(cmd != "max")
		if(cmd != "monster")
		if(cmd != "scrag")
		if(cmd != "wraith")
		if(cmd != "gimme")
		if(cmd != "god")
		if(cmd != "notarget")
		if(cmd != "fly")
		if(cmd != "noclip")
		if(cmd != "give")
		if(cmd != "kill")
		if(cmd != "pause")
		if(cmd != "ping")
		if(cmd != "name")
		if(cmd != "color")
		if(cmd != "rate")
		if(cmd != "pmodel")
		if(cmd != "playermodel")
		if(cmd != "playerskin")
		if(cmd != "prespawn")
		if(cmd != "spawn")
		if(cmd != "begin")
		if(cmd != "pings")
		if(cmd != "sv_startdownload")
		if(cmd != "download")
		if(cmd != "rate_burstsize")
		{
			print("WARNING: Invalid clientcommand by ", self.netname, ": ", s, "\n");
			return;
		}
		if (cmd == "name") {
			string name = substring(s, argv_start_index(1), -1);
			if (self.retard > 0)
				return;

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
