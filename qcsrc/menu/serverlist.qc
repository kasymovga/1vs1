float MENU_SERVERLIST_URI_HANDLER;
#define MENU_SERVERLIST_URIS_COUNT 3
var float menu_serverlist_uri_index = 0;
string menu_serverlist_uris[MENU_SERVERLIST_URIS_COUNT] = {
	"http://kasymovga.github.io/rexdlc-web/serverlist.txt",
	"http://rexuiz.com/maps/serverlist.txt",
	"http://nexuiz.mooo.com/serverlist.txt",
};
float MENU_SERVERLIST_MASTER_URI_HANDLER;
#define MENU_SERVERLIST_MASTER_URIS_COUNT 3
var float menu_serverlist_master_uri_index = 0;
string menu_serverlist_master_uris[MENU_SERVERLIST_MASTER_URIS_COUNT] = {
	"http://kasymovga.github.io/rexdlc-web/masterlist.txt",
	"http://rexuiz.com/maps/masterlist.txt",
	"http://nexuiz.mooo.com/masterlist.txt",
};

void(float id, float status, string data) menu_serverlist_callback {
	float f;
	float d;
	string s;
	cvar_set("net_slist_extra", "");
	if (status) {
		print(menu_serverlist_uris[menu_serverlist_uri_index], " error: ", ftos(status), "\n");
		menu_serverlist_uri_index++;
		if (menu_serverlist_uri_index < MENU_SERVERLIST_URIS_COUNT) {
			uri_get(menu_serverlist_uris[menu_serverlist_uri_index], MENU_SERVERLIST_URI_HANDLER);
			return;
		} else {
			f = fopen("data/serverlistcache.txt", FILE_READ);
			if (f < 0) {
				f = fopen("serverlistbootstrap.txt", FILE_READ);
				if (f < 0)
					return;
				else
					print("Loaded server list from serverlistbootstrap.txt\n");
			} else
				print("Loaded server list cache from data/serverlistcache.txt\n");

			while ((s = fgets(f))) {
				d = strstrofs(s, "/", 0);
				cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? substring(s, 0, d) : s)));
			}
			fclose(f);
		}
		return;
	}
	print(menu_serverlist_uris[menu_serverlist_uri_index], " downloaded successfully\n");
	f = fopen("serverlistcache.txt", FILE_WRITE);
	if not(f < 0) {
		fputs(f, data);
		fclose(f);
	}
	float n = tokenizebyseparator(data, "\n");
	float i;
	for (i = 0; i < n; i++) {
		s = argv(i);
		d = strstrofs(s, "/", 0);
		cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? substring(s, 0, d) : s)));
	}
}

void(float id, float status, string data) menu_serverlist_master_callback {
	if (status) {
		print(menu_serverlist_master_uris[menu_serverlist_master_uri_index], " error: ", ftos(status), "\n");
		menu_serverlist_master_uri_index++;
		if (menu_serverlist_master_uri_index < MENU_SERVERLIST_MASTER_URIS_COUNT) {
			uri_get(menu_serverlist_master_uris[menu_serverlist_master_uri_index], MENU_SERVERLIST_MASTER_URI_HANDLER);
			return;
		}
		return;
	}
	print(menu_serverlist_master_uris[menu_serverlist_master_uri_index], " downloaded successfully\n");
	float n = tokenizebyseparator(data, "\n");
	string s, s1, s2;
	float i;
	float masternum = 0;
	for (i = 0; i < n; i++) {
		s = argv(i);
		s1 = str_car(s);
		s = str_cdr(s);
		s2 = str_car(s);
		if (s1 == "M") {
			masternum++;
			if (masternum < 3) {
				cvar_set(strcat("sv_masterextra", ftos(masternum)), s2);
			}
		} else if (s1 == "U")
			cvar_set("sv_udppunchhole_server", s2);
	}
}

void(void) menu_serverlist_init {
	MENU_SERVERLIST_URI_HANDLER = uri_register_handler(menu_serverlist_callback);
	MENU_SERVERLIST_MASTER_URI_HANDLER = uri_register_handler(menu_serverlist_master_callback);
	uri_get(menu_serverlist_uris[0], MENU_SERVERLIST_URI_HANDLER);
	uri_get(menu_serverlist_master_uris[0], MENU_SERVERLIST_MASTER_URI_HANDLER);
}
