string sv_report_url;
float report_uri_handler;

var void(void(string item, string cmd) Add_Item) report_gamemenu_send_next;
void report_gamemenu_send(void(string item, string cmd) Add_Item) {
	Add_Item("Report", strcat("cl_cmd report " , cvar_string("sv_report_reasons"), ";"));
	report_gamemenu_send_next(Add_Item);
}

void(float id, float status, string data) report_uri_callback {
    if (status) {
        print(strcat("Report sending failed with error: ", ftos(status)), "\n");
        return;
    }
}

var float(string cmd, float tokens) report_cmd_client_handle_next;
float(string cmd, float tokens) report_cmd_client_handle {
    if (cmd == "report" && tokens == 3) {
		entity villain = edict_num(stof(argv(2)));
		if (villain)
		if (clienttype(villain) == CLIENTTYPE_REAL) {
			string victimsysinfo = self.sysinfo;
			string victimip = self.netaddress;
			string victimnick = self.netname;
			string villainsysinfo = villain.sysinfo;
			string villainip = villain.netaddress;
			string villainnick = villain.netname;
			string reason = argv(1);
			string s = strcat("villainip=", uri_escape(villain.netaddress), "&");
			s = strcat(s, "villainnick=", uri_escape(villain.netname), "&");
			s = strcat(s, "villainsysinfo=", uri_escape(villain.sysinfo), "&");
			s = strcat(s, "victimip=", uri_escape(self.netaddress), "&");
			s = strcat(s, "victimnick=", uri_escape(self.netname), "&");
			s = strcat(s, "victimsysinfo=", uri_escape(self.sysinfo), "&");
			s = strcat(s, "reason=", uri_escape(reason));
			print("Report sending: ", s, "\n");
			uri_get(strcat(sv_report_url, "?", s), report_uri_handler);
			sprint(self, "\{1}^2Your report sended\n");
			return TRUE;
		}
	}
	return report_cmd_client_handle_next(cmd, tokens);
}

void(void) report_init {
	CVAR_CACHE_STR(sv_report_url);
	if (sv_report_url == "")
		return;

	report_gamemenu_send_next = plugin_chain_gamemenu_send;
	plugin_chain_gamemenu_send = report_gamemenu_send;
	report_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = report_cmd_client_handle;
	report_uri_handler = uri_register_handler(report_uri_callback);
}
