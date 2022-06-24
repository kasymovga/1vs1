float MASTERLIST_URI_HANDLER;
#define MASTERLIST_URIS_COUNT 3
var float masterlist_uri_index = 0;
string masterlist_uris[MASTERLIST_URIS_COUNT] = {
	"http://kasymovga.github.io/rexdlc-web/masterlist.txt",
	"http://rexuiz.com/maps/masterlist.txt",
	"http://nexuiz.mooo.com/masterlist.txt",
};

void(float id, float status, string data) masterlist_callback {
	if (status) {
		print(masterlist_uris[masterlist_uri_index], " error: ", ftos(status), "\n");
		masterlist_uri_index++;
		if (masterlist_uri_index < MASTERLIST_URIS_COUNT) {
			uri_get(masterlist_uris[masterlist_uri_index], MASTERLIST_URI_HANDLER);
			return;
		}
		return;
	}
	print(masterlist_uris[masterlist_uri_index], " downloaded successfully\n");
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

void(void) masterlist_init {
	MASTERLIST_URI_HANDLER = uri_register_handler(masterlist_callback);
	uri_get(masterlist_uris[0], MASTERLIST_URI_HANDLER);
}
