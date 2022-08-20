float SP_COUNTRY;

float sv_ip2country;
float sv_ip2country_allow_fakeflag;
string sv_ip2country_bot_flag;

void IP2C_Log(string msg) {
    print("IP2C: ", msg, "\n");
}

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

var float(string cmd, float tokens) IP2C_cmd_game_handle_NextLink;
float IP2C_cmd_game_handle(string cmd, float tokens) {
	if(IP2C_GameCommand(cmd, tokens))
		return TRUE;

	return IP2C_cmd_game_handle_NextLink(cmd, tokens);
}

var void() IP2C_ShutdownHook_NextLink;
void IP2C_ShutdownHook(void) {
	IP2C_Shutdown();
	IP2C_ShutdownHook_NextLink();
}

var void() IP2C_client_connect_NextLink;
void IP2C_client_connect(void) {
	IP2C_SetCountry(self);
	IP2C_client_connect_NextLink();
}

void IP2C_InitSV(void) {
    CVAR_CACHE(sv_ip2country);
    CVAR_CACHE(sv_ip2country_allow_fakeflag);
	CVAR_CACHE_STR(sv_ip2country_bot_flag);
    if(!sv_ip2country) {
        return;
    }

	SP_COUNTRY = score_register("country", SCORE_FLAG_NOCLEAR);
    IP2C_Init();
    dlc_require("flagicons");
    if(sv_ip2country_allow_fakeflag) {
        IP2C_ClientCommandHandle_NextLink = plugin_chain_cmd_client_handle;
        plugin_chain_cmd_client_handle = IP2C_ClientCommandHandle;
    }
	IP2C_cmd_game_handle_NextLink = plugin_chain_cmd_game_handle;
	plugin_chain_cmd_game_handle = IP2C_cmd_game_handle;
	IP2C_ShutdownHook_NextLink = plugin_chain_shutdown;
	plugin_chain_shutdown = IP2C_ShutdownHook;
	IP2C_client_connect_NextLink = plugin_chain_client_connect;
	plugin_chain_client_connect = IP2C_client_connect;
}

float IPCacheDB;
.entity ip2c_callbackentity;
.string ip2c_callbackip;
.ip2c_callback_t ip2c_callbackfunction;
.float ip2c_requested_at;

er_func_t IP2C_ER_Response_Callback;
er_func_t IP2C_ER_Request_Callback;

#ifdef IP2C_CAN_RESOLVE

string ip2c_url_resolved;
string ip2c_url_last;

#define IP2C_SETSTR(s,v) if(s) strunzone(s); s = strzone(v)

string IP2C_GetQueryURL(void) {
    var url = cvar_string("sv_ip2country_server");

    if(url == ip2c_url_last)
        return ip2c_url_resolved;

    IP2C_SETSTR(ip2c_url_last, url);

    var a_start = strstrofs(url, "://", 0) + 3;
    var a_end = strstrofs(url, "/", a_start);

    if(a_end < 0)
        a_end = strlen(url);

    var host_addr = substring(url, a_start, a_end - a_start);

    // TODO: handle ipv6 addresses?
    var port_start = strstrofs(host_addr, ":", 0);
    var port_str = "-1";

    if(port_start >= 0) {
        port_str = substring(host_addr, port_start + 1, strlen(host_addr));
        host_addr = substring(host_addr, 0, port_start);
    }

    var u_head = substring(url, 0, a_start);

    // FIXME: currently, we can't manually set the Host header for HTTP, so give up here for now...
    if(u_head == "http://" || u_head == "https://") {
        IP2C_SETSTR(ip2c_url_resolved, url);
        return ip2c_url_resolved;
    }

    var u_tail = substring(url, a_end, strlen(url));
    var host_ip = netaddress_resolve(host_addr, stof(port_str));

    if(substring(host_ip, strlen(host_ip) - 3, 3) == ":-1")
        host_ip = substring(host_ip, 0, strlen(host_ip) - 3);

    url = u_head + host_ip + u_tail;

    IP2C_Log("Resolved the query URL to ^5" + url);
    IP2C_SETSTR(ip2c_url_resolved, url);

    return ip2c_url_resolved;
}

#endif

void IP2C_FreeCallbackEntity(entity e) {
    if(e.ip2c_callbackip)
        strunzone(e.ip2c_callbackip);

    remove(e);
}

void IP2C_Init(void) {
    IP2C_REGISTERVARS()
    IP2C_Log("Loading cached IPs");
    IPCacheDB = db_load(IP2C_DBNAME);

    extresponse_register_handler("ip2cr", IP2C_ER_Response_Callback, world);

    if(cvar("sv_ip2country_proxy"))
        extresponse_register_handler("ip2cq", IP2C_ER_Request_Callback, world);

	URI_GET_IP2C = uri_register_handler(IP2C_URI_Get_Callback);
}

void IP2C_Shutdown(void) {
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); )
        IP2C_FreeCallbackEntity(e);

    IP2C_Log("Saving cached IPs");
    db_save(IPCacheDB, IP2C_DBNAME);
    db_close(IPCacheDB);
}

void IP2C_ClearCache(void) {
    db_close(IPCacheDB);
    IPCacheDB = db_create();
    db_save(IPCacheDB, IP2C_DBNAME);

    IP2C_Log("Cleared the cache");
}

string IP2C_LookupCached(string ip) {
    string res = db_get(IPCacheDB, ip);

    if(res != "") {
        return res;
    }

    if(checkextension("DP_RM_GEOIP") && cvar("sv_ip2country_use_builtin")) {
        if((res = GeoIP_LookUp(ip))) {
            return res;
        }
    }

    return "";
}

void IP2C_CacheIP(string ip, string cn) {
    IP2C_Log(strcat("Cached IP ", ip, ", CN: ", cn));
    db_put(IPCacheDB, ip, cn);
}

void IP2C_RequestTimeout(void) {
    IP2C_Log(strcat("Request for ", self.ip2c_callbackip, " timed out after ", ftos(time - self.ip2c_requested_at), " seconds"));
    self.ip2c_callbackfunction(self.ip2c_callbackip, "", self.ip2c_callbackentity);
    IP2C_FreeCallbackEntity(self);
}

void IP2C_AddCallback(string ip, ip2c_callback_t callback, float timeout, entity callbackentity) {
    if(timeout <= 0)
        timeout = cvar("sv_ip2country_timeout");

    entity cb = spawn();
    cb.classname = "ip2c_callbackprovider";
    cb.ip2c_callbackip = strzone(ip);
    cb.ip2c_callbackentity = callbackentity;
    cb.ip2c_callbackfunction = callback;
    cb.think = IP2C_RequestTimeout;
    cb.nextthink = time + timeout;
    cb.ip2c_requested_at = time;
}

void IP2C_ExecCallbacks(string ip, string cn) {
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); )
    if(e.ip2c_callbackip == ip) {
        e.ip2c_callbackfunction(ip, cn, e.ip2c_callbackentity);
        IP2C_FreeCallbackEntity(e);
    }
}

void IP2C_Lookup(string ip, ip2c_callback_t callback, float timeout, entity callbackentity) {
    if(!cvar("sv_ip2country"))
        return;

    string res;
    res = IP2C_LookupCached(ip);

    IP2C_AddCallback(ip, callback, timeout, callbackentity);

    if(res != "") {
        IP2C_ExecCallbacks(ip, res);
        return;
    }

    string url = IP2C_GetQueryURL();

    if(url == "") {
        IP2C_Log(strcat("Can't lookup ip ", ip, ", sv_ip2country_server is not set"));
        return;
    }

    IP2C_Log(strcat("IP ", ip, " is not cached, requesting from the server"));

    if(substring(url, 0, strlen(IP2C_UDP_PROTOCOL_PREFIX)) == IP2C_UDP_PROTOCOL_PREFIX) {
        extresponse_query(substring(url, strlen(IP2C_UDP_PROTOCOL_PREFIX), strlen(url)), strcat("extResponse ip2cq ", ip));
    } else {
        uri_get(strcat(url, ip), URI_GET_IP2C);
    }
}

void IP2C_ER_Response_Callback(float argc, string response) {
    string source = argv(0);
    float ok = FALSE;

    string url = IP2C_GetQueryURL();
    if(substring(url, 0, strlen(IP2C_UDP_PROTOCOL_PREFIX)) == IP2C_UDP_PROTOCOL_PREFIX) {
        string trusted = substring(url, strlen(IP2C_UDP_PROTOCOL_PREFIX), strlen(url));
        if(source == trusted)
            ok = TRUE;
    }

    if(!ok) {
        IP2C_Log(strcat("Response packet from an untrusted origin ", source, " ignored"));
        return;
    }

    string ip = argv(2);
    string cn = argv(3);

    if(!ip || !cn || cn == "--") {
        IP2C_Log(strcat("The remote server failed to resolve ", ip));
        IP2C_ExecCallbacks(ip, "");
        return;
    }

    IP2C_CacheIP(ip, cn);
    IP2C_ExecCallbacks(ip, cn);
}

void(string ip, string cn, entity ent) ip2c_request_callback_lookup {
	if (ent.classname != "ip2cr_sourceinfo") {
		IP2C_Log(strcat("Huh? Lost the requester's address somehow. Was going to send: ", ip, " ", cn));
		return;
	}
	if (cn == "")
		cn = "--";

	IP2C_Log(strcat("Sending query response to ", ent.netname, ": ", ip, " ", cn));
	extresponse_query(ent.netname, strcat("extResponse ip2cr ", ip, " ", cn));
	strunzone(ent.netname);
	remove(ent);
}

void IP2C_ER_Request_Callback(float argc, string query) {
    string source = argv(0);
    string ip = argv(2);

    if(ip == "") {
        IP2C_Log(strcat("Malformed IP2C query ignored: ", query));
        return;
    } else {
        IP2C_Log(strcat("Got query from ", source, ": ", ip));
    }
    entity e = spawn();
    e.classname = "ip2cr_sourceinfo";
    e.netname = strzone(source);
    IP2C_Lookup(ip, ip2c_request_callback_lookup, 0, e);
}

void IP2C_URI_Get_Callback(float id, float status, string data) {
    if(status) {
        IP2C_Log(strcat("IP lookup failed, status: ", ftos(status)));
        return;
    }

    float n = tokenizebyseparator(data, " ");
    string cn, ip;

    cn = substring(argv(0), 0, 2);
    ip = argv(1);

    if(cn == "--") {
        IP2C_Log(strcat("The remote server failed to resolve ", ip));
        IP2C_ExecCallbacks(ip, "");
        return;
    }

    IP2C_CacheIP(ip, cn);
    IP2C_ExecCallbacks(ip, cn);
}

void IP2C_Callback_DumpToConsole(string ip, string cn, entity e) {
    if(cn != "")
        IP2C_Log(strcat("Country for IP ", ip, ": ", cn));
}

void IP2C_PrintRequests(void) {
    IP2C_Log("^3Requests in progress:");

    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); )
        IP2C_Log(strcat(e.ip2c_callbackip, " : ^5", ftos(time - e.ip2c_requested_at), "s"));
}

float IP2C_GameCommand(string cmd, float tokens) {
    switch(cmd) {
        case "help":
            print("  ip2c_lookup ipaddress\n");
            print("  ip2c_status\n");
            print("  ip2c_clearcache\n");
            print("  ip2c_putcache ip countrycode\n");
            return TRUE;

        case "ip2c_lookup":
            IP2C_Lookup(argv(1), IP2C_Callback_DumpToConsole, 0, world);
            return TRUE;

        case "ip2c_status":
            IP2C_PrintRequests();
            return TRUE;

        case "ip2c_clearcache":
            IP2C_ClearCache();
            return TRUE;

        case "ip2c_putcache":
            if(tokens < 3) {
                print("Usage: ip2c_putcache ip countrycode\n");
                return TRUE;
            }

            IP2C_CacheIP(argv(1), argv(2));
            return TRUE;
    }

    return FALSE;
}
