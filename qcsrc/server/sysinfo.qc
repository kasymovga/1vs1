.string sysinfo;
string sv_sysinfo_checker;
string sv_sysinfo_precache_player_models;
float URI_SYSINFO_CHECKER;

var float(string cmd, float tokens) sysinfo_ClientCommandHandle_NextLink;
float(string cmd, float tokens) sysinfo_ClientCommandHandle {
	float i;
	string tmp;
	if(cmd == "sysinfo") {
		if (g_campaign)
			return TRUE;

		tmp = argv(1);
		for (i = 2; i < tokens; i++) {
			tmp = strcat(tmp, "-", argv(i));
		}
		tmp = strreplace(" ", "-", tmp);
		tmp = strreplace("%", "-", tmp);
		tmp = strreplace("\\", "/", tmp);
		tmp = strreplace("\"", "", tmp);
		tmp = strreplace("&", "", tmp);
		tmp = strreplace("?", "", tmp);
		if (tmp != "")
		if (self.sysinfo == "") {
			self.sysinfo = strzone(tmp);
			tmp = strcat(tmp, "&ip=", self.netaddress);
			tmp = strcat(tmp, "&name=", uri_escape(self.netname));
			if (sv_sysinfo_checker != "")
				uri_get(strcat(sv_sysinfo_checker, tmp), URI_SYSINFO_CHECKER);
		}
		return TRUE;
	}
	return sysinfo_ClientCommandHandle_NextLink(cmd, tokens);
}

void(string _info, .float field, float val, string s) sysinfo_search_and_mark {
	entity e;
	for (e = find(NULL, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
		print(e.netname, " ", s, "\n");
		e.field = val;
		voip_setup(e);
	}
}

void(void) sysinfo_flag_think {
	self.cnt--;
	entity e;
	CLIENT_FOR_EACH_REAL(e) {
		if (e.sysinfo == self.netname) {
			ip2c_set(e, self.message);
			self.cnt = -1;
			break;
		}
	}
	if (self.cnt < 0) {
		str_unzone_ifneeded(self.netname);
		str_unzone_ifneeded(self.message);
		remove(self);
		return;
	}
	self.nextthink = time + 1;
}

entity sysinfo_model_forced;
var string(string m) sysinfo_player_body_model_list_allowed_mod_next;
string(string m) sysinfo_player_body_model_list_allowed_mod {
	entity sm;
	for (sm = sysinfo_model_forced; sm; sm = sm.enemy) {
		if (sm.owner == self)
			return sm.model;
	}
	return sysinfo_player_body_model_list_allowed_mod_next(m);
};

float sysinfo_model_init_done;
void(void) sysinfo_model_init {
	if (sysinfo_model_init_done)
		return;

	sysinfo_model_init_done = 1;
	sysinfo_player_body_model_list_allowed_mod_next = plugin_chain_player_body_model_list_allowed_mod;
	plugin_chain_player_body_model_list_allowed_mod = sysinfo_player_body_model_list_allowed_mod;
}

entity sysinfo_score_bonus;
var float(entity attacker, entity targ, float f) sysinfo_score_give_frag_mod_next;
float(entity attacker, entity targ, float f) sysinfo_score_give_frag_mod {
	entity e;
	if (attacker != targ) {
		for (e = sysinfo_score_bonus; e; e = e.enemy) {
			if (e.owner == attacker) {
				f *= e.dmg;
			} else if (e.owner == targ) {
				f *= e.dmg_edge;
			}
		}
	}
	return sysinfo_score_give_frag_mod_next(attacker, targ, f);
}

void(entity cl, float f1, float f2) sysinfo_score_bonus_add {
	entity e;
	for (e = sysinfo_score_bonus; e; e = e.enemy) {
		if (e.owner == cl) {
			e.dmg = f1;
			e.dmg_edge = f2;
			return;
		}
	}
	e = spawn();
	e.owner = cl;
	e.dmg = f1;
	e.dmg_edge = f2;
	e.enemy = sysinfo_score_bonus;
	sysinfo_score_bonus = e;
}

void(entity cl) sysinfo_score_bonus_remove {
	entity e, e2;
	if not(sysinfo_score_bonus) return;
	if (cl == sysinfo_score_bonus.owner) {
		e = sysinfo_score_bonus;
		sysinfo_score_bonus = e.enemy;
		remove(e);
		return;
	}
	for (e = sysinfo_score_bonus; e.enemy; e = e.enemy) {
		if (e.enemy.owner == cl) {
			e2 = e.enemy;
			e.enemy = e2.enemy;
			remove(e2);
			return;
		}
	}
}

float sysinfo_score_bonus_init_done;
void(void) sysinfo_score_bonus_init {
	if (sysinfo_score_bonus_init_done) return;
	sysinfo_score_bonus_init_done = 1;
	sysinfo_score_give_frag_mod_next = plugin_chain_score_give_frag_mod;
	plugin_chain_score_give_frag_mod = sysinfo_score_give_frag_mod;
}

void(float id, float status, string data) sysinfo_uri_callback {
	if (status) {
		print("sysinfo checker failed, status: ", ftos(status), "\n");
		return;
	}
	string head, tail, _info;
	tail = data;
	_info = str_car(tail);
	if (_info == "") return;
	tail = str_cdr(tail);
	entity e;
	while (tail != "") {
		head = str_car(tail);
		if (head == "saboteur")
			sysinfo_search_and_mark(_info, saboteur, 1, "marked as saboteur");
		else if (head == "noteam" && team_teams) {
			sysinfo_search_and_mark(_info, saboteur, 2, "marked as no team");
			PLAYER_FOR_EACH_REAL(e) {
				if (e.sysinfo == _info)
					player_to_spec(e);
			}
		} else if (head == "nodup") {
			string addr = "";
			CLIENT_FOR_EACH_REAL(e) {
				if (e.sysinfo == _info) {
					addr = e.netaddress;
					break;
				}
			}
			if (addr != "") {
				float keepone = FALSE;
				CLIENT_FOR_EACH_REAL(e) {
					if (e.netaddress == addr) {
						if (keepone)
							dropclient(e);
						else
							keepone = TRUE;
					}
				}
			}
		} else if (head == "retard" || head == "abuser") {
			sysinfo_search_and_mark(_info, abuser, 1, "marked as abuser");
			CLIENT_FOR_EACH_REAL(e) {
				if (e.abuser > 0)
					e.netname = client_abuserplayername;
			}
		} else if (head == "muted")
			sysinfo_search_and_mark(_info, muted, 1, "muted");
		else if (head == "stacker")
			sysinfo_search_and_mark(_info, stacker, 1, "marked as stacker");
		else if (head == "drop") {
			for (e = find(NULL, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
				print(e.netname, " droped because of sysinfo check\n");
				dropclient(e);
			}
			break;
		} else if (substring(head, 0, 5)  == "flag=") {
			e = spawn();
			e.nextthink = time + 1;
			e.message = str_zone_ifneeded(substring(head, 5, 2));
			e.netname = str_zone_ifneeded(_info);
			print(self.netname, " get custom flag by sysinfo:", e.message, "\n");
			e.think = sysinfo_flag_think;
			e.cnt = 5;
		} else if (substring(head, 0, 5) == "clid=") {
			for (e = find(NULL, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
				str_unzone_ifneeded(e.clid);
				e.clid = str_zone_ifneeded(substring(head, 5, 16));
				stuffcmd(e, strcat("seta _cl_id ", e.clid, "\n"));
				entity oldself = self;
				self = e;
				rank_load();
				self = oldself;
				print(e.netname, " have clid forced by sysinfo: ", e.clid, "\n");
			}
		} else if (substring(head, 0, 6)  == "model=") {
			string m = substring(head, 6, -1);
			string precache_list = strcat(" ", sv_sysinfo_precache_player_models, " ");
			if (strstrofs(precache_list, strcat(" ", m, " "), 0) >= 0)
				for (e = find(NULL, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
					sysinfo_model_init();
					entity sm = spawn();
					sm.enemy = sysinfo_model_forced;
					sm.owner = e;
					sm.model = str_zone_ifneeded(m);
					print("Forced model ", sm.model, " added for ", self.netname, "\n");
					sysinfo_model_forced = sm;
				}
		} else if (substring(head, 0, 11)  == "scorebonus=") {
			sysinfo_score_bonus_init();
			string sb = substring(head, 11, -1);
			float f1, f2;
			f1 = strstrofs(sb, ",", 0);
			if (f1 >= 0) {
				f2 = stof(substring(sb, f1 + 1, -1));
				f1 = stof(substring(sb, 0, f1));
			} else {
				f1 = stof(sb);
				f2 = 1;
			}
			for (e = find(NULL, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
				sysinfo_score_bonus_add(e, f1, f2);
			}
		}
		tail = str_cdr(tail);
	}
}

var void() sysinfo_client_disconnect_real_NextLink;
void() sysinfo_client_disconnect_real {
	str_unzone_ifneeded(self.sysinfo);
	sysinfo_client_disconnect_real_NextLink();
	if (sysinfo_model_forced) {
		entity sm;
		if (sysinfo_model_forced.owner == self) {
			print("Forced model removed for ", self.netname, "\n");
			sm = sysinfo_model_forced.enemy;
			str_unzone_ifneeded(sysinfo_model_forced.model);
			remove(sysinfo_model_forced);
			sysinfo_model_forced = sm;
		}
		entity sm2;
		if (sysinfo_model_forced) {
			for (sm = sysinfo_model_forced; sm.enemy; sm = sm.enemy) {
				if (sm.enemy.owner == self) {
					print("Forced model removed for ", self.netname, "\n");
					sm2 = sm.enemy.enemy;
					str_unzone_ifneeded(sm.enemy.model);
					remove(sm.enemy);
					sm.enemy = sm2;
				}
			}
		}
	}
	sysinfo_score_bonus_remove(self);
}

void() sysinfo_init {
	CVAR_CACHE_STR(sv_sysinfo_checker);
	sysinfo_ClientCommandHandle_NextLink = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = sysinfo_ClientCommandHandle;
	sysinfo_client_disconnect_real_NextLink = plugin_chain_client_disconnect_real;
	plugin_chain_client_disconnect_real = sysinfo_client_disconnect_real;
	URI_SYSINFO_CHECKER = uri_register_handler(sysinfo_uri_callback);
	CVAR_CACHE_STR(sv_sysinfo_precache_player_models);
	if (sv_sysinfo_precache_player_models != "") player_body_precache(sv_sysinfo_precache_player_models);
}
