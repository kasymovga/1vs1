
float ER_IsUnsafeInput(string q) {
    if(strstrofs(q, ";", 0) >= 0)
        return TRUE;
    if(strstrofs(q, "\n", 0) >= 0)
        return TRUE;
    if(strstrofs(q, "\r", 0) >= 0)
        return TRUE;
    if(strstrofs(q, "$", 0) >= 0)
        return TRUE;
    if(strstrofs(q, "\"", 0) >= 0)
        return TRUE;
    return FALSE;
}

void ER_Query(string dst, string input) {
    if(checkextension("DP_RM_QCSENDPACKET")) {
        net_sendpacket(dst, input);
        return;
    }

    if(ER_IsUnsafeInput(input)) {
        print("ER_Query: [for: ", dst, "] prevented a potentially dangerous string from being sent to the console: ", input, "\n");
        backtrace("ER_Query");
        return;
    }

    localcmd("packet " + dst + " " + " \"" + input + "\"\n");
}

entity ER_FindHandler(string command) {
    for(entity e = world; (e = find(e, classname, "er_handler"));) {
        if(e.netname == command)
            break;
    }

    return e;
}

void ER_Parse(string response) {
    dprint("Got an ExtResponse: ^5" + response + "\n");

    var n = tokenize_console(response);
    var e = ER_FindHandler(argv(1));

    if(e && e.er_func) {
        using(self = e.owner) {
            e.er_func(n, response);
        }
    }
}

void ER_Update(void) {
    while((var s = getextresponse()))
        ER_Parse(s);
}

void ER_RegisterHandler(string command, er_func_t callback, entity selfent) {
    var e = ER_FindHandler(command);
    (if(e) e else spawn()) {
        classname: "er_handler",
        netname: command,
        er_func: callback,
        owner: selfent,
    };
}
