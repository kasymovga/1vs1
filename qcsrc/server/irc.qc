/*
 * Ported from RocketMinsta mod. https://github.com/nexAkari/RocketMinsta
 */
entity irc;
float irc_startup_time;

float sv_ircbot_announce_bans;
float sv_ircbot_announce_chat_from_bots;
float sv_ircbot_announce_game_events;
float sv_ircbot_announce_map_finished;
float sv_ircbot_announce_gamestart;
float sv_ircbot_announce_irc_joinparts;
float sv_ircbot_announce_irc_nick;
float sv_ircbot_announce_joinparts;
float sv_ircbot_announce_joinparts_delay;
float sv_ircbot_announce_joinparts_showgameinfo;
float sv_ircbot_announce_joinparts_showip;
float sv_ircbot_announce_name;
float sv_ircbot_announce_radio;
float sv_ircbot_announce_votes;
float sv_ircbot_announce_when_empty;
float sv_ircbot_channel_auto_rejoin;
float sv_ircbot_chat_irc2game;
float sv_ircbot_chat_irc2game_require_highlight;
float sv_ircbot_reconnect_interval;
float sv_ircbot_reconnect_interval_add;
float sv_ircbot_silent;
float sv_ircbot_spamstatus;
float sv_ircbot_spamstatus_delay;
float sv_ircbot_update_topic;
float sv_ircbot_update_topic_hostname;
float sv_ircbot_update_topic_serverempty;
float sv_ircbot_update_topic_serverfull;

float irc_was_connected;
float irc_reconnect_time;
float irc_disconnections;
float irc_gamestart_wasannounced;

var void() IRC_Announce_RealClientConnect_NextLink;
void IRC_Announce_RealClientConnect();
var void() IRC_Announce_RealClientDisconnect_NextLink;
void IRC_Announce_RealClientDisconnect();
var void(entity plr, string msg) IRC_PublicPlayerChat_NextLink;
void IRC_PublicPlayerChat(entity plr, string msg);


void IRC_Print(string str) {
	if (sv_ircbot_silent)
		bprint("\{3}", "^5IRC ", str, "\n");
	else
		bprint("\{1}", "^5IRC ", str, "\n");
}

float IRC_CheckSession(float s) {
    if(!IRC_SessionExists(s))
        s = IRC_CreateSession();
    
    if(!IRC_SessionIsConnected(s)) {
        if(irc_was_connected) {
            float d = sv_ircbot_reconnect_interval + sv_ircbot_reconnect_interval_add * irc_disconnections;
            print("IRC_CheckSession: trying to reconnect in ", ftos(d), " seconds\n");

            irc_was_connected = FALSE;
            irc_reconnect_time = time + d;
            irc_disconnections += 1;
        }

        if(!irc || time >= irc_reconnect_time) {
            float err = IRC_ConnectSession(s,
                cvar_string("sv_ircbot_server"),
                cvar("sv_ircbot_server_port"),
                cvar_string("sv_ircbot_server_password"),
                cvar_string("sv_ircbot_nick"),
                cvar_string("sv_ircbot_user"),
                cvar_string("sv_ircbot_realname")
            );

            if(!err)
                irc_was_connected = TRUE;
            else if(err == IRC_ERR_STATE)
                IRC_TerminateSession(s);
        }
    } else
        irc_was_connected = TRUE;

    cvar_set("_sv_ircbot_session", ftos(s));
    return s;
}

#define IRC_STRING_SEPARATOR "^9  //  "

string IRC_GameInfoString(void) {
	return strcat("^7playing ^5", gametype_title, "^7 on ^2", mapname);
}

string IRC_ClientsInfoString(void) {
    string s = strcat("^1", ftos(player_count), "^7/", ftos(client_max_count), " clients");
    if(bot_count > 0)
        s = strcat(s, " (", ftos(bot_count), " bots)");
    return s;
}

float IRC_Privmsg(float handle, string targ, string msg) {
    float r = IRC_Privmsg_Builtin(handle, targ, msg);
    
    float spam = max(0, sv_ircbot_spamstatus);
    if(spam && handle == irc.cnt && strtolower(targ) == irc.target && time - irc_startup_time >= sv_ircbot_spamstatus_delay) {
        float c = cvar("_sv_ircbot_msgsent") + 1;
        if(c >= spam) {
            c = 0;
            IRC_Privmsg_Builtin(handle, targ, strcat("^1Game status: ^7", IRC_GameInfoString(), IRC_STRING_SEPARATOR, IRC_ClientsInfoString()));
        }
        cvar_set("_sv_ircbot_msgsent", ftos(c));
    }
    
    return r;
}

float IRC_Announce(float handle, string targ, string msg) {
	if(sv_ircbot_announce_when_empty || player_count > 0)
		return IRC_Privmsg(handle, targ, msg);
	return 0;
}

void IRC_UpdateTopic(void) {
    if(!sv_ircbot_update_topic)
        return;
        
    string s = cvar_string("sv_ircbot_update_topic_static");
    if(s != "")
        s = strcat(s, IRC_STRING_SEPARATOR, "^7");
    if(sv_ircbot_update_topic_hostname)
        s = strcat(s, cvar_string("hostname"), IRC_STRING_SEPARATOR);
    s = strcat(s, IRC_GameInfoString());
    
    if(!player_count && sv_ircbot_update_topic_serverempty)
        s = strcat(s, IRC_STRING_SEPARATOR, "^1server empty");
    else if(player_count == client_max_count && sv_ircbot_update_topic_serverfull)
        s = strcat(s, IRC_STRING_SEPARATOR, "^1server full");
    
    if(cvar_string("_sv_ircbot_lasttopic") != IRC_DP2IRC(s) || irc.skin > 1) {
        IRC_Topic(irc.cnt, irc.target, s);
    }

    irc.skin = 0;
}

void IRC_Think(void) {
    self.cnt = IRC_CheckSession(self.cnt);
    self.nextthink = time + 1;
    
    if(self.skin) {
        IRC_UpdateTopic();
        self.skin = 0;
    }
}

string IRC_DP2IRC_NoColors(string s) {
//#NO AUTOCVARS START
    string v1 = cvar_string("irc_translate_dp2irc_color");
    string v2 = cvar_string("irc_translate_dp2irc_qfont");
    cvar_set("irc_translate_dp2irc_color", "1");
    cvar_set("irc_translate_dp2irc_qfont", "1");
    s = IRC_DP2IRC(s);
    cvar_set("irc_translate_dp2irc_color", v1);
    cvar_set("irc_translate_dp2irc_qfont", v2);
    return s;
//#NO AUTOCVARS END
}

void IRC_Init(void) {
    float s;
	irc_startup_time = time;
    
    if(!cvar("sv_ircbot"))
        return;
    
    if(!checkextension("DP_RM_IRC")) {
        print("IRC_Init: engine doesn't implement the DP_RM_IRC extension. Install DarkPlacesRM to use IRC.\n");
        return;
    }
    
    if(!cvar("irc_initialized")) { print("IRC_Init: the IRC module is not initialized, make sure you have libircclient installed.\n");
        return;
    }
    
	CACHE_CVAR(sv_ircbot_announce_bans);
	CACHE_CVAR(sv_ircbot_announce_chat_from_bots);
	CACHE_CVAR(sv_ircbot_announce_game_events);
	CACHE_CVAR(sv_ircbot_announce_map_finished);
	CACHE_CVAR(sv_ircbot_announce_gamestart);
	CACHE_CVAR(sv_ircbot_announce_irc_joinparts);
	CACHE_CVAR(sv_ircbot_announce_irc_nick);
	CACHE_CVAR(sv_ircbot_announce_joinparts);
	CACHE_CVAR(sv_ircbot_announce_joinparts_delay);
	CACHE_CVAR(sv_ircbot_announce_joinparts_showgameinfo);
	CACHE_CVAR(sv_ircbot_announce_joinparts_showip);
	CACHE_CVAR(sv_ircbot_announce_name);
	CACHE_CVAR(sv_ircbot_announce_radio);
	CACHE_CVAR(sv_ircbot_announce_votes);
	CACHE_CVAR(sv_ircbot_announce_when_empty);
	CACHE_CVAR(sv_ircbot_channel_auto_rejoin);
	CACHE_CVAR(sv_ircbot_chat_irc2game);
	CACHE_CVAR(sv_ircbot_chat_irc2game_require_highlight);
	CACHE_CVAR(sv_ircbot_reconnect_interval);
	CACHE_CVAR(sv_ircbot_reconnect_interval_add);
	CACHE_CVAR(sv_ircbot_silent);
	CACHE_CVAR(sv_ircbot_spamstatus);
	CACHE_CVAR(sv_ircbot_spamstatus_delay);
	CACHE_CVAR(sv_ircbot_update_topic);
	CACHE_CVAR(sv_ircbot_update_topic_hostname);
	CACHE_CVAR(sv_ircbot_update_topic_serverempty);
	CACHE_CVAR(sv_ircbot_update_topic_serverfull);

    // These are internal cvars used to achieve persistence between restarts
    registercvar("_sv_ircbot_session", "-1");
    registercvar("_sv_ircbot_msgsent", "0");
    registercvar("_sv_ircbot_lasttopic", "");
    
    s = IRC_CheckSession(cvar("_sv_ircbot_session"));
    
    irc = spawn();
    irc.classname = "ircbot";
    irc.cnt = s;
    irc.target = strzone(strtolower(cvar_string("sv_ircbot_channel")));
    irc.targetname = strzone(cvar_string("sv_ircbot_channel_key"));
    irc.think = IRC_Think;
    irc.nextthink = time + 5;
    
    IRC_Announce_GameStart();
	IRC_Announce_RealClientConnect_NextLink = GameHookChain_RealClientConnect;
	GameHookChain_RealClientConnect = IRC_Announce_RealClientConnect;
	IRC_Announce_RealClientDisconnect_NextLink = GameHookChain_RealClientDisconnect;
	GameHookChain_RealClientDisconnect = IRC_Announce_RealClientDisconnect;
	IRC_PublicPlayerChat_NextLink = GameHookChain_PublicPlayerChat;
	GameHookChain_PublicPlayerChat = IRC_PublicPlayerChat;
}

float IRC_IsIgnored(string mask) {
    float i, argc = tokenizebyseparator(cvar_string("sv_ircbot_ignore_list"), " ");
    for(i = 0; i < argc; ++i)
        if(IRC_MaskMatches(mask, argv(i)))
            return TRUE;
    return FALSE;
}

void IRC_Event(float handle, string event, float numeric, string src, float argc) {
    string nick, user, host;
    
    if(!irc)
        return;

    if(handle != irc.cnt)    // not our session
        return;
    
    nick = substring(src, 0, strstrofs(src, "!", 0));
    user = substring(src, strstrofs(src, "!", 0) + 1, strstrofs(src, "@", 0) - strstrofs(src, "!", 0) - 1);
    host = substring(src, strstrofs(src, "@", 0) + 1, strlen(src));
	string msg;
    
    if(event == "CONNECT") {
        irc_disconnections = 0;
        IRC_JoinChannel(handle, irc.target, irc.targetname);
        if(cvar_string("sv_ircbot_connectcommand") != "")
            IRC_SendRaw(handle, cvar_string("sv_ircbot_connectcommand"));
    } else if(event == "CHANNEL") {
        if(sv_ircbot_chat_irc2game)
        if(strtolower(argv(0)) == irc.target) {
            msg = argv(1);

            if(IRC_IsIgnored(src))
                return;

            msg = IRC_IRC2DP(msg);

            if(sv_ircbot_chat_irc2game_require_highlight) {
                string mynick = IRC_CurrentNick(handle);
                float nl = strlen(mynick);
                float ml = strlen(msg);
                
                if(substring(msg, 0, nl + 1) == strcat(mynick, " "))
                    msg = substring(msg, nl + 1, ml);
                else if(substring(msg, 0, nl + 2) == strcat(mynick, ": ") ||
                        substring(msg, 0, nl + 2) == strcat(mynick, ", "))
                    msg = substring(msg, nl + 2, ml);
                else
                    msg = "";
            }
            
            if(msg != "")
                IRC_Print(strcat("^8<^3", nick, "^8>^7 ", msg));
        }
    } else if(event == "PRIVMSG") {
		//Nothing
    } else if(event == "CTCP") {
        // /me for borked libircclient
        if(sv_ircbot_chat_irc2game)
        if(!sv_ircbot_chat_irc2game_require_highlight)
        if(substring(argv(0), 0, 7) == "ACTION ") {
            msg = argv(0);
            if(!IRC_IsIgnored(src))
                IRC_Print(strcat("^3* ", nick, "^7 ", IRC_IRC2DP(substring(msg, 7, strlen(msg)))));
        }
    } else if(event == "ACTION") {
        // /me for unborked libircclient
        if(sv_ircbot_chat_irc2game)
        if(!sv_ircbot_chat_irc2game_require_highlight)
        if(strtolower(argv(0)) == irc.target) {
            msg = argv(1);
            if(!IRC_IsIgnored(src))
                IRC_Print(strcat("^3* ", nick, "^7 ", IRC_IRC2DP(msg)));
        }
    } else if(event == "KICK") {
        if(sv_ircbot_channel_auto_rejoin)
        if(argv(1) == IRC_CurrentNick(handle)) {
            IRC_JoinChannel(handle, argv(0), ((strtolower(argv(0)) == irc.target) ? irc.targetname : ""));
            return;
        }
        
        if(sv_ircbot_announce_irc_joinparts) if(strtolower(argv(0)) == irc.target)
            IRC_Print(strcat("^1* ^3", nick, " ^1kicked ^3", argv(1), " ^1from ^2", argv(0), ((argv(2) != "" && argv(2) != argv(1)) ? strcat(" ^8(", argv(2), ")") : "")));
    } else if(event == "JOIN") {
        if(sv_ircbot_announce_irc_joinparts) if(strtolower(argv(0)) == irc.target)
            IRC_Print(strcat("^7* ^3", nick, " ^7joined ^2", argv(0)));
    } else if(event == "PART") {
        if(sv_ircbot_announce_irc_joinparts) if(strtolower(argv(0)) == irc.target)
            IRC_Print(strcat("^7* ^3", nick, " ^7left ^2", argv(0), ((argv(1) != "" && argv(1) != nick) ? strcat(" ^8(", argv(1), ")") : "")));
    } else if(event == "QUIT") {
        if(sv_ircbot_announce_irc_joinparts)
            IRC_Print(strcat("^1* ^3", nick, " ^1has quit IRC", ((argv(0) != "" && argv(0) != "Quit") ?  strcat(" ^8(", argv(0), ")") : "")));
    } else if(event == "MODE") {
        if(strtolower(argv(0)) == irc.target) if(argv(1) == "+o") if(argv(2) == IRC_CurrentNick(irc.cnt))
            irc.skin = 1;
    } else if(event == "NICK") {
        if(sv_ircbot_announce_irc_nick)
            IRC_Print(strcat("^7* ^3", nick, " ^7is now known as ^3", argv(0)));
    } else if(event == "TOPIC") {
        if(strtolower(argv(0)) == irc.target) {
            cvar_set("_sv_ircbot_lasttopic", argv(1));

            if(nick != IRC_CurrentNick(handle))
                IRC_UpdateTopic();
        }
    } else if(numeric == IRC_RFC_ERR_NICKNAMEINUSE) {
        IRC_ChangeNick(handle, strcat(argv(1), "`"));
    } else if(numeric == IRC_RFC_RPL_TOPIC) {
        if(strtolower(argv(1)) == irc.target)
            cvar_set("_sv_ircbot_lasttopic", argv(2));
    } else if(numeric == IRC_RFC_RPL_NOTOPIC) {
        if(strtolower(argv(1)) == irc.target)
            cvar_set("_sv_ircbot_lasttopic", "");
    }
}

void IRC_PublicPlayerChat(entity plr, string msg) {
	if (clienttype(plr) == CLIENTTYPE_REAL || sv_ircbot_announce_chat_from_bots)
		IRC_Privmsg(irc.cnt, irc.target, strcat("<", plr.netname, "^7> ", msg));

	IRC_PublicPlayerChat_NextLink(plr, msg);
}

void IRC_Announce_Client_Callback(string ip, string cn, entity ctx) {
    entity plr = ctx.owner;
    string msg;
    
    if(ctx.cnt) msg = "^1- part ^3#";
    else        msg = "^2+ join ^3#";
    msg = strcat(msg, ftos(num_for_edict(plr)), "^7: ", plr.netname);
    
    if(sv_ircbot_announce_joinparts_showip)
        msg = strcat(msg, "^7 (^4", ip, "^7)");
    if(cn != "")
        msg = strcat(msg, "^7 [^6", strtoupper(cn), "^7]");
    if(sv_ircbot_announce_joinparts_showgameinfo)
        msg = strcat(msg, IRC_STRING_SEPARATOR, IRC_GameInfoString());
    msg = strcat(msg, IRC_STRING_SEPARATOR, IRC_ClientsInfoString());
    
    IRC_Privmsg(irc.cnt, irc.target, msg);
    irc.skin = 1;
    
    remove(ctx);
}

void IRC_Announce_Client(entity plr, float ispart) {
    if(!sv_ircbot_announce_joinparts)
        return;

    if(time - irc_startup_time < sv_ircbot_announce_joinparts_delay)
        return;
    
    entity ctx = spawn();
    ctx.cnt = ispart;
    ctx.owner = plr;
    
    IRC_Announce_Client_Callback(plr.netaddress, "", ctx);
}

void IRC_Announce_RealClientConnect() {
    IRC_Announce_Client(self, FALSE);
    if (!irc_gamestart_wasannounced)
        IRC_Announce_GameStart();

	IRC_Announce_RealClientConnect_NextLink();
}

void IRC_Announce_RealClientDisconnect() {
    IRC_Announce_Client(self, TRUE);
	IRC_Announce_RealClientDisconnect_NextLink();
}

void IRC_Defer_Update_Topic()
{
	IRC_UpdateTopic();
	remove(self);
}

void IRC_Announce_GameStart(void) { if(!irc) return;
    if(sv_ircbot_announce_gamestart)
    if(sv_ircbot_announce_when_empty || player_count > 0) {
		string s = cvar_string("g_profile");
		if (s != "") {
			s = strcat("[^3", strtoupper(s), "^7] ");
		}
        IRC_Privmsg(irc.cnt, irc.target, strcat("^3--> ^7Now playing ", s, "^5", gametype_title, "^7 on ^2", mapname, " ^3<-- "));
        irc_gamestart_wasannounced = TRUE;
    }
	entity e = spawn();
	e.nextthink = time + 10;
	e.think = IRC_Defer_Update_Topic;
}

void IRC_Announce_GameOver(void) { if(!irc) return;
    if(sv_ircbot_announce_map_finished)
    if(sv_ircbot_announce_when_empty || player_count > 0 || irc_gamestart_wasannounced)
        IRC_Privmsg(irc.cnt, irc.target, strcat("^1--> ^5", gametype_title, "^7 on ^2", mapname, " ^7ended ^1<-- "));
}

void IRC_Announce_GameEvent(string estr) { if(!irc) return;
	if(sv_ircbot_announce_game_events)
		IRC_Announce(irc.cnt, irc.target, estr);
}

void IRC_Announce_Vote(string vstr) { if(!irc) return;
    if(sv_ircbot_announce_votes)
        IRC_Announce(irc.cnt, irc.target, vstr);
}

void IRC_Announce_Ban(string bstr) { if(!irc) return;
    if(sv_ircbot_announce_bans)
        IRC_Announce(irc.cnt, irc.target, bstr);
}

void IRC_Announce_Name(entity plr, string name) { if(!irc) return;
    if(sv_ircbot_announce_name && (strdecolorize(plr.netname) != strdecolorize(name)))
        IRC_Announce(irc.cnt, irc.target, strcat("* ^3", plr.netname, "^7 changed name to ^3", name));
}

void IRC_Announce_Radio(string rstr) { if(!irc) return;
    if(sv_ircbot_announce_radio)
        IRC_Announce(irc.cnt, irc.target, rstr);
}
