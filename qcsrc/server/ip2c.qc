float SP_COUNTRY;

float sv_ip2country;
float sv_ip2country_allow_fakeflag;
string sv_ip2country_bot_flag;

void IP2C_SetCountry_Internal(entity player, string cn) {
    if(/*player.hidecountry ||*/ cn == "") {
        cn = "xx";
    }

    if(player.scorekeeper) {
        cn = strtolower(cn);  // flag icons have lowcase names
        score_player_set(player, SP_COUNTRY, str2chr(substring(cn, 0, 1), 0) | (str2chr(substring(cn, 1, 1), 0) * 256));
    } else {
        IP2C_Log(strcat(player.netname, "^7 has no scorekeeper"));
    }
}

void IP2C_LookupForPlayer_Callback(string ip, string cn, entity player) {
    entity e;
    FOR_EACH_REALCLIENT(e) if(e.netaddress == ip) {
        IP2C_SetCountry_Internal(e, cn);
    }
}

void IP2C_SetCountry(entity player) {
    if(clienttype(player) != CLIENTTYPE_REAL) {
        IP2C_SetCountry_Internal(player, sv_ip2country_bot_flag);
    } else {
        IP2C_Lookup(player.netaddress, IP2C_LookupForPlayer_Callback, 0, player);
    }
}

var float(string cmd, float tokens) IP2C_ClientCommandHandle_NextLink;

float IP2C_ClientCommandHandle(string cmd, float tokens) {
    if(cmd == "fakeflag" && self.classname) {
        if(strlen(argv(1)) != 2) {
            sprint(self, "^1The flag code must be exactly 2 characters long.\n");
            return TRUE;
        }

        IP2C_SetCountry_Internal(self, strtoupper(argv(1)));
        return TRUE;
    }

    return IP2C_ClientCommandHandle_NextLink(cmd, tokens);
}

var float(string cmd, float tokens) IP2C_GameCommandHandle_NextLink;
float IP2C_GameCommandHandle(string cmd, float tokens) {
	if(IP2C_GameCommand(cmd, tokens))
		return TRUE;

	return IP2C_GameCommandHandle_NextLink(cmd, tokens);
}

var void() IP2C_ShutdownHook_NextLink;
void IP2C_ShutdownHook(void) {
	IP2C_Shutdown();
	IP2C_ShutdownHook_NextLink();
}

var void() IP2C_ClientConnect_NextLink;
void IP2C_ClientConnect(void) {
	IP2C_SetCountry(self);
	IP2C_ClientConnect_NextLink();
}

void IP2C_InitSV(void) {
    CACHE_CVAR(sv_ip2country);
    CACHE_CVAR(sv_ip2country_allow_fakeflag);
	CACHE_CVAR_STR(sv_ip2country_bot_flag);
    if(!sv_ip2country) {
        return;
    }

	SP_COUNTRY = score_register("country", SFL_NOCLEAR);
    IP2C_Init();
    dlc_require("flagicons");

    net_link_entity(spawn(), FALSE, 0, inline float(entity e, float sf) {
        WriteByte(MSG_ENTITY, ENT_CLIENT_INIT_IP2C);
        return TRUE;
    });

    if(sv_ip2country_allow_fakeflag) {
        IP2C_ClientCommandHandle_NextLink = GameHookChain_ClientCommandHandle;
        GameHookChain_ClientCommandHandle = IP2C_ClientCommandHandle;
    }
	IP2C_GameCommandHandle_NextLink = GameHookChain_GameCommandHandle;
	GameHookChain_GameCommandHandle = IP2C_GameCommandHandle;
	IP2C_ShutdownHook_NextLink = gamehook_chain_shutdown;
	gamehook_chain_shutdown = IP2C_ShutdownHook;
	IP2C_ClientConnect_NextLink = GameHookChain_ClientConnect;
	GameHookChain_ClientConnect = IP2C_ClientConnect;
}
