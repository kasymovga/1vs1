float URI_GET_RADIO;
float sv_radio;
float sv_radio_announce;
float sv_radio_preload;
float sv_radio_queue_autofill;
float sv_radio_queue_autofill_retry;
float sv_radio_queue_advanceat;
float sv_radio_queue_autofill_retry;
float sv_radio_log_skips;

float radio_playing;
float radio_looping;
float radio_starttime;
float radio_tracklen;
float radio_playing_queue;
float radio_queue_advanceat;
float radio_queue_next_request;
string radio_url;
string radio_filename;

string mmss(float tenths) {
	float minutes;
	string s;
	tenths = floor(tenths + 0.5);
	minutes = floor(tenths / 600);
	tenths -= minutes * 600;
	s = ftos(1000 + tenths);
	return strcat(ftos(minutes), ":", substring(s, 1, 2));
}

var void() Radio_client_connect_real_NextLink;
void Radio_client_connect_real(void);

var void() Radio_ServerFrame_NextLink;
void Radio_ServerFrame(void);
var float(string cmd, float tokens) Radio_ClientCommandHandle_NextLink;
float Radio_ClientCommandHandle(string cmd, float tokens);
var float(string cmd, float tokens) Radio_cmd_game_handle_NextLink;
float Radio_cmd_game_handle(string cmd, float tokens);

var void(void(string item, string cmd) Add_Item) Radio_gamemenu_send_NextLink;
void Radio_gamemenu_send(void(string item, string cmd) Add_Item) {
	Add_Item("Radio", "cl_cmd showradio;");
	Radio_gamemenu_send_NextLink(Add_Item);
}


void Radio_Init(void) {
	radio_playing_queue = -1;

	CVAR_CACHE(sv_radio);
	if(!sv_radio)
		return;

	URI_GET_RADIO = uri_register_handler(Radio_URI_Get_Callback);
	registercvar("_radio_queue", "");
	registercvar("_radio_queue_left", "0");
	CVAR_CACHE(sv_radio_announce);
	CVAR_CACHE(sv_radio_preload);
	CVAR_CACHE(sv_radio_queue_autofill);
	CVAR_CACHE(sv_radio_queue_autofill_retry);
	CVAR_CACHE(sv_radio_queue_advanceat);
	CVAR_CACHE(sv_radio_queue_autofill_retry);
	CVAR_CACHE(sv_radio_log_skips);
	Radio_client_connect_real_NextLink = plugin_chain_client_connect_real;
	plugin_chain_client_connect_real = Radio_client_connect_real;
	Radio_ServerFrame_NextLink = plugin_chain_world_frame_start;
	plugin_chain_world_frame_start = Radio_ServerFrame;
	Radio_ClientCommandHandle_NextLink = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = Radio_ClientCommandHandle;
	Radio_cmd_game_handle_NextLink = plugin_chain_cmd_game_handle;
	plugin_chain_cmd_game_handle = Radio_cmd_game_handle;
	Radio_gamemenu_send_NextLink = plugin_chain_gamemenu_send;
	plugin_chain_gamemenu_send = Radio_gamemenu_send;
}

void Radio_SendPreload(entity e, string url) {
	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RADIO);
	net_write_byte(MSG_ONE, TRUE);
	net_write_string(MSG_ONE, url);
}

void Radio_Announce(entity e) {
	if(radio_playing_queue >= 0)
	if(sv_radio_announce) {
		string desc = cvar_string(strcat("_radio_queue_", ftos(radio_playing_queue), "_desc"));
		if(desc == "")
			desc = "^8(unknown track)";
		desc = strcat("^1[RADIO] ^2Now playing ^3", desc);
		if(radio_tracklen)
			desc = strcat(desc, "^8 (", mmss(radio_tracklen * 10), ")");
		float left = cvar("_radio_queue_left");
		if(left)
			desc = strcat(desc, "^7 - ", ftos(left), " in queue");

		if(e)
			sprint(e, strcat("\{1}", desc, "\n"));
		else {
			bprint("\{1}", desc, "\n");
		}
	}
}

void Radio_SendPlay(entity e, float force) {
	if(!radio_playing)
		return;

	Radio_Announce(e);

	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RADIO);
	net_write_byte(MSG_ONE, FALSE); //preload
	net_write_string(MSG_ONE, radio_url);
	net_write_string(MSG_ONE, radio_filename);
	net_write_byte(MSG_ONE, (radio_looping ? 1 : 0) | (force ? 2 : 0));
	if(!radio_looping)
		net_write_coord(MSG_ONE, radio_starttime);
}

void Radio_Preload(string url) {
	if(!sv_radio_preload)
		return;

	entity e; CLIENT_FOR_EACH_REAL(e)
		Radio_SendPreload(e, url);
}

void Radio_Play(string url, string fname, float loop) {
	str_unzone_ifneeded(radio_url);
	str_unzone_ifneeded(radio_filename);

	radio_url = str_zone_ifneeded(url);
	radio_filename = str_zone_ifneeded(fname);
	radio_looping = loop;
	radio_starttime = time;
	radio_playing = TRUE;
	radio_tracklen = 0;
	radio_playing_queue = -1;
	entity e; CLIENT_FOR_EACH_REAL(e)
		Radio_SendPlay(e, FALSE);
}

void Radio_Stop(void) {
	str_unzone_ifneeded(radio_url);
	str_unzone_ifneeded(radio_filename);

	if(!radio_playing)
		return;

	radio_playing = FALSE;
	radio_url = radio_filename = "";
	radio_playing_queue = -1;

	entity e; CLIENT_FOR_EACH_REAL(e)
		stuffcmd(e, "cd reset\n");
}

void Radio_Queue_Request(void) {
	radio_queue_next_request = 0;
	if(sv_radio_queue_autofill)
		uri_get(cvar_string("sv_radio_queue_autofill_server"), URI_GET_RADIO);
}

void Radio_Queue_PlayFirst(void) {
	if(!player_count || map_finished) {
		Radio_Stop();
		return;
	}

	string q = cvar_string("_radio_queue");

	if(q == "") {
		Radio_Stop();
		Radio_Queue_Request();
		return;
	}

	float n = tokenizebyseparator(q, " ");

	string id	= argv(0);
	string url   = cvar_string(strcat("_radio_queue_", id, "_url"));
	string fname = cvar_string(strcat("_radio_queue_", id, "_fname"));

	Radio_Play(url, fname, FALSE);

	radio_tracklen = cvar(strcat("_radio_queue_", id, "_len"));
	radio_playing_queue = stof(id);
	radio_queue_advanceat = radio_starttime + radio_tracklen * sv_radio_queue_advanceat;

	// preload next track
	id = argv(1);
	if(id != "")
		Radio_Preload(cvar_string(strcat("_radio_queue_", id, "_url")));

	cvar_set("_radio_queue_left", ftos(n-1));
	Radio_Announce(world);
}

string Radio_Queue_GetFreeID(void) {
	float id;
	string qs = strcat(" ", cvar_string("_radio_queue"), " ");

	for(id = 0 ;; ++id) {
		if (id == radio_playing_queue)
			continue;

		string s = ftos(id);
		if(strstrofs(qs, strcat(" ", s, " "), 0) < 0)
			return s;
	}
}

void Radio_Queue(string url, string fname, float len, string desc) {
	radio_queue_next_request = 0;

	string id = Radio_Queue_GetFreeID();

	string url_var   = strcat("_radio_queue_", id, "_url");
	string fname_var = strcat("_radio_queue_", id, "_fname");
	string len_var   = strcat("_radio_queue_", id, "_len");
	string desc_var  = strcat("_radio_queue_", id, "_desc");

	registercvar(url_var, "");
	registercvar(fname_var, "");
	registercvar(len_var, "");
	registercvar(desc_var, "");

	cvar_set(url_var, url);
	cvar_set(fname_var, fname);
	cvar_set(len_var, ftos(len));
	cvar_set(desc_var, desc);

	string q = cvar_string("_radio_queue");
	if(q == "")
		cvar_set("_radio_queue", id);
	else
		cvar_set("_radio_queue", strcat(q, " ", id));

	if(radio_playing_queue < 0)
		Radio_Queue_PlayFirst();
	else if(!cvar("_radio_queue_left"))
		Radio_Preload(url);

	cvar_set("_radio_queue_left", ftos(cvar("_radio_queue_left") + 1));
}

void Radio_Queue_Advance(void) {
	string q = cvar_string("_radio_queue");
	float sp = strstrofs(q, " ", 0);

	if(sp < 0) {
		cvar_set("_radio_queue", "");
		return;
	}

	cvar_set("_radio_queue", substring(q, sp+1, strlen(q)));
}

void Radio_Queue_Skip(void) {
	if(radio_playing_queue < 0)
		return;

	if(sv_radio_log_skips) {
		float fh = fopen("skiplog", FILE_APPEND);
		if(fh >= 0) {
			fputs(fh, strcat(strftime(TRUE, "%a %b %e %H:%M:%S %Z %Y "), radio_url, " ", radio_filename, "\n"));
			fclose(fh);
		}
	}

	if(radio_queue_advanceat)
		Radio_Queue_Advance();
	Radio_Queue_PlayFirst();
}

var void() Radio_ServerFrame_NextLink;
void Radio_ServerFrame(void) {
	Radio_ServerFrame_NextLink();
	if(radio_queue_next_request)
	if(time > radio_queue_next_request)
		Radio_Queue_Request();

	if(radio_playing_queue < 0)
		return;

	if(radio_queue_advanceat > 0)
	if(time > radio_queue_advanceat) {
		Radio_Queue_Advance();
		radio_queue_advanceat = 0;

		if(cvar_string("_radio_queue") == "")
			Radio_Queue_Request();
	}

	if(time > radio_starttime + radio_tracklen)
		Radio_Queue_PlayFirst();
}

void Radio_URI_Get_Callback(float id, float status, string data) {
	if(status) {
		radio_queue_next_request = time + sv_radio_queue_autofill_retry;
		return;
	}

	float n = tokenizebyseparator(data, " ");
	string d = "";

	if(n > 3) {
		d = substring(data, argv_start_index(3), strlen(data));
		d = strcat(d, " ^8(autoqueue)");
	}

	Radio_Queue(argv(0), argv(1), stof(argv(2)), d);
}

void Radio_client_connect_Delayed(void) {
	Radio_SendPlay(self, FALSE);
}

void Radio_client_connect_real(void) {
	Radio_client_connect_real_NextLink();
	if (player_count - bot_count == 1)
		defer(5, Radio_Queue_PlayFirst);

	if(!radio_playing)
		return;

	if(sv_radio_preload)
		Radio_SendPreload(self, radio_url);
	defer(3, Radio_client_connect_Delayed);
}

float Radio_ClientCommandHandle(string cmd, float tokens) {
    if(cmd == "radiotoggle" && tokens == 2) {
//        if(!self.scorekeeper)
//            return FALSE;
//
//        float o = self.radio_enabled;
//        self.radio_enabled = stof(argv(1));
//        score_player_setFlagsBoolean(self, SPFLAG_MUTE, !self.radio_enabled);
//
//        if(!o && self.radio_enabled)
		if (stof(argv(1)))
			Radio_SendPlay(self, TRUE);
		else
			stuffcmd(self, "cd reset\n");

		return TRUE;
	}
	return Radio_ClientCommandHandle_NextLink(cmd, tokens);
}

float Radio_cmd_game_handle(string cmd, float tokens) {
    if(argv(0) == "netmusic" || argv(0) == "radio_play") {
    	Radio_Play(argv(1), argv(2), (argv(3) == "loop"));
    	return TRUE;
    }
    if(argv(0) == "stopmusic" || argv(0) == "radio_stop") {
    	Radio_Stop();
    	return TRUE;
    }
    if(argv(0) == "radio_preload") {
    	Radio_Preload(argv(1));
    	return TRUE;
    }
    if(argv(0) == "radio_queue") {
    	Radio_Queue(argv(1), argv(2), stof(argv(3)), uri_unescape(argv(4)));
    	return TRUE;
    }
    if(argv(0) == "radio_queue_skip") {
    	Radio_Queue_Skip();
    	return TRUE;
    }
    if(argv(0) == "radio_queue_restart") {
    	Radio_Queue_PlayFirst();
    	return TRUE;
    }
    if(argv(0) == "radio_evil") {
		entity e;
        CLIENT_FOR_EACH_REAL(e)
            stuffcmd(e, "radio 1\n");
        return TRUE;
    }
	return Radio_cmd_game_handle_NextLink(cmd, tokens);
}
