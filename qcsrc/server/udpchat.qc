string sv_udpchat_server;
string sv_udpchat_id;

void UDPChat_ER_Response_Callback(float argc, string response) {
	string s;
	float i, n;
	string from = argv(0);
	string peer = "";
	if (from == sv_udpchat_server)
		peer = from;

	if (peer == "")
		for (i = 1; (s = cvar_string(strcat("sv_udpchat_client", ftos(i)))) != ""; i++)
			if (from == s) {
				peer = s;
				break;
			}

	if (peer == "") {
		print("Unknown peer: ", from, "\n");
		return;
	}

	string msg = substring(response, argv_start_index(2), -1);
	float colon = strstrofs(msg, ":", 0);
	if (colon)
		bprint("\{3}", "^5\x12 ^3", substring(msg, 0, colon), "^2:^5", substring(msg, colon + 1, -1), "\n");
	else
		bprint("\{3}", "^5\x12 ", msg, "\n");

	if (sv_udpchat_server != "")
	if (peer != sv_udpchat_server)
		ER_Query(sv_udpchat_server, "extResponse udpchat " + msg);

	n = i;
	for (i = 1; i < n; i++) {
		s = cvar_string(strcat("sv_udpchat_client", ftos(i)));
		if (peer != s)
			ER_Query(s, "extResponse udpchat " + msg);
	}
}

var void(entity source, string msg) UDPChat_PupblicPlayerChat_NextLink;
void UDPChat_PupblicPlayerChat(entity source, string msg) {
	if (clienttype(source) != CLIENTTYPE_REAL)
		return;

	string _netname = strreplace(":", "_", source.netname);
	_netname = strreplace("@", "_", source.netname);
	if (sv_udpchat_server != "")
		ER_Query(sv_udpchat_server, "extResponse udpchat " + strdecolorize(_netname) + "@" + sv_udpchat_id + ": " + strdecolorize(msg));

	string s;
	float i;
	for (i = 1; (s = cvar_string(strcat("sv_udpchat_client", ftos(i)))) != ""; i++)
		for (i = 1; (s = cvar_string(strcat("sv_udpchat_client", ftos(i)))) != ""; i++)
			ER_Query(s, "extResponse udpchat " + strdecolorize(_netname) + "@" + sv_udpchat_id + ": " + strdecolorize(msg));

	UDPChat_PupblicPlayerChat_NextLink(source, msg);
}

void UDPChat_Init() {
	if not(cvar("sv_udpchat"))
		return;

	sv_udpchat_server = cvar_string_zone_ifneeded("sv_udpchat_server");
	sv_udpchat_id = cvar_string_zone_ifneeded("sv_udpchat_id");
    ER_RegisterHandler("udpchat", UDPChat_ER_Response_Callback, world);
	UDPChat_PupblicPlayerChat_NextLink = GameHookChain_PublicPlayerChat;
	GameHookChain_PublicPlayerChat = UDPChat_PupblicPlayerChat;
}

