float vote_was_rejected;
string vote_called_vote;
string vote_called_vote_display;
float vote_called_master;
entity vote_caller;
float vote_finished;
.float vote_master;
.float vote_next;
.float vote_vote;

float(string cmd) vote_check_nasty;
entity(string vote, string cmd, entity caller) vote_kick_victim_get;
float(string s, entity e) vote_cmd;
void(entity e) vote_help;
string(entity e) vote_netname;
string(string m, entity e) vote_validate_map;
string(string s, float tokens) vote_parse;
float(string vote, string cmd) vote_allowed;
void(void) vote_accept;
void(void) vote_reject;
void(void) vote_timeout;
void(entity stopper) vote_stop;
void(void) vote_count;
entity vote_note;
float yescount;
float nocount;
float yescount_target;
float nocount_target;
float realplayeryescount;
float realplayernocount;

string vote_note_message1;
string vote_note_bar;

string sv_announcer_extra_vote_now;
string sv_announcer_extra_vote_failed;
string sv_announcer_extra_vote_passed;

void(void) vote_note_clear {
	if (vote_note_message1 == "")
		return;

	strunzone(vote_note_bar);
	vote_note_message1 = "";
}

void(void) vote_note_update {
	if not(vote_note)
		return;

	vote_note_clear();
	vote_note_message1 = "^2A vote has been called for ^1{1}^7\n^0[{2}^0]\n";
	float i, n;
	vote_note_bar = "^2";
	n = yescount;
	for (i = 0; i < n; i++)
		vote_note_bar = strcat(vote_note_bar, "Y");

	n = yescount_target - yescount;
	for (i = 0; i <= n; i++)
		vote_note_bar = strcat(vote_note_bar, ".");

	vote_note_bar = strcat(vote_note_bar, "^1");
	n = nocount_target - nocount;
	for (i = 0; i <= n; i++)
		vote_note_bar = strcat(vote_note_bar, ".");

	n = nocount;
	for (i = 0; i < n; i++)
		vote_note_bar = strcat(vote_note_bar, "N");

	//s = strcat(s, "^0[", vote_note_bar, "^0]");
	vote_note_bar = strzone(vote_note_bar);
	vote_note.SendFlags = 1;
}

void(void) vote_note_message {
	self.message = vote_note_message1;
	if (other.vote_vote > 0)
		self.message = strcat(self.message, "Your vote: ^2Yes");
	else if (other.vote_vote < 0)
		self.message = strcat(self.message, "Your vote: ^1No");
	else
		self.message = strcat(self.message, "^3{vyes} ^2Yes   ^3{vno} ^1No");

	self.target = vote_called_vote_display;
	self.target2 = vote_note_bar;
}

float(string cmd) vote_check_nasty {
	if (strstrofs(cmd, ";", 0) >= 0)
		return TRUE;

	if (strstrofs(cmd, "\n", 0) >= 0)
		return TRUE;

	if (strstrofs(cmd, "\r", 0) >= 0)
		return TRUE;

	if (strstrofs(cmd, "$", 0) >= 0)
		return TRUE;

	return FALSE;
}

string vote_kick_victim_newcommand;
string vote_kick_victim_reason;

entity(string vote, string cmd, entity caller) vote_kick_victim_get {
	float tokens;
	string ns;
	entity e;
	string reason;
	tokens = tokenize_console(vote);
	ns = "";
	e = client_entity_from_argv(tokens, 1);
	if (e) {
		if (client_entity_from_argv_firsttoken < tokens)
			vote_kick_victim_reason = substring(vote, argv_start_index(client_entity_from_argv_firsttoken), argv_end_index(-1) - argv_start_index(client_entity_from_argv_firsttoken));
		else
			vote_kick_victim_reason = "";

		reason = "";
		if (cmd != "vdo" || vote_kick_victim_reason == "")
			reason = "~"; // by convention, ~ prefixes a "unverified" kickban which will not be networked

		if (substring(vote_kick_victim_reason, 0, 1) == "~") {
			reason = "~";
			vote_kick_victim_reason = substring(vote_kick_victim_reason, 1, strlen(vote_kick_victim_reason) - 1);
		}
		if (caller)
			reason = strcat(reason, "player ", strdecolorize(caller.netname));
		else
			reason = strcat(reason, "console vote");

		if (vote_kick_victim_reason != "")
			reason = strcat(reason, ": ", strdecolorize(vote_kick_victim_reason));

		if not(cvar_value_issafe(reason))
			reason = uri_escape(reason);

		vote_kick_victim_newcommand = strcat(argv(0), " # ", ftos(num_for_edict(e)));
		if (argv(0) == "kickban") {
			vote_kick_victim_newcommand = strcat(vote_kick_victim_newcommand, " ", cvar_string("g_ban_default_bantime"), " ", cvar_string("g_ban_default_masksize"), " ", reason);
		} else if (argv(0) == "kick") {
			vote_kick_victim_newcommand = strcat(vote_kick_victim_newcommand, " ", reason);
		}
		return e;
	}
	cmd_print_to(caller, strcat("Usage: ", cmd, " ", argv(0), " #playernumber (as in \"status\")\n"));
	return world;
}

string vote_remap_display;
string vote_remap_vote;
float(string vote, string cmd, entity e) vote_remap {
	float vote_argc;
	entity victim;
	vote_argc = tokenize_console(vote);
	if (!vote_allowed(argv(0), cmd))
		return FALSE;

	// vote_allowed tokenizes!
	vote_argc = tokenize_console(vote);
	// remap chmap to gotomap (forces intermission)
	if (vote_argc < 2)
		if (argv(0) == "chmap" || argv(0) == "gotomap" || argv(0) == "kick" || argv(0) == "kickban") // won't work without arguments
			return FALSE;

	if (argv(0) == "chmap") {
		vote = strcat("gotomap ", substring(vote, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
		vote_argc = tokenize_console(vote);
	}
	if (argv(0) == "gotomap") {
		if (!(vote = vote_validate_map(substring(vote, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), e)))
			return FALSE;

		vote = strcat("gotomap ", vote);
		vote_argc = tokenize_console(vote); // vote_validate_map may have done some stuff to it
	}
	// make kick and kickban votes a bit nicer (and reject them if formatted badly)
	if (argv(0) == "kick" || argv(0) == "kickban") {
		if (!(victim = vote_kick_victim_get(vote, cmd, e)))
			return FALSE;
		vote_remap_vote = vote_kick_victim_newcommand;
		vote_remap_display = strcat("^1", vote, " (^7", victim.netname, "^1): ", vote_kick_victim_reason);
	} else {
		vote_remap_vote = vote;
		vote_remap_display = strzone(strcat("^1", vote));
	}
	return TRUE;
}

float(string s, entity e) vote_cmd {
	float argc;
	argc = tokenize_console(s);
	if (argv(0) == "help") {
		cmd_print_to(e, "  vote COMMANDS ARGUMENTS. See 'vhelp' for more info.");
		return TRUE;
	} else if (argv(0) == "vote") {
		if (e && !(e.flags & FL_CLIENT)) {
			cmd_print_to(e, "^1You can't use vote in unconnected state!");
			return TRUE;
		}
		if (g_campaign) {
			cmd_print_to(e, "^1You can't use vote in campaing mode!");
			return TRUE;
		}
		if (argv(1) == "") {
			cmd_print_to(e, "^1You have to supply a vote command. See 'vhelp' for more info.");
		} else if (argv(1) == "help") {
			vote_help(e);
		} else if (argv(1) == "status") {
			if (vote_called) {
				cmd_print_to(e, strcat("^7Vote for ", vote_called_vote_display, "^7 called by ^7", vote_netname(vote_caller), "^7."));
			} else {
				cmd_print_to(e, "^1No vote called.");
			}
		} else if (argv(1) == "call") {
			if (!e || cvar("sv_vote_call")) {
				if (cvar("sv_vote_nospectators") && e && e.classname != "player") {
					cmd_print_to(e, "^1Error: Only players can call a vote."); // TODO invent a cvar name for allowing votes by spectators during warmup anyway
				}
				else if (timeout_status) { //don't allow a vote call during a timeout
					cmd_print_to(e, "^1Error: You can not call a vote while a timeout is active.");
				}
				else if (vote_called) {
					cmd_print_to(e, "^1There is already a vote called.");
				}
				else if (e.abuser > 0) {
					cmd_print_to(e, "^1Error: You can not call a vote");
				} else {
					string vote;
					vote = vote_parse(s, argc);
					if (vote == "") {
						cmd_print_to(e, "^1Your vote is empty. See 'vhelp' for more info.");
					} else if (e
						&& time < e.vote_next) {
							cmd_print_to(e, strcat("^1You have to wait ^2", ftos(e.vote_next - time), "^1 seconds before you can again call a vote."));
					} else if (vote_check_nasty(vote)) {
						cmd_print_to(e, "Syntax error in command. See 'vhelp' for more info.");
					} else if (vote_remap(vote, "vcall", e)) {
						vote_called_vote = strzone(vote_remap_vote);
						vote_called_vote_display = strzone(vote_remap_display);
						vote_called = TRUE;
						vote_note = noteline_new(vote_note_message);
						vote_called_master = FALSE;
						vote_finished = time + cvar("sv_vote_timeout");
						if (sv_announcer_extra_vote_now != "")
							sound_play2all(sv_announcer_extra_vote_now);

						vote_caller = e; // remember who called the vote
						if (e) {
							e.vote_vote = 1; // of course you vote yes
							e.vote_next = time + cvar("sv_vote_wait");
						}
						print_all(PRINT_CHAT, "^2* ^3{1}^2 calls a vote for {2}", vote_netname(vote_caller), vote_called_vote_display, "");
						vote_count(); // needed if you are the only one
					} else {
						cmd_print_to(e, "^1This vote is not ok. See 'vhelp' for more info.");
					}
				}
			} else {
				cmd_print_to(e, "^1Vote calling is NOT allowed.");
			}
		} else if (argv(1) == "stop") {
			if (!vote_called) {
				cmd_print_to(e, "^1No vote called.");
			} else if (e == vote_caller) { // the vote_caller can stop a vote
				vote_stop(e);
			} else if (!e) { // server admin / console can too
				vote_stop(e);
			} else if (e.vote_master) { // masters can too
				vote_stop(e);
			} else {
				cmd_print_to(e, "^1You are not allowed to stop that Vote.");
			}
		} else if (argv(1) == "master") {
			if (cvar("sv_vote_master")) {
				if (vote_called) {
					cmd_print_to(e, "^1There is already a vote called.");
				} else {
					vote_called = TRUE;
					vote_called_master = TRUE;
					vote_called_vote = strzone("XXX");
					vote_called_vote_display = strzone("^3master");
					vote_note = noteline_new(vote_note_message);
					vote_finished = time + cvar("sv_vote_timeout");
					if (sv_announcer_extra_vote_now != "")
						sound_play2all(sv_announcer_extra_vote_now);

					vote_caller = e; // remember who called the vote
					if (e) {
						e.vote_vote = 1; // of course you vote yes
						e.vote_next = time + cvar("sv_vote_wait");
					}
					print_all(PRINT_CHAT, "^2* ^3{1}^2 calls a vote to become ^3master^2", vote_netname(vote_caller), "", "");
					vote_count(); // needed if you are the only one
				}
			} else {
				cmd_print_to(e, "^1Vote to become master is NOT allowed.");
			}
		} else if (argv(1) == "do") {
			if (!e || e.vote_master) {
				string dovote;
				dovote = vote_parse(s, argc);
				if (dovote == "") {
					cmd_print_to(e, "^1Your command was empty. See 'vhelp' for more info.");
				} else if (vote_check_nasty(dovote)) {
					cmd_print_to(e, "Syntax error in command. See 'vhelp' for more info.");
				} else if (vote_remap(dovote, "vdo", e)) { // strcat seems to be necessary
					print_all(PRINT_CHAT, "^2* ^3{1}^2 used his ^3master^2 status to do ^2{2}^2", vote_netname(e), vote_remap_display, "");
					localcmd(strcat(vote_remap_vote, "\n"));
				} else {
					cmd_print_to(e, "^1This command is not ok. See 'vhelp' for more info.");
				}
			} else {
				cmd_print_to(e, "^1You are NOT a master.  You might need to login or vote to become master first. See 'vhelp' for more info.");
			}
		} else if (argv(1) == "login") {
			string masterpwd;
			masterpwd = cvar_string("sv_vote_master_password");
			if (masterpwd != "") {
				float granted;
				granted = (masterpwd == argv(2));
				if (e)
					e.vote_master = granted;
				if (granted) {
					print("Accepted master login from ", vote_netname(e), "\n");
					print_all(PRINT_CHAT, "^2* ^3{1}^2 logged in as ^3master^2", vote_netname(e), "", "");
				} else
					print("REJECTED master login from ", vote_netname(e), "\n");
			}
			else
				cmd_print_to(e, "^1Login to become master is NOT allowed.");
		} else if (argv(1) == "yes") {
			if (!vote_called) {
				cmd_print_to(e, "^1No vote called.");
			} else if (!e) {
				cmd_print_to(e, "^1You can't vote from the server console.");
			} else if (e.vote_vote == 0
				  || cvar("sv_vote_change")) {
				print_to(e, PRINT_CHAT, "^1You accepted the vote.", "", "", "");
				e.vote_vote = 1;
				if (!cvar("sv_vote_singlecount")) {
					vote_count();
				}
			} else {
				print_to(e, PRINT_CHAT, "^1You have already voted.", "", "", "");
			}
		} else if (argv(1) == "no") {
			if (!vote_called) {
				cmd_print_to(e, "^1No vote called.");
			} else if (!e) {
				cmd_print_to(e, "^1You can't vote from the server console.");
			} else if (e.vote_vote == 0
				  || cvar("sv_vote_change")) {
				print_to(e, PRINT_CHAT, "^1You rejected the vote.", "", "", "");
				e.vote_vote = -1;
				if (!cvar("sv_vote_singlecount")) {
					vote_count();
				}
			} else {
				print_to(e, PRINT_CHAT, "^1You have already voted.", "", "", "");
			}
		} else if (argv(1) == "abstain" || argv(1) == "dontcare") {
			if (!vote_called) {
				cmd_print_to(e, "^1No vote called.");
			} else if (!e) {
				cmd_print_to(e, "^1You can't vote from the server console.");
			} else if (e.vote_vote == 0
				  || cvar("sv_vote_change")) {
				cmd_print_to(e, "^1You abstained from your vote.");
				e.vote_vote = -2;
				if (!cvar("sv_vote_singlecount")) {
					vote_count();
				}
			} else {
				print_to(e, PRINT_CHAT, "^1You have already voted.", "", "", "");
			}
		} else {
			// ignore this?
			cmd_print_to(e, "^1Unknown vote command.");
		}
		return TRUE;
	}
	return FALSE;
}

void(entity e) vote_help {
	string vmasterdis = "";
	if (!cvar("sv_vote_master")) {
		vmasterdis = " ^1(disabled)";
	}
	string vlogindis = "";
	if ("" == cvar_string("sv_vote_master_password")) {
		vlogindis = " ^1(disabled)";
	}
	string vcalldis = "";
	if (!cvar("sv_vote_call")) {
		vcalldis = " ^1(disabled)";
	}
	cmd_print_to(e, "^7You can use voting with \"^2cmd vote help^7\" \"^2cmd vote status^7\" \"^2cmd vote call ^3COMMAND ARGUMENTS^7\" \"^2cmd vote stop^7\" \"^2cmd vote master^7\" \"^2cmd vote login^7\" \"^2cmd vote do ^3COMMAND ARGUMENTS^7\" \"^2cmd vote yes^7\" \"^2cmd vote no^7\" \"^2cmd vote abstain^7\" \"^2cmd vote dontcare^7\".");
	cmd_print_to(e, "^7Or if your version is up to date you can use these aliases \"^2vhelp^7\" \"^2vstatus^7\" \"^2vcall ^3COMMAND ARGUMENTS^7\" \"^2vstop^7\" \"^2vmaster^7\" \"^2vlogin^7\" \"^2vdo ^3COMMAND ARGUMENTS^7\" \"^2vyes^7\" \"^2vno^7\" \"^2abstain^7\" \"^2vdontcare^7\".");
	cmd_print_to(e, "^7\"^2help^7\" shows this info.");
	cmd_print_to(e, "^7\"^2status^7\" shows if there is a vote called and who called it.");
	cmd_print_to(e, strcat("^7\"^2call^7\" is used to call a vote. See the list of allowed commands.", vcalldis, "^7"));
	cmd_print_to(e, "^7\"^2stop^7\" can be used by the vote caller or an admin to stop a vote and maybe correct it.");
	cmd_print_to(e, strcat("^7\"^2master^7\" call a vote to become master who can execute commands without a vote", vmasterdis, "^7"));
	cmd_print_to(e, strcat("^7\"^2login^7\" login to become master who can execute commands without a vote.", vlogindis, "^7"));
	cmd_print_to(e, "^7\"^2do^7\" executes a command if you are a master. See the list of allowed commands.");
	cmd_print_to(e, "^7\"^2yes^7\", \"^2no^7\", \"^2abstain^7\" and \"^2dontcare^7\" to make your vote.");
	cmd_print_to(e, "^7If enough of the players vote yes the vote is accepted.");
	cmd_print_to(e, "^7If enough of the players vote no the vote is rejected.");
	cmd_print_to(e, strcat("^7If neither the vote will timeout after ", cvar_string("sv_vote_timeout"), "^7 seconds."));
	cmd_print_to(e, "^7You can call a vote for or execute these commands:");
	cmd_print_to(e, strcat("^3", cvar_string("sv_vote_commands"), "^7 and maybe further ^3arguments^7"));
}

string vote_netname(entity e) {
	if (e) {
		return strcat(e.netname, "^0#", ftos(num_for_edict(e)));
	} else {
		if (cvar_string("sv_adminnick") != "") {
			return cvar_string("sv_adminnick");
		} else {
			return cvar_string("hostname");
		}
	}
}

string(string m, entity e) vote_validate_map {
	m = map_info_fix_name(m);
	if (!m) {
		cmd_print_to(e, "This map is not available on this server.");
		return NULL;
	}
	if (!cvar("sv_vote_override_mostrecent"))
		if (map_is_recent(m)) {
			cmd_print_to(e, "This server does not allow for recent maps to be played again. Please be patient for some rounds.");
			return NULL;
		}
	if not(map_info_get_game_types(m) & (map_info_type_from_game_type(game_type_current()) | game_type_vote_mapinfo_mask)) {
		cmd_print_to(e, strcat("^1Invalid mapname, \"^3", m, "^1\" does not support the current game mode."));
		return NULL;
	}
	return m;
}


void(void) vote_think {
	if (vote_finished > 0) // a vote was called
	if (time > vote_finished) {
		vote_count();
	}
}

string(string all, float argc) vote_parse {
	if (argc < 3)
		return "";
	return substring(all, argv_start_index(2), argv_end_index(-1) - argv_start_index(2));
}

float(string votecommand, string list) vote_command_in_list {
	string l;
	l = strcat(" ", list, " ");
	
	if (strstrofs(l, strcat(" ", votecommand, " "), 0) >= 0)
		return TRUE;
	
	// if gotomap is allowed, chmap is too, and vice versa
	if (votecommand == "gotomap")
		if (strstrofs(l, " chmap ", 0) >= 0)
			return TRUE;
	if (votecommand == "chmap")
		if (strstrofs(l, " gotomap ", 0) >= 0)
			return TRUE;
	
	return FALSE;
}

float(string votecommand, string cmd) vote_allowed {
	if (vote_command_in_list(votecommand, cvar_string("sv_vote_commands")))
		return TRUE;

	if (cmd == "vdo") {
		if (vote_command_in_list(votecommand, cvar_string("sv_vote_master_commands")))
			return TRUE;
	} else {
		if (vote_command_in_list(votecommand, cvar_string("sv_vote_only_commands")))
			return TRUE;
	}
	return FALSE;
}

void(void) vote_reset {
	entity player;
	CLIENT_FOR_EACH(player) {
		player.vote_vote = 0;
	}
	if (vote_called) {
		strunzone(vote_called_vote);
		strunzone(vote_called_vote_display);
	}
	vote_called = FALSE;
	vote_called_master = FALSE;
	vote_finished = 0;
	vote_note_clear();
	if (vote_note) {
		remove(vote_note);
		vote_note = world;
	}
}

void(void) vote_accept {
	print_all(PRINT_CHAT, "^2* ^3{1}^2's vote for ^1{2}^2 was accepted", vote_netname(vote_caller), vote_called_vote_display, "");
	if (vote_called_master) {
		if (vote_caller) {
			vote_caller.vote_master = 1;
		}
	} else {
		localcmd(strcat(vote_called_vote, "\n"));
	}
	if (vote_caller) {
		vote_caller.vote_next = 0; // people like your votes,
					  // no wait for next vote
	}
	vote_reset();
	if (sv_announcer_extra_vote_passed)
		sound_play2all(sv_announcer_extra_vote_passed);
}

void(void) vote_reject {
	print_all(PRINT_CHAT, "^2* ^3{1}^2's vote for {2}^2 was rejected", vote_netname(vote_caller), vote_called_vote_display, "");
	vote_was_rejected = TRUE;
	vote_reset();
	if (sv_announcer_extra_vote_passed)
		sound_play2all(sv_announcer_extra_vote_failed);
}

void(void) vote_timeout {
	print_all(PRINT_CHAT, "^2* ^3{1}^2's vote for {2}^2 timed out", vote_netname(vote_caller), vote_called_vote_display, "");
	vote_reset();
	if (sv_announcer_extra_vote_passed)
		sound_play2all(sv_announcer_extra_vote_failed);
}

void(entity stopper) vote_stop {
	print_all(PRINT_CHAT, "^2* ^3{1}^2 stopped ^3{2}^2's vote", vote_netname(stopper), vote_netname(vote_caller), "");
	if (stopper == vote_caller) {
		// no wait for next vote so you can correct your vote
		if (vote_caller) {
			vote_caller.vote_next = time + cvar("sv_vote_stop");
		}
	}
	vote_reset();
}

void(float abstaincount, float notvoters, float mincount, string result) vote_spam {
	if (mincount >= 0) {
		print_all_long(PRINT_CHAT, "^2* vote results: ^1{1}^2:^1{2}^2 (^1{3}^2 needed), ^1{4}^2 didn't care, ^1{5}^2 didn't vote", ftos(yescount), ftos(nocount), ftos(ceil(mincount)), ftos(floor(abstaincount)), ftos(ceil(notvoters)), "");
	} else {
		print_all_long(PRINT_CHAT, "^2* vote results: ^1{1}^2:^1{2}^2, ^1{3}^2 didn't care, ^1{4}^2 didn't have to vote", ftos(yescount), ftos(nocount), ftos(floor(abstaincount)), ftos(ceil(notvoters)), "", "");
	}
}

float(entity pl, float allowed_dups) vote_check_dup_ip {
	entity e;
	CLIENT_FOR_EACH_REAL(e)
		if (e.vote_vote == pl.vote_vote)
		if (e.netaddress == pl.netaddress) {
			if (allowed_dups <= 0)
				return TRUE;

			if (e == pl)
				break;

			allowed_dups = allowed_dups - 1;
		}
	return FALSE;
}

void(void) vote_count {
	float playercount;
	playercount = 0;
	yescount = 0;
	nocount = 0;
	float abstaincount;
	abstaincount = 0;
	entity player;
	//same for real players
	float realplayercount;
	float realplayerabstaincount;
	realplayercount = realplayernocount = realplayerabstaincount = realplayeryescount = 0;
	float allowed_dups = cvar("sv_vote_limit_from_single_address");
	CLIENT_FOR_EACH_REAL(player) {
		if (allowed_dups > 0)
		if (player != vote_caller)
		if (vote_check_dup_ip(player, allowed_dups))
			continue;

		if (player.vote_vote == -1) {
			++nocount;
		} else if (player.vote_vote == 1) {
			++yescount;
		} else if (player.vote_vote == -2 || (time > vote_finished && player.classname == "spectator" && player.team < 0)) {
			++abstaincount;
		}
		++playercount;
		//do the same for real players
		if (player.classname == "player") {
			if (player.vote_vote == -1) {
				++realplayernocount;
			} else if (player.vote_vote == 1) {
				++realplayeryescount;
			} else if (player.vote_vote == -2) {
				++realplayerabstaincount;
			}
			++realplayercount;
		}
	}
	//in tournament mode, if we have at least one player then don't make the vote dependent on spectators (so specs don't have to press F1)
	if (cvar("sv_vote_nospectators"))
	if (realplayercount > 0) {
		yescount = realplayeryescount;
		nocount = realplayernocount;
		abstaincount = realplayerabstaincount;
		playercount = realplayercount;
	}
	if (time > vote_finished) {
		float ignorecount;
		ignorecount = playercount - nocount - yescount - abstaincount;
		abstaincount += ignorecount * bound(0, cvar("sv_vote_players_auto_abstain"), 1);
	}
	if (vote_called_master
	   && playercount == 1) {
		// if only one player is on the server becoming vote
		// master is not allowed.  This could be used for
		// trolling or worse. 'self' is the user who has
		// called the vote because this function is called
		// by cmd_client. Maybe all voting should
		// be disabled for a single player?
		cmd_print_to(vote_caller, "^1You are the only player on this server so you can not become vote master.");
		if (vote_caller) {
			vote_caller.vote_next = 0;
		}
		vote_reset();
	} else {
		float votefactor, simplevotefactor;
		votefactor = bound(0.5, cvar("sv_vote_majority_factor"), 0.999);
		simplevotefactor = cvar("sv_vote_simple_majority_factor");
		yescount_target = (playercount - abstaincount) * votefactor;
		nocount_target = (playercount - abstaincount) * (1 - votefactor);
		if (yescount > yescount_target) {
			vote_spam(abstaincount, playercount - yescount - nocount - abstaincount, -1, "yes");
			vote_accept();
		} else if (nocount >= nocount_target) { // that means, yescount cannot reach minyes any more
			vote_spam(abstaincount, playercount - yescount - nocount - abstaincount, -1, "no");
			vote_reject();
		} else if (time > vote_finished) {
			if (simplevotefactor) {
				string result;
				simplevotefactor = bound(votefactor, simplevotefactor, 0.999);
				if (yescount > (yescount + nocount) * simplevotefactor)
					result = "yes";
				else if (yescount + nocount > 0)
					result = "no";
				else
					result = "timeout";
				vote_spam(abstaincount, playercount - yescount - nocount - abstaincount, floor(min((playercount - abstaincount) * votefactor, (yescount + nocount) * simplevotefactor)) + 1, result);
				if (result == "yes")
					vote_accept();
				else if (result == "no")
					vote_reject();
				else
					vote_timeout();
			} else {
				vote_spam(abstaincount, playercount - yescount - nocount - abstaincount, floor((playercount - abstaincount) * votefactor) + 1, "timeout");
				vote_timeout();
			}
		}
	}
	vote_note_update();
}

void(void) vote_client_disconnect {
	if (vote_caller == self)
		vote_stop(vote_caller);
}

void(void) vote_client_connect {
	if (vote_was_rejected)
		self.vote_next = time + cvar("sv_vote_wait");
	else
		self.vote_next = cvar("sv_vote_delay");
}

void(void) vote_init {
	CVAR_CACHE_STR(sv_announcer_extra_vote_now);
	CVAR_CACHE_STR(sv_announcer_extra_vote_failed);
	CVAR_CACHE_STR(sv_announcer_extra_vote_passed);
	precache_sound(sv_announcer_extra_vote_now);
	precache_sound(sv_announcer_extra_vote_failed);
	precache_sound(sv_announcer_extra_vote_passed);
}
