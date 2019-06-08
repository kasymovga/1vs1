entity extresponse_chain;
.er_func_t er_func;

float(string q) extrepsone_is_unsafe_input {
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

void(string dst, string input) extresponse_query {
    if(checkextension("DP_RM_QCSENDPACKET")) {
        net_sendpacket(dst, input);
        return;
    }
    if(extrepsone_is_unsafe_input(input)) {
        print("extrespone_query: [for: ", dst, "] prevented a potentially dangerous string from being sent to the console: ", input, "\n");
        backtrace("extrespone_query");
        return;
    }
    localcmd("packet " + dst + " " + " \"" + input + "\"\n");
}

entity(string command) extresponse_find_handler {
	entity e;
    for (e = extresponse_chain; e; e = e.owner) {
        if (e.netname == command)
            break;
    }
    return e;
}

void(string response) extresponse_parse {
    dprint("Got an ExtResponse: ^5" + response + "\n");

    var n = tokenize_console(response);
    var e = extresponse_find_handler(argv(1));

    if(e && e.er_func) {
        using(self = e.owner) {
            e.er_func(n, response);
        }
    }
}

void(void) extresponse_update {
    while((var s = getextresponse()))
        extresponse_parse(s);
}

void(string command, er_func_t callback, entity selfent) extresponse_register_handler {
    entity e = extresponse_find_handler(command);
	if (e)
		return;

	e = spawn();
	e.classname = "er_handler";
	e.netname = command;
	e.er_func = callback;
	e.owner = extresponse_chain;
	extresponse_chain = e;
}
