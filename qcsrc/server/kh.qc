#define FOR_EACH_KH_KEY(v) for(v = kh_worldkeylist; v; v = v.weaponentity )

float KH_SCORE_TEAM_CAPS;
float KH_SCORE_CAPS;
float KH_SCORE_PUSHES;
float KH_SCORE_DESTROYS;
float KH_SCORE_PICKUPS;
float KH_SCORE_KCKILLS;
float KH_SCORE_LOSSES;

float KH_KEY_ZSHIFT = 22;
float KH_KEY_XYDIST = 24;
float KH_KEY_XYSPEED = 45;
float KH_KEY_WP_ZSHIFT = 20;

vector KH_KEY_MIN = '-10 -10 -46';
vector KH_KEY_MAX = '10 10 3';
float KH_KEY_BRIGHTNESS = 2;

string kh_Controller_Waitmsg;
float kh_no_radar_circles;
float kh_roundbased;

// kh_state
//     bits  0- 4: team of key 1, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits  5- 9: team of key 2, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits 10-14: team of key 3, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits 15-19: team of key 4, or 0 for no such key, or 30 for dropped, or 31 for self
.float kh_state;

entity kh_worldkeylist;
entity kh_controller;
float kh_teams;
string kh_teams_missed;
float kh_interferemsg_time, kh_interferemsg_team;
.float kh_droptime;

string kh_sound_capture = "kh/capture.wav";
string kh_sound_destroy = "kh/destroy.wav";
string kh_sound_drop = "kh/drop.wav";
string kh_sound_collect = "kh/collect.wav";
string kh_sound_alarm = "kh/alarm.wav";  // the new siren/alarm

float g_kh_damageforcescale;
float g_kh_delay_collect;
float g_kh_delay_drop;
float g_kh_delay_return;
float g_kh_delay_round;
float g_kh_delay_tracking;
float g_kh_dropvelocity;
float g_kh_maxdist;
float g_kh_protecttime;
float g_kh_score_capture;
float g_kh_score_carrierfrag;
float g_kh_score_collect;
float g_kh_score_destroyed;
float g_kh_score_push;
float g_kh_throwvelocity;
float g_kh_showenemycarrier;

void kh_Key_Spawn(entity key, entity initial_owner, float angle, float idx);
void kh_Key_Hide(entity key);
void(void) kh_key_think;
void(entity key) kh_Key_Attach;
void(entity key) kh_Key_Detach;
void(entity key, entity player) kh_Key_AssignTo;
void(entity key, entity player) kh_Key_Collect;
void(void) kh_Key_Touch;
void(float teem) kh_WinnerTeam;
void(float teem, entity lostkey) kh_LoserTeam;
void(void) kh_FinishRound;
void(void) kh_StartRound;
void(void) kh_EnableTrackingDevice;
float(entity e) kh_KeyCarrier_waypointsprite_visible_for_player;
float(entity e) kh_Key_waypointsprite_visible_for_player;
float(entity attacker, entity targ, float f) kh_HandleFrags;

#define STR_ITEM_KH_KEY "item_kh_key"
typedef void(void) kh_Think_t;
var kh_Think_t kh_Controller_Thinkfunc;

void(void) kh_update_state;

void(float t, string msg, kh_Think_t func) kh_Controller_SetThink { // runs occasionaly
	kh_Controller_Thinkfunc = func;
	kh_controller.cnt = ceil(t);
	str_unzone_ifneeded(kh_Controller_Waitmsg);
	kh_Controller_Waitmsg = str_zone_ifneeded(msg);
	if (t == 0)
		kh_controller.nextthink = time; // force
}

void(void) kh_Controller_Think { // called a lot
	if (map_intermission_running)
		return;

	if (self.cnt > 0) {
		if (kh_Controller_Waitmsg != "") {
			if not(kh_roundbased)
				game_status_set(kh_Controller_Waitmsg, 2, ftos(self.cnt), kh_teams_missed, "");
		}
		self.cnt -= 1;
	} else if (self.cnt == 0) {
		self.cnt -= 1;
		kh_Controller_Thinkfunc();
	}
	self.nextthink = time + 1;
}

// frags f: take from cvar * f
// frags 0: no frags
void(entity player, entity key, float frags_player, float frags_owner) kh_Scores_Event { // update the score when a key is captured
	if (map_intermission_running)
		return;

	if (frags_player)
		score_player_team_add_score(player, frags_player);

	if (key && key.owner && frags_owner)
		score_player_team_add_score(key.owner, frags_owner);
}

void(entity key) kh_Key_Attach { // runs when a player picks up a key and several times when a key is assigned to a player at the start of a round
	setattachment(key, key.owner.body, "");
	setorigin(key, '0 0 1' * KH_KEY_ZSHIFT);  // fixing x, y in think
	key.angles_y -= key.owner.angles_y;
	key.flags = 0;
	key.solid = SOLID_NOT;
	key.movetype = MOVETYPE_NONE;
	key.team = key.owner.team;
	key.nextthink = time;
	key.damageforcescale = 0;
	key.takedamage = DAMAGE_NO;
}

void(entity key) kh_Key_Detach { // runs every time a key is dropped or lost. Runs several times times when all the keys are captured
	setorigin(key, key.owner.origin + key.origin_z * '0 0 1');
	setattachment(key, NULL, "");
	key.angles_y += key.owner.angles_y;
	key.flags = FL_ITEM;
	key.solid = SOLID_TRIGGER;
	key.movetype = MOVETYPE_TOSS;
	key.pain_finished = time + g_kh_delay_return;
	key.damageforcescale = g_kh_damageforcescale;
	key.takedamage = DAMAGE_YES;
	// let key.team stay
	key.realowner = key.owner;
	key.playerid = key.owner.playerid;
}

void kh_Key_AssignTo(entity key, entity player) { // runs every time a key is picked up or assigned. Runs prior to kh_key_attach
	entity k;
	float ownerteam0, ownerteam;
	if (key.owner == player)
		return;

	ownerteam0 = kh_Key_AllOwnedByWhichTeam();
	if (key.owner) {
		kh_Key_Detach(key);
		// remove from linked list
		if (key.kh_next)
			key.kh_next.kh_prev = key.kh_prev;

		key.kh_prev.kh_next = key.kh_next;
		key.kh_next = NULL;
		key.kh_prev = NULL;
		if not(key.owner.kh_next) {
			// No longer a key carrier
			if (!kh_no_radar_circles)
			if (key.owner.waypointsprite_attachedforcarrier)
				WaypointSprite_Ping(key.owner.waypointsprite_attachedforcarrier);

			WaypointSprite_DetachCarrier(key.owner);
		}
	}
	key.owner = player;
	if (player) {
		// insert into linked list
		key.kh_next = player.kh_next;
		key.kh_prev = player;
		player.kh_next = key;
		if (key.kh_next)
			key.kh_next.kh_prev = key;

		kh_Key_Attach(key);
		if not(key.kh_next) {
			// player is now a key carrier
			if (g_kh_showenemycarrier) {
				WaypointSprite_AttachCarrier("", player);
				player.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = kh_KeyCarrier_waypointsprite_visible_for_player;
				WaypointSprite_UpdateRule(player.waypointsprite_attachedforcarrier, player.team, SPRITERULE_TEAMPLAY);
				if (player.team == COLOR_TEAM1)
					WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, "keycarrier-red", "keycarrier-friend", "keycarrier-red");
				else if (player.team == COLOR_TEAM2)
					WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, "keycarrier-blue", "keycarrier-friend", "keycarrier-blue");
				else if (player.team == COLOR_TEAM3)
					WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, "keycarrier-yellow", "keycarrier-friend", "keycarrier-yellow");
				else if (player.team == COLOR_TEAM4)
					WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, "keycarrier-pink", "keycarrier-friend", "keycarrier-pink");
				WaypointSprite_UpdateTeamRadar(player.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, colormap_palette_color(player.team - 1, 0));
			} else {
				WaypointSprite_AttachCarrier("keycarrier-friend", player);
				WaypointSprite_UpdateTeamRadar(player.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '0 1 0');
			}
			if (!kh_no_radar_circles)
				WaypointSprite_Ping(player.waypointsprite_attachedforcarrier);
		}
	}
	// moved that here, also update if there's no player
	kh_update_state();
	key.pusher = NULL;
	ownerteam = kh_Key_AllOwnedByWhichTeam();
	if (ownerteam != ownerteam0) {
		if (ownerteam != -1) {
			kh_interferemsg_time = time + 0.2;
			kh_interferemsg_team = player.team;
			// audit all key carrier sprites, update them to RUN HERE
			FOR_EACH_KH_KEY(k) {
				if (k.owner)
					WaypointSprite_UpdateSprites(k.owner.waypointsprite_attachedforcarrier, k.owner.waypointsprite_attachedforcarrier.model1, "keycarrier-finish", k.owner.waypointsprite_attachedforcarrier.model3);
			}
		} else {
			kh_interferemsg_time = 0;
			// audit all key carrier sprites, update them to RUN HERE
			FOR_EACH_KH_KEY(k) {
				if (k.owner)
					WaypointSprite_UpdateSprites(k.owner.waypointsprite_attachedforcarrier, k.owner.waypointsprite_attachedforcarrier.model1, "keycarrier-friend", k.owner.waypointsprite_attachedforcarrier.model3);
			}
		}
	}
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) kh_key_damage {
	if (self.owner)
		return;

	if (vlen(force) > 0) {
		if (time > self.pushltime)
			if (attacker.classname == "player")
				self.team = (attacker ? attacker.team : 0);
	}
	if (deathtype == DEATH_HURTTRIGGER)
		entity_move_to_random_location(self, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256);
}

void(void) key_reset {
	kh_Key_Hide(self);
}

void(entity key, entity initial_owner, float angle, float i) kh_Key_Spawn { // runs every time a new flag is created, ie after all the keys have been collected
	key.count = i;
	key.classname = STR_ITEM_KH_KEY;
	key.touch = kh_Key_Touch;
	key.think = kh_key_think;
	key.nextthink = time;
	key.items = IT_KEY1 | IT_KEY2;
	key.cnt = angle;
	key.angles = '0 360 0' * random();
	key.event_damage = kh_key_damage;
	key.takedamage = DAMAGE_YES;
	setmodel(key, "models/keyhunt/key.md3");
	key.lip = 0;
	key.effects &= ~EFFECT_NODRAW;
	key.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setsize(key, KH_KEY_MIN, KH_KEY_MAX);
	key.colormod = team_color(initial_owner.team) * KH_KEY_BRIGHTNESS;
	key.reset = key_reset;
	switch (initial_owner.team) {
	case COLOR_TEAM1:
		key.netname = "^1red key";
		break;
	case COLOR_TEAM2:
		key.netname = "^4blue key";
		break;
	case COLOR_TEAM3:
		key.netname = "^3yellow key";
		break;
	case COLOR_TEAM4:
		key.netname = "^6pink key";
		break;
	default:
		key.netname = "ERROR key";
		break;
	}
	print_to_spec(initial_owner, PRINT_CENTER, "You are starting with the {1}", key.netname, "", "");  // message to player at start of round
	kh_Key_AssignTo(key, initial_owner);
}

void(entity key) kh_Key_Hide { // runs after when all the keys have been collected or when a key has been dropped for more than X seconds
	entity o;
	o = key.owner;
	kh_Key_AssignTo(key, NULL);
	key.solid = SOLID_NOT;
	key.effects |= EFFECT_NODRAW;
	kh_update_state();
}

// -1 when no team completely owns all keys yet
float(void) kh_Key_AllOwnedByWhichTeam { // constantly called. check to see if all the keys are owned by the same team
	entity key;
	float teem;
	float mykeys;
	teem = -1;
	mykeys = kh_teams;
	FOR_EACH_KH_KEY(key) {
		if (!key.owner)
			return -1;

		if (teem == -1)
			teem = key.team;
		else if (teem != key.team)
			return -1;

		--mykeys;
	}
	if (mykeys != 0)
		return -1;

	return teem;
}

void(entity key, entity player) kh_Key_Collect { //a player picks up a dropped key
	sound(player, CHAN_AUTO, kh_sound_collect, VOL_BASE, ATTN_NORM);
	if (key.lip != player.team) {
		kh_Scores_Event(player, key, g_kh_score_collect, 0);
		score_player_add(player, KH_SCORE_PICKUPS, 1);
	}
	key.lip = 0;
	print_all(PRINT_INFO, "{1}^7 picked up the {2}", player.netname, key.netname, "");
	kh_Key_AssignTo(key, player); // this also updates .kh_state
	RM(rm_hud_flash_teamcolor_default_spec(player));
}

void(entity player, float suicide, float died) kh_Key_DropAll { // runs whenever a player dies
	entity key;
	entity mypusher;
	if (player.kh_next) {
		mypusher = NULL;
		if (player.pusher)
			if (time < player.pushltime)
				mypusher = player.pusher;

		while ((key = player.kh_next)) {
			kh_Scores_Event(player, key, 0, 0);
			score_player_add(player, KH_SCORE_LOSSES, 1);
			print_all(PRINT_INFO, strcat("{1}^7 ", (died ? "died and " : ""), "lost the {2}"), player.netname, key.netname, "");
			kh_Key_AssignTo(key, NULL);
			makevectors('-1 0 0' * (45 + 45 * random()) + '0 360 0' * random());
			key.velocity = weapon_calculate_projectile_velocity(player.velocity, g_kh_dropvelocity * v_forward);
			key.pusher = mypusher;
			key.pushltime = time + g_kh_protecttime;
			if (suicide)
				key.lip = player.team;
		}
		sound(player, CHAN_AUTO, kh_sound_drop, VOL_BASE, ATTN_NORM);
	}
}

void(void) kh_Key_Touch { // runs many, many times when a key has been dropped and can be picked up
	if (map_intermission_running)
		return;

	if (kh_roundbased)
	if not(roundbased_active)
		return;

	if (self.owner) // already carried
		return;

	if (other.classname != "player")
		return;

	if (other.deadflag != DEAD_NO)
		return;

	if (other == self.enemy)
		if (time < self.kh_droptime + g_kh_delay_collect)
			return;  // you just dropped it!

	if not(plugin_chain_PlayerCanBeCarrier(other))
		return;

	self.think = kh_key_think; //in case of kh_Key_MoveToRandomLocation_Think
	kh_Key_Collect(self, other);
}

void(void) kh_key_think {  // runs all the time
	entity head;
	//entity player;  // needed by FOR_EACH_PLAYER
	if (map_intermission_running)
		return;

	if (self.owner) {
		makevectors('0 1 0' * (self.cnt + math_mod(time, 360) * KH_KEY_XYSPEED));
		setorigin(self, v_forward * KH_KEY_XYDIST + '0 0 1' * self.origin_z);
		if (self.owner.BUTTON_DROP)
		if (time >= self.owner.kh_droptime + g_kh_delay_drop) {
			self.owner.kh_droptime = time;
			self.kh_droptime = time;  // prevent collecting this one for some time
			self.enemy = self.owner;
			self.pusher = NULL;
			kh_Scores_Event(self.owner, self, 0, 0);
			print_all(PRINT_INFO, "{1}^7 dropped the {2}", self.owner.netname, self.netname, "");
			sound(self.owner, CHAN_AUTO, kh_sound_drop, VOL_BASE, ATTN_NORM);
			makevectors(self.owner.v_angle);
			self.velocity = weapon_calculate_projectile_velocity(self.owner.velocity, g_kh_throwvelocity * v_forward);
			kh_Key_AssignTo(self, NULL);
			self.pushltime = time + g_kh_protecttime;
			self.lip = self.team;
		}
	}
	// if in nodrop or time over, respawn key
	if not(self.owner) {
		if not(self.effects & EFFECT_NODRAW)
			if (time > self.pain_finished)
				kh_LoserTeam(self.team, self);

		if (self.waterlevel > 0)
		if (self.watertype == CONTENT_LAVA || self.watertype == CONTENT_SLIME)
			entity_move_to_random_location(self, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256);
	} else if (kh_Key_AllOwnedByWhichTeam() != -1) {
		if (self.nextstep < time) {
			sound(self.owner, CHAN_AUTO, kh_sound_alarm, VOL_BASE, ATTN_NORM);  // play a simple alarm
			self.nextstep = time + 2.5;  // repeat every 2.5 seconds
		}
		entity key;
		vector p;
		p = self.owner.origin;
		FOR_EACH_KH_KEY(key)
			if (vlen(key.owner.origin - p) > g_kh_maxdist)
				goto not_winning;

		kh_WinnerTeam(self.team);
:not_winning
	}
	if (kh_interferemsg_time && time > kh_interferemsg_time) {
		kh_interferemsg_time = 0;
		FOR_EACH_PLAYER (head) {
			if (head.team == kh_interferemsg_team)
				if (head.kh_next)
					print_to_spec(head, PRINT_CENTER, "All keys are in your team's hands!\n\nMeet the other key carriers ^1NOW^7!", "", "", "");
				else
					print_to_spec(head, PRINT_CENTER, "All keys are in your team's hands!\n\nHelp the key carriers to meet!", "", "", "");
			else
				print_to_spec(head, PRINT_CENTER, "All keys are in the {1}^7's hands!\n\nInterfere ^1NOW^7!", team_colored_name(kh_interferemsg_team), "", "");
		}
	}
	self.nextthink = time + 0.05;
}

void(float teem) kh_WinnerTeam { // runs when a team wins
	// all key carriers get some points
	vector firstorigin = '0 0 0', lastorigin = '0 0 0', midpoint = '0 0 0';
	float first;
	entity key;
	float score;
	score = (kh_teams - 1) * g_kh_score_capture;
	float f = floor(score / kh_teams);
	// twice the score for 3 team games, three times the score for 4 team games!
	// note: for a win by destroying the key, this should NOT be applied
	FOR_EACH_KH_KEY(key) {
		if (kh_roundbased)
			score_player_add(key.owner, KH_SCORE_CAPS, 1);
		else {
			score_player_team_add(key.owner, KH_SCORE_CAPS, KH_SCORE_TEAM_CAPS, 1);
			kh_Scores_Event(key.owner, key, f, 0);
		}
	}
	if (kh_roundbased)
		score_team_add_to(teem, KH_SCORE_TEAM_CAPS, 1);

	string s = "";
	first = TRUE;
	FOR_EACH_KH_KEY(key)
		if (key.owner.kh_next == key) {
			if (!first)
				s = strcat(s, "^7, ");

			s = strcat(s, key.owner.netname);
			first = FALSE;
		}
	print_all(PRINT_INFO, "{1}^7 captured the keys for the {2}", s, team_colored_name(teem), "");
	if (kh_roundbased)
		roundbased_round_start_with_winner(other.team, "");

	first = TRUE;
	midpoint = '0 0 0';
	vector thisorigin;
	FOR_EACH_KH_KEY(key) {
		thisorigin = ENTITY_CENTER(key.owner);
		//dprint("Key origin: ", vtos(thisorigin), "\n");
		midpoint += thisorigin;
		if (!first)
			te_lightning2(NULL, lastorigin, thisorigin);

		lastorigin = thisorigin;
		if (first)
			firstorigin = thisorigin;

		first = FALSE;
	}
	if (kh_teams > 2) {
		te_lightning2(NULL, lastorigin, firstorigin);
	}
	midpoint = midpoint * (1 / kh_teams);
	te_customflash(midpoint, 1000, 1, team_color(teem) * 0.5 + '0.5 0.5 0.5');  // make the color >=0.5 in each component
	sound_play2all(kh_sound_capture);
	kh_FinishRound();
	if (rm_active) {
		entity pl;
		FOR_EACH_REALCLIENT(pl)
			if (pl.team == teem)
				rm_hud_flash_teamcolor_default_spec(pl);
	}
}

void(void) kh_Key_MoveToRandomLocation_Think {
	vector v = self.origin;
	if (entity_move_to_random_location(self, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 30, 1024, 256)) {
		print_all(PRINT_INFO, "The {1}^7 respawned", self.netname, "", "");
		self.pain_finished = time + g_kh_delay_return;
		self.think = kh_key_think;
		sound_play2all(kh_sound_destroy);
		te_tarexplosion(v);
	}
	self.nextthink = time;
}

void(float teem, entity lostkey) kh_LoserTeam { // runs when a player pushes a flag carrier off the map
	entity player, key, attacker;
	float players;
	float mykeys;
	attacker = NULL;
	if (lostkey.pusher)
		if (lostkey.pusher.team != teem)
			if (lostkey.pusher.classname == "player")
				attacker = lostkey.pusher;

	players = mykeys = 0;
	if (attacker) {
		if (lostkey.realowner && lostkey.playerid == lostkey.realowner.playerid)
			kh_Scores_Event(lostkey.realowner, NULL, 0, - g_kh_score_push);
			// don't actually GIVE him the -nn points, just log
		kh_Scores_Event(attacker, NULL, g_kh_score_push, 0);
		score_player_add(attacker, KH_SCORE_PUSHES, 1);
		print_to_spec(attacker, PRINT_CENTER, "Your push is the best!", "", "", "");
		print_all(PRINT_INFO, "The {1}^7 could not take care of the {2}^7 when {3}^7 came", team_colored_name(teem), lostkey.netname, attacker.netname);
	} else {
		FOR_EACH_PLAYER(player)
			if (player.team != teem)
				++players;

		FOR_EACH_KH_KEY(key)
			if (key.owner && key.team != teem)
				++mykeys;

		if (lostkey.realowner && lostkey.playerid == lostkey.realowner.playerid)
			kh_Scores_Event(lostkey.realowner, NULL, 0, - g_kh_score_destroyed);
			// don't actually GIVE him the -nn points, just log

		if (lostkey.realowner.playerid == lostkey.playerid)
			score_player_add(lostkey.realowner, KH_SCORE_DESTROYS, 1);

		print_all(PRINT_INFO, "The {1}^7 could not take care of the {2}", team_colored_name(teem), lostkey.netname, "");
	}
	lostkey.think = kh_Key_MoveToRandomLocation_Think;
}

void(void) kh_FinishRound { // runs when a team captures the keys
	// prepare next round
	kh_interferemsg_time = 0;
	entity key;
	kh_no_radar_circles = TRUE;
	FOR_EACH_KH_KEY(key)
		kh_Key_Hide(key);

	kh_no_radar_circles = FALSE;
	kh_Controller_SetThink(g_kh_delay_round, "Round starts in {1}", kh_StartRound);
}

string(void) kh_CheckEnoughPlayers { // checks enough player are present, runs after every completed round
	float i, players, teem;
	entity player;
	// find a random player per team
	str_unzone_ifneeded(kh_teams_missed);
	kh_teams_missed = "";
	for (i = 0; i < kh_teams; ++i) {
		teem = team_from_index(i);
		players = 0;
		FOR_EACH_PLAYER(player)
			if (player.deadflag == DEAD_NO)
				if ( !player.BUTTON_CHAT)
					if (player.team == teem)
						++players;

		if (players == 0) {
			if (kh_teams_missed != "")
				kh_teams_missed = strcat(kh_teams_missed, ", ");

			kh_teams_missed = strcat(kh_teams_missed, team_colored_name(teem));
		}
	}
	kh_teams_missed = str_zone_ifneeded(kh_teams_missed);
	return kh_teams_missed;;
}

void(void) kh_WaitForPlayers { // delay start of the round until enough players are present
	string teams_missing;
	if (time < map_starttime) {
		kh_Controller_SetThink(map_starttime - time + 0.1, "", kh_WaitForPlayers);
		return;
	}
	teams_missing = kh_CheckEnoughPlayers();
	if (teams_missing == "")
		kh_Controller_SetThink((kh_roundbased ? 0 : g_kh_delay_round), "Round starts in {1}", kh_StartRound);
	else
		kh_Controller_SetThink(1, "Waiting for players to join...\n\nNeed active players for: {2}", kh_WaitForPlayers);
}

void(void) kh_StartRound { // runs at the start of each round
	string teams_missing;
	float i, players, teem;
	entity player;
	if (time < map_starttime) {
		kh_Controller_SetThink(map_starttime - time + 0.1, "", kh_WaitForPlayers);
		return;
	}
	teams_missing = kh_CheckEnoughPlayers();
	if (teams_missing != "") {
		kh_Controller_SetThink(1, "Waiting for players to join...\n\nNeed active players for: {2}", kh_WaitForPlayers);
		return;
	}
	if not(kh_roundbased)
		game_status_set("", 1, "", "", "");

	entity key;
	i = 0;
	FOR_EACH_KH_KEY(key) {
		teem = team_from_index(i);
		players = 0;
		entity my_player = NULL;
		FOR_EACH_PLAYER(player)
			if (player.deadflag == DEAD_NO)
				if (!player.BUTTON_CHAT)
					if (player.team == teem) {
						++players;
						if (random() * players <= 1)
							my_player = player;
					}
		kh_Key_Spawn(key, my_player, 360 * i / kh_teams, i);
		i++;
	}
	kh_tracking_enabled = FALSE;
	if (g_kh_showenemycarrier)
		kh_Controller_SetThink((kh_roundbased ? 0 : g_kh_delay_tracking), "\nScanning frequency range...", kh_EnableTrackingDevice);
}

void(void) kh_EnableTrackingDevice { // runs after each round
	if not(kh_roundbased)
		game_status_set("", 1, "", "", "");

	kh_tracking_enabled = TRUE;
}

float(entity e) kh_Key_waypointsprite_visible_for_player {
	if (!kh_tracking_enabled)
	if (g_kh_showenemycarrier)
		return FALSE;

	if (self.owner.effects & EFFECT_NODRAW)
		return FALSE;

	if (!self.owner.owner)
		return TRUE;

	return FALSE;  // draw only when key is not owned
}

float(entity e) kh_KeyCarrier_waypointsprite_visible_for_player { // runs all the time
	if (e.classname != "player" || self.team != e.team)
		if (!kh_tracking_enabled)
			return FALSE;

	return TRUE;
}

float(entity attacker, entity targ, float f) kh_HandleFrags { // adds to the player score
	if (attacker == targ)
		return f;

	if (targ.kh_next) {
		if (attacker.team == targ.team) {
			entity k;
			float nk;
			nk = 0;
			for (k = targ.kh_next; k; k = k.kh_next)
				++nk;

			kh_Scores_Event(attacker, targ.kh_next, -nk * g_kh_score_collect, 0);
		} else {
			kh_Scores_Event(attacker, targ.kh_next, g_kh_score_carrierfrag - 1, 0);
			score_player_add(attacker, KH_SCORE_KCKILLS, 1);
			RM(rm_hud_flash_teamcolor_default_spec(attacker));
			// the frag gets added later
		}
	}
	return f;
}

var void(float killed) kh_PlayerClear_NextLink;
void kh_PlayerClear(float killed) {
	kh_Key_DropAll(self, TRUE, killed);
	kh_PlayerClear_NextLink(killed);
}

float(entity attacker, entity inflictor, float deathtype) kh_DeathHandle {
	if (self == attacker)
		kh_Key_DropAll(self, TRUE, TRUE);
	else if ((attacker.classname == "player"))
		kh_Key_DropAll(self, FALSE, TRUE);

	return FALSE;
}

void(void) kh_WaitRoundBegin {
	if (roundbased_active)
		kh_Controller_SetThink(0, "", kh_WaitForPlayers);
	else
		kh_Controller_SetThink(1, "", kh_WaitRoundBegin);
}

void(void) kh_Reset {
	if (kh_roundbased)
		kh_Controller_SetThink(0, "", kh_WaitRoundBegin);
	else
		kh_Controller_SetThink(g_kh_delay_round + max(0, map_starttime - time), "", kh_WaitForPlayers);
}

var void(entity e) kh_SpectateCopy_NextLink;
void(entity e) kh_SpectateCopy {
	self.kh_state = e.kh_state;
	kh_SpectateCopy_NextLink(e);
}

float(entity plr) kh_player_is_carrier { return (plr.kh_next ? TRUE :FALSE); }
void(entity plr) kh_player_drop_carried { kh_Key_DropAll(plr, FALSE, FALSE); }
float(entity e) kh_portal_forbidden_for { return e.classname == STR_ITEM_KH_KEY; }

void(void) kh_init_delayed { // sets up th KH environment
	CVAR_CACHE(g_kh_damageforcescale);
	CVAR_CACHE(g_kh_delay_collect);
	CVAR_CACHE(g_kh_delay_drop);
	CVAR_CACHE(g_kh_delay_return);
	CVAR_CACHE(g_kh_delay_round);
	CVAR_CACHE(g_kh_delay_tracking);
	CVAR_CACHE(g_kh_dropvelocity);
	CVAR_CACHE(g_kh_maxdist);
	CVAR_CACHE(g_kh_protecttime);
	CVAR_CACHE(g_kh_score_capture);
	CVAR_CACHE(g_kh_score_carrierfrag);
	CVAR_CACHE(g_kh_score_collect);
	CVAR_CACHE(g_kh_score_destroyed);
	CVAR_CACHE(g_kh_score_push);
	CVAR_CACHE(g_kh_throwvelocity);
	CVAR_CACHE(g_kh_showenemycarrier);
	kh_controller = spawn();
	kh_controller.think = kh_Controller_Think;
	kh_controller.reset2 = kh_Reset;
	addstat(STAT_KH_KEYS, STAT_INT, kh_state);
	if (game_type == GAME_TYPE_KEYHUNT_CA || game_type == GAME_TYPE_KEYHUNT_FT)
		kh_roundbased = TRUE;

	if (kh_roundbased)
		kh_Controller_SetThink(0, "", kh_WaitRoundBegin);
	else
		kh_Controller_SetThink(0, "", kh_WaitForPlayers);

	score_basics(SCORE_FLAG_SORT_PRIO_PRIMARY, (kh_roundbased ? 0 : SCORE_FLAG_SORT_PRIO_PRIMARY), TRUE);
	KH_SCORE_TEAM_CAPS = score_register_team_score("caps", (kh_roundbased ? SCORE_FLAG_SORT_PRIO_PRIMARY : SCORE_FLAG_SORT_PRIO_SECONDARY));
	KH_SCORE_CAPS = score_register("caps", SCORE_FLAG_SORT_PRIO_SECONDARY);
	KH_SCORE_PUSHES = score_register("pushes", 0);
	KH_SCORE_DESTROYS = score_register("destroyed", SCORE_FLAG_LOWER_IS_BETTER);
	KH_SCORE_PICKUPS = score_register("pickups", 0);
	KH_SCORE_KCKILLS = score_register("kckills", 0);
	KH_SCORE_LOSSES = score_register("losses", SCORE_FLAG_LOWER_IS_BETTER);
	if (kh_roundbased) {
		if (game_type == GAME_TYPE_KEYHUNT_CA)
			clanarena_shared_init("khca");
		else if (game_type == GAME_TYPE_KEYHUNT_FT)
			freeze_shared_init("khft");

		roundbased_score_field_set(KH_SCORE_TEAM_CAPS);
	}
	float i;
	entity key;
	for (i = 0; i < kh_teams; i++) {
		key = spawn();
		key.effects = EFFECT_NODRAW;
		key.weaponentity = kh_worldkeylist; //use weaponentity field for global key chain
		kh_worldkeylist = key;
		key.team = team_from_index(i);
		WaypointSprite_Spawn("key-dropped", 0, 0, key, '0 0 1' * KH_KEY_WP_ZSHIFT, NULL, 0, key, waypointsprite_attachedforcarrier, FALSE);
		key.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = kh_Key_waypointsprite_visible_for_player;
		WaypointSprite_UpdateTeamRadar(key.waypointsprite_attachedforcarrier, RADARICON_FLAG, '0 1 1');
	}
	plugin_score_give_frag_mod = kh_HandleFrags;
}

void(void) kh_init {
	entity_initialize(NULL, kh_init_delayed, INITPRIO_GAMETYPE);
	precache_sound(kh_sound_capture);
	precache_sound(kh_sound_destroy);
	precache_sound(kh_sound_drop);
	precache_sound(kh_sound_collect);
	precache_sound(kh_sound_alarm);  // the new siren
	plugin_player_death_handle = kh_DeathHandle;
	kh_PlayerClear_NextLink = plugin_chain_player_clear;
	plugin_chain_player_clear = kh_PlayerClear;
	plugin_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	kh_SpectateCopy_NextLink = plugin_chain_spectator_copy;
	plugin_chain_spectator_copy = kh_SpectateCopy;
	plugin_player_is_carrier = kh_player_is_carrier;
	plugin_player_drop_carried = kh_player_drop_carried;
	plugin_portal_forbidden_for = kh_portal_forbidden_for;
	plugin_havocbot_role_choose = kh_role_choose;
	precache_model("models/keyhunt/key.md3");
	kh_teams = bound(2, cvar("g_kh_teams"), 4);
	team_teams_set_count(kh_teams);
}

void kh_update_state(void) {
	entity player;
	entity key;
	float s;
	float f;
	s = 0;
	FOR_EACH_KH_KEY(key) {
		if (key.owner)
			f = key.team;
		else
			f = 30;

		s |= pow(32, key.count) * f;
	}
	FOR_EACH_CLIENT(player) {
		player.kh_state = s;
	}
	FOR_EACH_KH_KEY(key) {
		if (key.owner)
			key.owner.kh_state |= pow(32, key.count) * 31;
	}
}

#undef FOR_EACH_KH_KEY
