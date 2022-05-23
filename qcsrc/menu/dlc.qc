entity dlc_curl_event_listener;
float dlc_downloading;
string dlc_expected;

void(void) dlc_curl_event_listener_think {
	if (dlc_expected == "") return;
	if (substring(curl_file_name, 0, 8) == "dlcache/") {
		curl_file_name = substring(curl_file_name, 8, -1);
	}
	if (substring(curl_file_name, 0, 11) == "zzz-rexdlc_")
	if (substring(curl_file_name, -4, 4) == ".pk3") {
		string n = substring(curl_file_name, 11, -5);
		string s = strreplace(strcat(" ", n, " "), " ", dlc_expected);
		str_unzone_ifneeded(dlc_expected);
		dlc_expected = str_zone_ifneeded(s);
		if (curl_error)
			print("Expected DLC ", n, " failed\n");
		else
			print("Expected DLC ", n, " fetched\n");
	}
	if (dlc_expected == " ") {
		if (dlc_ready_all()) {
			if (dlc_reload(!dlc_downloading, TRUE)) {
				if (self.cnt) {
					if (clientstate() != CS_CONNECTED)
						localcmd("r_restart\n");
					else if (!isserver())
						localcmd("disconnect;wait;r_restart;wait;reconnect\n");
				}
				remove(dlc_curl_event_listener);
				dlc_curl_event_listener = NULL;
				dlc_downloading = 0;
				dlc_reloaded = TRUE;
				str_unzone_ifneeded(dlc_expected);
				dlc_expected = "";
			}
		} else {
			if (dlc_downloading) {
				print("Some DLC failed\n");
				dlc_failed = TRUE; //Downloading failed
			} else {
				dlc_reload(FALSE, self.cnt); //Request downloading
			}
		}
	}
}

float(float nodownload, float renderrestart) dlc_reload {
	dlc_failed = FALSE;
	str_unzone_ifneeded(dlc_expected);
	if not(nodownload)
	if not(dlc_downloading) {
		dlc_downloading = TRUE;
		dlc_set_repos(cvar_string("sv_dlc_repository"));
	}
	string s = strcat(DLC_BASE_LIST " ", cvar_defstring("menu_dlc_extra"));
	dlc_list = "";
	if not(file_exists("maps/soylent.bsp")) { //check presence of data.pk3
		dlc_mandatory = TRUE;
		s = strcat(s, " base-maps");
		if (file_exists("dlcache/zzz-rexdlc_base-maps-lightmaps.pk3"))
			s = strcat(s, " base-maps-lightmaps");
	}
	if not(file_exists("textures/evil_metal/walltek3.jpg")) { //check presence of data.pk3
		dlc_mandatory = TRUE;
		s = strcat(s, " base-textures");
		if (file_exists("dlcache/zzz-rexdlc_base-textures-extra.pk3"))
			s = strcat(s, " base-textures-extra");
	}
	if not(file_exists("models/ebomb.mdl")) { //check presence of data.pk3
		dlc_mandatory = TRUE;
		s = strcat(s, " base-models");
	}
	if not(file_exists("sound/plats/medplat1.ogg")) { //check presence of data.pk3
		dlc_mandatory = TRUE;
		s = strcat(s, " base-sounds");
	}
	if not(file_exists("gfx/num_0.tga")) { //check presence of data.pk3
		dlc_mandatory = TRUE;
		s = strcat(s, " base-gfx");
	}
	if not(dlc_mandatory) {
		s = strcat(s, " datapatches");
	}
	if (cvar("cl_brightskins") && (!dlc_mandatory || dlc_ready("base-models"))) {
		s = strcat(s, " brightskins");
	}
	if (cvar("cl_oldnexmodel") <= 0 && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (cvar("cl_oldnexmodel") < 0)
			s = strcat(s, " xonnex");
		else
			s = strcat(s, " newnex");
	}
	if (cvar("cl_lasermodel") && (!dlc_mandatory || dlc_ready("base-models"))) {
		s = strcat(s, " xonlaser");
	}
	float n;
	if ((n = cvar("cl_simpleitems")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		s = strcat(s, " chainsaw_v2 zapper_v2 supershotgun"); //need load them first, to override their g_* models
		if (dlc_ready("chainsaw_v2") && dlc_ready("zapper_v2") && dlc_ready("supershotgun")) {
			if (n == 2)
				s = strcat(s, " simpleitems-luma");
			else
				s = strcat(s, " simpleitems");
		}
	}
	dlc_expected = " ";
	string head = "", tail = s;
	while (tail != "") {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head != "") {
			if (head == "classiccampaign-p3" && (!dlc_ready("classiccampaign") || !dlc_ready("classiccampaign-p1") || !dlc_ready("classiccampaign-p2"))) continue; //hack for classic campaign dlc order
			if not(dlc_load(head, nodownload)) {
				dlc_expected = strcat(dlc_expected, head, " ");
				if not(nodownload)
					print("Downloading missing pack: ", head, "\n");
			}
		}
	}
	if (dlc_ready_all()) {
		dlc_expected = "";
		return TRUE;
	}
	dlc_expected = str_zone_ifneeded(dlc_expected);
	if not(dlc_curl_event_listener) {
		dlc_curl_event_listener = spawn();
		dlc_curl_event_listener.classname = "curl_event_listener";
		dlc_curl_event_listener.think = dlc_curl_event_listener_think;
	}
	if (renderrestart)
		dlc_curl_event_listener.cnt = 1;

	dlc_reloaded = FALSE;
	return FALSE;
}
