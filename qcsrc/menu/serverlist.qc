float SERVERLIST_URI_HANDLER;
#define SERVERLIST_URIS_COUNT 3
var float serverlist_uri_index = 0;
string serverlist_uris[SERVERLIST_URIS_COUNT] = {
	"http://rexuiz.com/maps/serverlist.txt",
	"http://nexuiz.mooo.com/serverlist.txt",
	"http://kasymovga.github.io/rexdlc-web/serverlist.txt",
};

void(float id, float status, string data) serverlist_callback {
	float f;
	float d;
	string s;
	cvar_set("net_slist_extra", "");
	if (status) {
		print(serverlist_uris[serverlist_uri_index], " error: ", ftos(status), "\n");
		serverlist_uri_index++;
		if (serverlist_uri_index < SERVERLIST_URIS_COUNT) {
			uri_get(serverlist_uris[serverlist_uri_index], SERVERLIST_URI_HANDLER);
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
				cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? str_sub(s, 0, d) : s)));
			}
			fclose(f);
		}
		return;
	}
	print(serverlist_uris[serverlist_uri_index], " downloaded successfully\n");
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
		cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? str_sub(s, 0, d) : s)));
	}
}

void(void) serverlist_reload {
	uri_get(serverlist_uris[0], SERVERLIST_URI_HANDLER);
}

void(void) serverlist_init {
	SERVERLIST_URI_HANDLER = uri_register_handler(serverlist_callback);
	serverlist_reload();
}

void(void) serverlist_fields_update {
	SERVERLIST_FIELD_CNAME = gethostcacheindexforkey( "cname" );
	SERVERLIST_FIELD_PING = gethostcacheindexforkey( "ping" );
	SERVERLIST_FIELD_GAME = gethostcacheindexforkey( "game" );
	SERVERLIST_FIELD_MOD = gethostcacheindexforkey( "mod" );
	SERVERLIST_FIELD_MAP = gethostcacheindexforkey( "map" );
	SERVERLIST_FIELD_NAME = gethostcacheindexforkey( "name" );
	SERVERLIST_FIELD_MAXPLAYERS = gethostcacheindexforkey( "maxplayers" );
	SERVERLIST_FIELD_NUMPLAYERS = gethostcacheindexforkey( "numplayers" );
	SERVERLIST_FIELD_NUMHUMANS = gethostcacheindexforkey( "numhumans" );
	SERVERLIST_FIELD_NUMBOTS = gethostcacheindexforkey( "numbots" );
	SERVERLIST_FIELD_PROTOCOL = gethostcacheindexforkey( "protocol" );
	SERVERLIST_FIELD_FREESLOTS = gethostcacheindexforkey( "freeslots" );
	SERVERLIST_FIELD_PLAYERS = gethostcacheindexforkey( "players" );
	SERVERLIST_FIELD_QCSTATUS = gethostcacheindexforkey( "qcstatus" );
	SERVERLIST_FIELD_ISFAVORITE = gethostcacheindexforkey( "isfavorite" );
}
