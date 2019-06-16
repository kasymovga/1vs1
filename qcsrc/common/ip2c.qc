float IPCacheDB;
.entity ip2c_callbackentity;
.string ip2c_callbackip;
.ip2c_callback_t ip2c_callbackfunction;
.float ip2c_requested_at;

er_func_t IP2C_ER_Response_Callback;
er_func_t IP2C_ER_Request_Callback;

void IP2C_Log(string msg) {
    #ifdef MENUQC
        print("MENU ");
    #endif

    print("IP2C: ", msg, "\n");
}

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
    var res = db_get(IPCacheDB, ip);

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

#ifdef MENUQC
.void() think;
.float nextthink;

// apparently menuqc doesn't support thinkfunctions
void IP2C_CheckTimedOut(void) {
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); ) if(time >= e.nextthink) {
        entity oldself;
        oldself = self;
        self = e;
        e.think();
        self = oldself;
    }
}
#endif

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

    var url = IP2C_GetQueryURL();

    if(url == "") {
        IP2C_Log(strcat("Can't lookup ip ", ip, ", sv_ip2country_server is not set"));
        return;
    }

    IP2C_Log(strcat("IP ", ip, " is not cached, requesting from the server"));

    if(substring(url, 0, strlen(IP2C_UDP_PROTOCOL_PREFIX)) == IP2C_UDP_PROTOCOL_PREFIX) {
        extresponse_query(substring(url, strlen(IP2C_UDP_PROTOCOL_PREFIX), strlen(url)), "extResponse ip2cq " + ip);
    } else {
        uri_get(strcat(url, ip), URI_GET_IP2C);
    }
}

void IP2C_ER_Response_Callback(float argc, string response) {
    var source = argv(0);
    var ok = FALSE;

    var url = IP2C_GetQueryURL();
    if(substring(url, 0, strlen(IP2C_UDP_PROTOCOL_PREFIX)) == IP2C_UDP_PROTOCOL_PREFIX) {
        var trusted = substring(url, strlen(IP2C_UDP_PROTOCOL_PREFIX), strlen(url));
        if(source == trusted)
            ok = TRUE;
    }

    if(!ok) {
        IP2C_Log("Response packet from an untrusted origin " + source + " ignored");
        return;
    }

    var ip = argv(2);
    var cn = argv(3);

    if(!ip || !cn || cn == "--") {
        IP2C_Log(strcat("The remote server failed to resolve ", ip));
        IP2C_ExecCallbacks(ip, "");
        return;
    }

    IP2C_CacheIP(ip, cn);
    IP2C_ExecCallbacks(ip, cn);
}

void IP2C_ER_Request_Callback(float argc, string query) {
    var source = argv(0);
    var ip = argv(2);

    if(ip == "") {
        IP2C_Log("Malformed IP2C query ignored: " + query);
        return;
    } else {
        IP2C_Log("Got query from " + source + ": " + ip);
    }

    IP2C_Lookup(ip, inline void(string ip, string cn, entity ent) {
        if(ent.classname != "ip2cr_sourceinfo") {
            IP2C_Log("Huh? Lost the requester's address somehow. Was going to send: " + ip + " " + cn);
            return;
        }

        if(cn == "")
            cn = "--";

        IP2C_Log("Sending query response to " + ent.netname + ": " + ip + " " + cn);
        extresponse_query(ent.netname, "extResponse ip2cr " + ip + " " + cn);

        strunzone(ent.netname);
        remove(ent);
    }, 0, spawn() {
        classname: "ip2cr_sourceinfo",
        netname: strzone(source),
    });
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
