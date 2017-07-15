
float sv_ip2country;
float sv_ip2country_allow_fakeflag;

void IP2C_SetCountry_Internal(entity player, string cn) {
    if(/*player.hidecountry ||*/ cn == "") {
        cn = "xx";
    }

    if(player.scorekeeper) {
        cn = strtolower(cn);  // flag icons have lowcase names
        PlayerScore_Set(player, SP_COUNTRY, str2chr(substring(cn, 0, 1), 0) | (str2chr(substring(cn, 1, 1), 0) * 256));
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
    if(!sv_ip2country || clienttype(player) != CLIENTTYPE_REAL) {
        IP2C_SetCountry_Internal(player, "");
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

void IP2C_InitSV(void) {
    CACHE_CVAR(sv_ip2country);
    CACHE_CVAR(sv_ip2country_allow_fakeflag);

    if(!sv_ip2country) {
        return;
    }

    IP2C_Init();
    dlc_require("flagicons");

    Net_LinkEntity(spawn(), FALSE, 0, inline float(entity e, float sf) {
        WriteByte(MSG_ENTITY, ENT_CLIENT_INIT_IP2C);
        return TRUE;
    });

    if(sv_ip2country_allow_fakeflag) {
        IP2C_ClientCommandHandle_NextLink = GameHookChain_ClientCommandHandle;
        GameHookChain_ClientCommandHandle = IP2C_ClientCommandHandle;
    }
}
