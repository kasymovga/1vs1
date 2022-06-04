entity dlc_curl_event_listener;
float dlc_downloading;
string dlc_expected;
float dlc_think_frames;

void(void) dlc_restart_render {
	print("Render restart requested\n");
	if (clientstate() != CS_CONNECTED)
		localcmd("r_restart\n");
	else if (!isserver())
		localcmd("disconnect;wait;r_restart;wait;reconnect\n");
}

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
			print("DLC ", n, " failed\n");
		else
			print("DLC ", n, " fetched\n");
	}
	if (dlc_expected == " ") {
		if (dlc_ready_all()) {
			float rr = dlc_curl_event_listener.cnt;
			if (dlc_reload(!dlc_downloading, dlc_curl_event_listener.cnt)) {
				if (rr)
					dlc_restart_render();

				if (dlc_curl_event_listener) {
					remove(dlc_curl_event_listener);
					dlc_curl_event_listener = NULL;
				}
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
				dlc_reload(FALSE, dlc_curl_event_listener.cnt); //Request downloading
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
	float n;
	if ((n = cvar("cl_lasermodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == 1)
			s = strcat(s, " xonlaser");
	}
	if ((n = cvar("cl_glmodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == 1)
			s = strcat(s, " xongl");
		else if (n == -1)
			s = strcat(s, " n23gl");
	}
	if ((n = cvar("cl_rlmodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == 2)
			s = strcat(s, " qanrl");
		else if (n == 1)
			s = strcat(s, " xonrl");
		else if (n == -1)
			s = strcat(s, " n23rl");
	}
	if ((n = cvar("cl_hagarmodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == 1)
			s = strcat(s, " xonhagar");
		else if (n == -1)
			s = strcat(s, " n23hagar");
	}
	if ((n = cvar("cl_sgmodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == -1)
			s = strcat(s, " n23shotgun");
	}
	if ((n = cvar("cl_uzimodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == -1)
			s = strcat(s, " n23uzi");
	}
	if ((n = cvar("cl_electromodel")) && (!dlc_mandatory || dlc_ready("base-models"))) {
		if (n == -1)
			s = strcat(s, " n23electro");
	}
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
		dlc_reloaded = TRUE;
		dlc_expected = "";
		if (dlc_curl_event_listener) {
			remove(dlc_curl_event_listener);
			dlc_curl_event_listener = NULL;
		}
		return TRUE;
	}
	dlc_expected = str_zone_ifneeded(dlc_expected);
	if not(dlc_curl_event_listener) {
		dlc_curl_event_listener = spawn();
		dlc_curl_event_listener.classname = "curl_event_listener";
		dlc_curl_event_listener.think = dlc_curl_event_listener_think;
	}
	dlc_curl_event_listener.cnt = (renderrestart || dlc_mandatory);
	if (dlc_curl_event_listener.cnt)
		print("Render restart will be requried\n");

	dlc_reloaded = FALSE;
	return FALSE;
}

void(void) dlc_think {
	if (dlc_think_frames > 10) {
		dlc_think_frames = 0;
		if not(dlc_reloaded) {
			float rr = dlc_curl_event_listener.cnt;
			if (dlc_ready_all()) {
				if (dlc_reload(TRUE, rr))
					dlc_restart_render();
			} else {
				if not(dlc_downloading)
					dlc_reload(FALSE, rr);
			}
		}
	}
	dlc_think_frames++;
}