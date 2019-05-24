void EffectIndexDump()
{
	float d;
	float fh;
	string s;

	d = db_create();

	print("begin of effects list\n");
	db_put(d, "TE_GUNSHOT", "1"); print("effect TE_GUNSHOT is ", ftos(particleeffectnum("TE_GUNSHOT")), "\n");
	db_put(d, "TE_GUNSHOTQUAD", "1"); print("effect TE_GUNSHOTQUAD is ", ftos(particleeffectnum("TE_GUNSHOTQUAD")), "\n");
	db_put(d, "TE_SPIKE", "1"); print("effect TE_SPIKE is ", ftos(particleeffectnum("TE_SPIKE")), "\n");
	db_put(d, "TE_SPIKEQUAD", "1"); print("effect TE_SPIKEQUAD is ", ftos(particleeffectnum("TE_SPIKEQUAD")), "\n");
	db_put(d, "TE_SUPERSPIKE", "1"); print("effect TE_SUPERSPIKE is ", ftos(particleeffectnum("TE_SUPERSPIKE")), "\n");
	db_put(d, "TE_SUPERSPIKEQUAD", "1"); print("effect TE_SUPERSPIKEQUAD is ", ftos(particleeffectnum("TE_SUPERSPIKEQUAD")), "\n");
	db_put(d, "TE_WIZSPIKE", "1"); print("effect TE_WIZSPIKE is ", ftos(particleeffectnum("TE_WIZSPIKE")), "\n");
	db_put(d, "TE_KNIGHTSPIKE", "1"); print("effect TE_KNIGHTSPIKE is ", ftos(particleeffectnum("TE_KNIGHTSPIKE")), "\n");
	db_put(d, "TE_EXPLOSION", "1"); print("effect TE_EXPLOSION is ", ftos(particleeffectnum("TE_EXPLOSION")), "\n");
	db_put(d, "TE_EXPLOSIONQUAD", "1"); print("effect TE_EXPLOSIONQUAD is ", ftos(particleeffectnum("TE_EXPLOSIONQUAD")), "\n");
	db_put(d, "TE_TAREXPLOSION", "1"); print("effect TE_TAREXPLOSION is ", ftos(particleeffectnum("TE_TAREXPLOSION")), "\n");
	db_put(d, "TE_TELEPORT", "1"); print("effect TE_TELEPORT is ", ftos(particleeffectnum("TE_TELEPORT")), "\n");
	db_put(d, "TE_LAVASPLASH", "1"); print("effect TE_LAVASPLASH is ", ftos(particleeffectnum("TE_LAVASPLASH")), "\n");
	db_put(d, "TE_SMALLFLASH", "1"); print("effect TE_SMALLFLASH is ", ftos(particleeffectnum("TE_SMALLFLASH")), "\n");
	db_put(d, "TE_FLAMEJET", "1"); print("effect TE_FLAMEJET is ", ftos(particleeffectnum("TE_FLAMEJET")), "\n");
	db_put(d, "EF_FLAME", "1"); print("effect EF_FLAME is ", ftos(particleeffectnum("EF_FLAME")), "\n");
	db_put(d, "TE_BLOOD", "1"); print("effect TE_BLOOD is ", ftos(particleeffectnum("TE_BLOOD")), "\n");
	db_put(d, "TE_SPARK", "1"); print("effect TE_SPARK is ", ftos(particleeffectnum("TE_SPARK")), "\n");
	db_put(d, "TE_PLASMABURN", "1"); print("effect TE_PLASMABURN is ", ftos(particleeffectnum("TE_PLASMABURN")), "\n");
	db_put(d, "TE_TEI_G3", "1"); print("effect TE_TEI_G3 is ", ftos(particleeffectnum("TE_TEI_G3")), "\n");
	db_put(d, "TE_TEI_SMOKE", "1"); print("effect TE_TEI_SMOKE is ", ftos(particleeffectnum("TE_TEI_SMOKE")), "\n");
	db_put(d, "TE_TEI_BIGEXPLOSION", "1"); print("effect TE_TEI_BIGEXPLOSION is ", ftos(particleeffectnum("TE_TEI_BIGEXPLOSION")), "\n");
	db_put(d, "TE_TEI_PLASMAHIT", "1"); print("effect TE_TEI_PLASMAHIT is ", ftos(particleeffectnum("TE_TEI_PLASMAHIT")), "\n");
	db_put(d, "EF_STARDUST", "1"); print("effect EF_STARDUST is ", ftos(particleeffectnum("EF_STARDUST")), "\n");
	db_put(d, "TR_ROCKET", "1"); print("effect TR_ROCKET is ", ftos(particleeffectnum("TR_ROCKET")), "\n");
	db_put(d, "TR_GRENADE", "1"); print("effect TR_GRENADE is ", ftos(particleeffectnum("TR_GRENADE")), "\n");
	db_put(d, "TR_BLOOD", "1"); print("effect TR_BLOOD is ", ftos(particleeffectnum("TR_BLOOD")), "\n");
	db_put(d, "TR_WIZSPIKE", "1"); print("effect TR_WIZSPIKE is ", ftos(particleeffectnum("TR_WIZSPIKE")), "\n");
	db_put(d, "TR_SLIGHTBLOOD", "1"); print("effect TR_SLIGHTBLOOD is ", ftos(particleeffectnum("TR_SLIGHTBLOOD")), "\n");
	db_put(d, "TR_KNIGHTSPIKE", "1"); print("effect TR_KNIGHTSPIKE is ", ftos(particleeffectnum("TR_KNIGHTSPIKE")), "\n");
	db_put(d, "TR_VORESPIKE", "1"); print("effect TR_VORESPIKE is ", ftos(particleeffectnum("TR_VORESPIKE")), "\n");
	db_put(d, "TR_NEHAHRASMOKE", "1"); print("effect TR_NEHAHRASMOKE is ", ftos(particleeffectnum("TR_NEHAHRASMOKE")), "\n");
	db_put(d, "TR_NEXUIZPLASMA", "1"); print("effect TR_NEXUIZPLASMA is ", ftos(particleeffectnum("TR_NEXUIZPLASMA")), "\n");
	db_put(d, "TR_GLOWTRAIL", "1"); print("effect TR_GLOWTRAIL is ", ftos(particleeffectnum("TR_GLOWTRAIL")), "\n");
	db_put(d, "SVC_PARTICLE", "1"); print("effect SVC_PARTICLE is ", ftos(particleeffectnum("SVC_PARTICLE")), "\n");

	fh = fopen("effectinfo.txt", FILE_READ);
	while((s = fgets(fh)))
	{
		tokenize(s); // tokenize_console would hit the loop counter :(
		if(argv(0) == "effect")
		{
			if(db_get(d, argv(1)) != "1")
			{
				if(particleeffectnum(argv(1)) >= 0)
					print("effect ", argv(1), " is ", ftos(particleeffectnum(argv(1))), "\n");
				db_put(d, argv(1), "1");
			}
		}
	}
	print("end of effects list\n");

	db_close(d);
}

void make_mapinfo_Think()
{
	if(MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 1))
	{
		print("Done rebuiling mapinfos.\n");
		MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		remove(self);
	}
	else
	{
		self.think = make_mapinfo_Think;
		self.nextthink = time;
	}
}

void GameCommand(string command)
{
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
		print("  effectindexdump\n");
		print("  cvar_changes\n");
		print("  find classname\n");
		GameCommand_Vote("help", world);
		GameCommand_Ban("help");
		GameCommand_Generic("help");
		IP2C_GameCommand("help", argc);
		return;
	}

	if(GameCommand_Vote(command, world))
		return;

	if(GameCommand_Ban(command))
		return;

	if(GameCommand_Generic(command))
		return;

	if (GameHookChain_GameCommandHandle(cmd, argc))
		return;

	if(cmd == "printstats")
	{
		DumpStats(FALSE);
		return;
	}

	if(cmd == "make_mapinfo")
	{
		e = spawn();
		e.classname = "make_mapinfo";
		e.think = make_mapinfo_Think;
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
		if(entno <= maxclients)
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
		db_save(ServerProgsDB, argv(1));
		print("DB saved.\n");
		return;
	}

	if(cmd == "dumpdb") if(argc == 2)
	{
		db_dump(ServerProgsDB, argv(1));
		print("DB dumped.\n");
		return;
	}

	if(cmd == "loaddb") if(argc == 2)
	{
		db_close(ServerProgsDB);
		ServerProgsDB = db_load(argv(1));
		print("DB loaded.\n");
		return;
	}
	if (cmd == "nospectators")
	{
		blockSpectators = 1;
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
	if (cmd == "lockteams")
	{
		if(teamplay)
		{
			lockteams = 1;
			bprint("^1The teams are now locked.\n");
		}
		else
			bprint("That command can only be used in a team-based gamemode.\n");
		return;
	}
	if (cmd == "unlockteams")
	{
		if(teamplay)
		{
			lockteams = 0;
			bprint("^1The teams are now unlocked.\n");
		}
		else
			bprint("That command can only be used in a team-based gamemode.\n");
		return;
	}
	if (cmd == "movetoteam") if(argc == 3)
	{
		entno = stof(argv(1));
		client = world;
		if(entno <= maxclients)
			client = edict_num(entno);
		if(client.flags & FL_CLIENT)
		{
			float lt;
			lt = lockteams;
			lockteams = 0;

			self = client;
			SV_ParseClientCommand(strcat("selectteam ", argv(2)));

			lockteams = lt;
		}
		else
			print("Client not found\n");
		return;
	}
	if (cmd == "teamstatus")
	{
		scores_nice_print(world);
		return;
	}
	if (cmd == "allready")
	{
		ReadyRestart();
		return;
	}
	if (cmd == "effectindexdump")
	{
		EffectIndexDump();
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
	if (cmd == "records")
	{
		strunzone(records_reply);
		records_reply = strzone(getrecords());
		print(records_reply);
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

			tracebox(start, PL_MIN, PL_MAX, end, MOVE_NOMONSTERS, world);
			if(!trace_startsolid)
			{
				p = trace_endpos;
				tracebox(p, PL_MIN, PL_MAX, p, MOVE_NOMONSTERS, world);
				if(trace_startsolid)
				{
					rint(42); // do an engine breakpoint on VM_rint so you can get the trace that errnoeously returns startsolid
					tracebox(start, PL_MIN, PL_MAX, end, MOVE_NOMONSTERS, world);
					tracebox(p, PL_MIN, PL_MAX, p, MOVE_NOMONSTERS, world);

					// how much do we need to back off?
					safe = 1;
					unsafe = 0;
					for(;;)
					{
						pos = p * (1 - (safe + unsafe) * 0.5) + start * ((safe + unsafe) * 0.5);
						tracebox(pos, PL_MIN, PL_MAX, pos, MOVE_NOMONSTERS, world);
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

					tracebox(p, PL_MIN + '0.1 0.1 0.1', PL_MAX - '0.1 0.1 0.1', p, MOVE_NOMONSTERS, world);
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
	if (teamplay)
	if (cmd == "shuffleteams")
	{
		float t = COLOR_TEAM4;
		autoswap_last_best = world;
		FOR_EACH_TEAMPLAYER(plr)
		{
			teams_check_allowed(plr);
			if (t == COLOR_TEAM4)
				t = COLOR_TEAM1;
			else if (t == COLOR_TEAM1)
				t = COLOR_TEAM2;
			else if (t == COLOR_TEAM2)
				t = COLOR_TEAM3;
			else if (t == COLOR_TEAM3)
				t = COLOR_TEAM4;

			for (i = 0; i < 2; i++) {
				if (t == COLOR_TEAM1 && c1 < 0)
					t = COLOR_TEAM2;

				if (t == COLOR_TEAM2 && c2 < 0)
					t = COLOR_TEAM3;

				if (t == COLOR_TEAM3 && c3 < 0)
					t = COLOR_TEAM4;

				if (t == COLOR_TEAM4 && c4 < 0)
					t = COLOR_TEAM1;
			}
			if (t != plr.team) {
				player_to_spec(plr);
				SetPlayerTeam(plr, TeamColorSkin(t), TeamColorSkin(t), FALSE);
				e = self;
				self = plr;
				spectator_to_player();
				self = e;
				if (clienttype(plr) == CLIENTTYPE_REAL)
					centerprint(plr, strcat("You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(t)));
			}
		}
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
