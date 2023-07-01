/*
 * Protocol of online ban list:
 *
 * - Reporting a ban:
 *     GET g_ban_sync_uri?action=ban&hostname=...&ip=xxx.xxx.xxx&duration=nnnn&reason=...................
 *     (IP 1, 2, 3, or 4 octets, 3 octets for example is a /24 mask)
 * - Removing a ban:
 *     GET g_ban_sync_uri?action=unban&hostname=...&ip=xxx.xxx.xxx
 * - Querying the ban list
 *     GET g_ban_sync_uri?action=list&hostname=...&servers=xxx.xxx.xxx.xxx;xxx.xxx.xxx.xxx;...
 *     
 *     shows the bans from the listed servers, and possibly others.
 *     Format of a ban is ASCII plain text, four lines per ban, delimited by
 *     newline ONLY (no carriage return):
 *
 *     IP address (also 1, 2, 3, or 4 octets, delimited by dot)
 *     time left in seconds
 *     reason of the ban
 *     server IP that registered the ban
 */

float BAN_URIS_MAX = 16;

float BAN_URI_GET;


float(string ip, float bantime, string reason, float dosync) ban_insert;

void(string ip, float bantime, string reason) ban_online_list_send {
	string uri;
	float i, n;
	uri = strcat(     "?action=ban&hostname=", uri_escape(cvar_string("hostname")));
	uri = strcat(uri, "&ip=", uri_escape(ip));
	uri = strcat(uri, "&duration=", ftos(bantime));
	uri = strcat(uri, "&reason=", uri_escape(reason));
	n = tokenize_console(cvar_string("g_ban_sync_uri"));
	if (n >= BAN_URIS_MAX)
		n = BAN_URIS_MAX;

	for (i = 0; i < n; ++i)
		uri_get(strcat(argv(i), uri), URI_GET_DISCARD); // 0 = "discard" callback target
}

void(string ip) ban_online_list_send_unban {
	string uri;
	float i, n;
	uri = strcat(     "?action=unban&hostname=", uri_escape(cvar_string("hostname")));
	uri = strcat(uri, "&ip=", uri_escape(ip));
	n = tokenize_console(cvar_string("g_ban_sync_uri"));
	if (n >= BAN_URIS_MAX)
		n = BAN_URIS_MAX;

	for (i = 0; i < n; ++i)
		uri_get(strcat(argv(i), uri), URI_GET_DISCARD); // 0 = "discard" callback target
}

string ban_online_list_servers;
float ban_online_list_timeout;
float ban_online_list_request_waiting[BAN_URIS_MAX];

void(float id, float status, string data) ban_online_list_uri_callback {
	float n, i, j, l;
	string ip;
	float timeleft;
	string reason;
	string serverip;
	float syncinterval;
	string uri;
	id -= BAN_URI_GET;
	if (id >= BAN_URIS_MAX) {
		print("Received ban list for invalid ID\n");
		return;
	}
	tokenize_console(cvar_string("g_ban_sync_uri"));
	uri = argv(id);
	print("Received ban list from ", uri, ": ");
	if (ban_online_list_request_waiting[id] == 0) {
		print("rejected (unexpected)\n");
		return;
	}
	ban_online_list_request_waiting[id] = 0;
	if (time > ban_online_list_timeout) {
		print("rejected (too late)\n");
		return;
	}
	syncinterval = cvar("g_ban_sync_interval");
	if (syncinterval == 0) {
		print("rejected (syncing disabled)\n");
		return;
	}
	if (syncinterval > 0)
		syncinterval *= 60;
	
	if (status != 0) {
		print("error: status is ", ftos(status), "\n");
		return;
	}
	if (substring(data, 0, 1) == "<") {
		print("error: received HTML instead of a ban list: ");
		return;
	}
	if (strstrofs(data, "\r", 0) != -1) {
		print("error: received carriage returns: ");
		return;
	}
	if (data == "")
		n = 0;
	else
		n = tokenizebyseparator(data, "\n");

	if (math_mod(n, 4) != 0) {
		print("error: received invalid item count: ", ftos(n), "\n");
		return;
	}
	print("OK, ", ftos(n / 4), " items\n");
	for (i = 0; i < n; i += 4) {
		ip = argv(i);
		timeleft = stof(argv(i + 1));
		reason = argv(i + 2);
		serverip = argv(i + 3);
		timeleft -= 1.5 * cvar("g_ban_sync_timeout");
		if (timeleft < 0)
			continue;

		l = strlen(ip);
		for (j = 0; j < l; ++j)
			if (strstrofs("0123456789.", substring(ip, j, 1), 0) == -1) {
				print("Invalid character ", substring(ip, j, 1), " in IP address ", ip, ". Skipping this ban.\n");
				goto skip;
			}
		if (cvar("g_ban_sync_trusted_servers_verify"))
			if ((strstrofs(strcat(";", ban_online_list_servers, ";"), strcat(";", serverip, ";"), 0) == -1))
				continue;

		if (syncinterval > 0)
			timeleft = min(syncinterval + (ban_online_list_timeout - time) + 5, timeleft);
			// the ban will be prolonged on the next sync
			// or expire 5 seconds after the next timeout
		ban_insert(ip, timeleft, strcat("ban synced from ", serverip, " at ", uri), 0);
		print("Ban list syncing: accepted ban of ", ip, " by ", serverip, " at ", uri, ": ");
		print(reason, "\n");
:skip
	}
}

#define ban_compat_stub OnlineBanList_Think //compatibility with old save files
void(void) ban_compat_stub { remove(self); }

void(void) ban_online_list_think {
	float argc;
	string uri;
	float i, n;
	argc = tokenize_console(cvar_string("g_ban_sync_trusted_servers"));
	if (argc == 0)
		return;

	str_unzone_ifneeded(ban_online_list_servers);
	ban_online_list_servers = argv(0);
	for (i = 1; i < argc; ++i)
		ban_online_list_servers = strcat(ban_online_list_servers, ";", argv(i));

	ban_online_list_servers = str_zone_ifneeded(ban_online_list_servers);
	uri = strcat(     "?action=list&hostname=", uri_escape(cvar_string("hostname")));
	uri = strcat(uri, "&servers=", uri_escape(ban_online_list_servers));
	ban_online_list_timeout = time + cvar("g_ban_sync_timeout");
	n = tokenize_console(cvar_string("g_ban_sync_uri"));
	if (n >= BAN_URIS_MAX)
		n = BAN_URIS_MAX;

	for (i = 0; i < n; ++i) {
		if(ban_online_list_request_waiting[i])
			continue;

		ban_online_list_request_waiting[i] = 1;
		uri_get(strcat(argv(i), uri), BAN_URI_GET + i); // 1000 = "banlist" callback target
	}
	if(cvar("g_ban_sync_interval") > 0)
		self.nextthink = time + max(60, cvar("g_ban_sync_interval") * 60);
}

#define BAN_MAX 64
float ban_loaded;
string ban_ip[BAN_MAX];
float ban_expire[BAN_MAX];
float ban_count;

void(void) ban_save {
	string out;
	float i;

	if(!ban_loaded)
		return;

	// version of list
	out = "1";
	for(i = 0; i < ban_count; ++i)
	{
		if(time > ban_expire[i])
			continue;
		out = strcat(out, " ", ban_ip[i]);
		out = strcat(out, " ", ftos(ban_expire[i] - time));
	}
	if(strlen(out) <= 1) // no real entries
		cvar_set("g_banned_list", "");
	else
		cvar_set("g_banned_list", out);
}

float(float i) ban_delete {
	if (i < 0)
		return FALSE;

	if (i >= ban_count)
		return FALSE;

	if (ban_expire[i] == 0)
		return FALSE;

	if (ban_expire[i] > 0) {
		ban_online_list_send_unban(ban_ip[i]);
		strunzone(ban_ip[i]);
	}
	ban_expire[i] = 0;
	ban_ip[i] = "";
	ban_save();
	return TRUE;
}

void(void) ban_load {
	float i, n;
	for (i = 0; i < ban_count; ++i)
		ban_delete(i);

	ban_count = 0;
	ban_loaded = TRUE;
	n = tokenize_console(cvar_string("g_banned_list"));
	if (stof(argv(0)) == 1) {
		ban_count = (n - 1) / 2;
		for (i = 0; i < ban_count; ++i) {
			ban_ip[i] = strzone(argv(2*i+1));
			ban_expire[i] = time + stof(argv(2*i+2));
		}
	}
	if (cvar_string("g_ban_sync_uri") == "")
		return;

	if (cvar("g_ban_sync_interval") == 0) // < 0 is okay, it means "sync on level start only"
		return;

	entity e;
	e = spawn();
	e.classname = "bansyncer";
	e.think = ban_online_list_think;
	e.nextthink = time + 1;
}

void(void) ban_view {
	float i;
	string msg;
	for (i = 0; i < ban_count; ++i) {
		if(time > ban_expire[i])
			continue;
		msg = strcat("#", ftos(i), ": ");
		msg = strcat(msg, ban_ip[i], " is still banned for ");
		msg = strcat(msg, ftos(ban_expire[i] - time), " seconds");
		print(msg, "\n");
	}
}

float(entity client, float idx) ban_client_banned {
	float i, b, e;
	if (!ban_loaded)
		ban_load();

	if (!net_ip_parse(client.netaddress)) {
		if (client.netaddress != "local")
		if (client.netaddress != "null/botclient")
			print("ban_client_banned: cannot parse ip address: ", client.netaddress, "\n");

		return FALSE;
	}
	if (idx < 0) {
		b = 0;
		e = ban_count;
	} else {
		b = idx;
		e = idx + 1;
	}
	for (i = b; i < e; ++i) {
		string s;
		if (time > ban_expire[i])
			continue;

		s = ban_ip[i];
		if (net_ip_pref1 == s) return TRUE;
		if (net_ip_pref2 == s) return TRUE;
		if (net_ip_pref3 == s) return TRUE;
		if (net_ip_pref4 == s) return TRUE;
	}
	net_ip_clean();
	return FALSE;
}

float(entity client) ban_maybe_enforce {
	if (g_campaign) return FALSE;
	if (ban_client_banned(client, -1)) {
		string s;
		s = strcat("^1NOTE:^7 banned client ", client.netaddress, " just tried to enter\n");
		dropclient(client);
		bprint(s);
		return TRUE;
	}
	return FALSE;
}

string(float i, string reason) ban_enforce {
	string s;
	entity e;
	// Enforce our new ban
	s = "";
	FOR_EACH_REALCLIENT(e)
		if (ban_client_banned(e, i)) {
			if (reason != "") {
				if (s == "")
					reason = strcat(reason, ": affects ");
				else
					reason = strcat(reason, ", ");
				reason = strcat(reason, e.netname);
			}
			s = strcat(s, "^1NOTE:^7 banned client ", e.netname, "^7 has to go\n");
			dropclient(e);
		}
	bprint(s);
	return reason;
}

float(string ip, float bantime, string reason, float dosync) ban_insert {
	float i;
	float j;
	float bestscore;
	// already banned?
	for (i = 0; i < ban_count; ++i)
		if (ban_ip[i] == ip) {
			// prolong the ban
			if (time + bantime > ban_expire[i])
				ban_expire[i] = time + bantime;

			// and enforce
			reason = ban_enforce(i, reason);
			// and abort
			if(dosync)
				if(reason != "")
					if(substring(reason, 0, 1) != "~") // like IRC: unauthenticated banner
						ban_online_list_send(ip, bantime, reason);

			return FALSE;
		}
	// do we have a free slot?
	for (i = 0; i < ban_count; ++i)
		if (time > ban_expire[i])
			break;

	// no free slot? Then look for the one who would get unbanned next
	if (i >= BAN_MAX) {
		i = 0;
		bestscore = ban_expire[i];
		for (j = 1; j < ban_count; ++j) {
			if (ban_expire[j] < bestscore) {
				i = j;
				bestscore = ban_expire[i];
			}
		}
	}
	// if we replace someone, will we be banned longer than him (so long-term
	// bans never get overridden by short-term bans)
	if (i < ban_count)
	if (ban_expire[i] > time + bantime) {
		print(ip, " could not get banned due to no free ban slot\n");
		return FALSE;
	}
	// okay, insert our new victim as i
	ban_delete(i);
	ban_expire[i] = time + bantime;
	ban_ip[i] = strzone(ip);
	ban_count = max(ban_count, i + 1);
	ban_save();
	reason = ban_enforce(i, reason);
	// and abort
	if(dosync)
		if(reason != "")
			if(substring(reason, 0, 1) != "~") // like IRC: unauthenticated banner
				ban_online_list_send(ip, bantime, reason);

	return TRUE;
}

void(entity client, float bantime, float masksize, string reason) ban_kick {
	if (!net_ip_parse(client.netaddress)) {
		sprint(client, strcat("Kickbanned: ", reason, "\n"));
		dropclient(client);
		return;
	}
	// now ban him
	switch(masksize) {
	case 1:
		ban_insert(net_ip_pref1, bantime, reason, 1);
		break;
	case 2:
		ban_insert(net_ip_pref2, bantime, reason, 1);
		break;
	case 3:
		ban_insert(net_ip_pref3, bantime, reason, 1);
		break;
	default:
		ban_insert(net_ip_pref4, bantime, reason, 1);
		break;
	}
	net_ip_clean();
	/*
	 * not needed, as we enforce the ban in ban_insert anyway
	// and kick him
	sprint(client, strcat("Kickbanned: ", reason, "\n"));
	dropclient(client);
	 */
}

float(string command) ban_cmd {
	float argc;
	float bantime = 0;
	entity client;
	float entno;
	float masksize = 0;
	string reason;
	float reasonarg;
	if (g_campaign) return FALSE;
	argc = tokenize_console(command);
	if (argv(0) == "help") {
		print("  kickban # n m p reason - kickban player n for m seconds, using mask size p (1 to 4)\n");
		print("  ban ip m reason - ban an IP or range (incomplete IP, like 1.2.3) for m seconds\n");
		print("  bans - list all existing bans\n");
		print("  unban n - delete the entry #n from the bans list\n");
		return TRUE;
	}
	if (argv(0) == "kickban") {
		#define INITARG(c) reasonarg = c
		#define GETARG(v,d) if ((argc > reasonarg) && ((v = stof(argv(reasonarg))) != 0)) ++reasonarg; else v = d
		#define RESTARG(v) if (argc > reasonarg) v = substring(command, argv_start_index(reasonarg), strlen(command) - argv_start_index(reasonarg)); else v = ""
		if (argc >= 3) {
			entno = stof(argv(2));
			if (entno > client_max_count || entno < 1)
				return TRUE;

			client = edict_num(entno);
			INITARG(3);
			GETARG(bantime, cvar("g_ban_default_bantime"));
			GETARG(masksize, cvar("g_ban_default_masksize"));
			RESTARG(reason);
			ban_kick(client, bantime, masksize, reason);
			return TRUE;
		}
	} else if (argv(0) == "ban") {
		if (argc >= 2) {
			string ip;
			ip = argv(1);

			INITARG(2);
			GETARG(bantime, cvar("g_ban_default_bantime"));
			RESTARG(reason);
			ban_insert(ip, bantime, reason, 1);
			return TRUE;
		}
		#undef INITARG
		#undef GETARG
		#undef RESTARG
	} else if (argv(0) == "bans") {
		ban_view();
		return TRUE;
	} else if (argv(0) == "unban") {
		if(argc >= 2) {
			float who;
			who = stof(argv(1));
			ban_delete(who);
			return TRUE;
		}
	}
	return FALSE;
}

void(void) ban_init {
	if (g_campaign) return;
	ban_load();
	BAN_URI_GET = uri_register_handler(ban_online_list_uri_callback);
	float i;
	for (i = 1; i < BAN_URIS_MAX; i++)
		uri_register_handler(ban_online_list_uri_callback);
}
