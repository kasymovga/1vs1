entity voip_speaker_chain;
entity voip_note;
float voip_talk_on;
.float voip_last;
float voip_volume_send_last;

string(void) voip_note_message {
	string s;
	entity e, e2;
	s = "^2VOICE CHAT [Microphone: ";
	if not(voip_group) {
		if (time > voip_volume_send_last + 1) {
			localcmd(";sendcvar voipvolume;");
			voip_volume_send_last = time;
		}
	}
	if (voip_talk_on && voip_group) { //in talk mode show everyone who able to hear
		s = strcat(s, "^1ON^2]");
		for (e = player_list.sort_next; e; e = e.sort_next) {
			if (e.scores[SP_VOIP_FIELD] != voip_group)
				continue;

			if (e.sv_entnum == player_localentnum - 1)
				s = strcat(s, "\n", player_name(e.sv_entnum), " ^3<)))");
			else {
				for (e2 = voip_speaker_chain; e2; e2 = e2.enemy) {
					if (e.sv_entnum == e2.cnt) {
						s = strcat(s, "\n", player_name(e2.cnt), " ^3<)))");
						goto continue_2;
					}
				}
				s = strcat(s, "\n", player_name(e.sv_entnum), " ^0<)))");
			}
:continue_2
		}
	} else { // in listen mode show only the ones who talk
		s = strcat(s, "^3OFF^2]");
		for (e2 = voip_speaker_chain; e2; e2 = e2.enemy) {
			s = strcat(s, "\n", player_name(e2.cnt), " ^3<)))");
		}
	}
	s = strcat(s, "\n", " ");
	return s;
}

void(void) voip_note_update {
	if (!voip_speaker_chain && !voip_talk_on) {
		if (voip_note) {
			stdproc_remove_entity(voip_note);
			voip_note = NULL;
		}
	} else {
		if (voip_note) {
			str_unzone_ifneeded(voip_note.message);
			voip_note.message = str_zone_ifneeded(voip_note_message());
		} else
			voip_note = noteline_new(voip_note_message());
	}
}

void(void) voip_draw {
	entity e, e2;
	float changed = FALSE;
	while (voip_speaker_chain && voip_speaker_chain.health < time) {
		e = voip_speaker_chain.enemy;
		remove(voip_speaker_chain);
		voip_speaker_chain = e;
		changed = TRUE;
	}
	for (e = voip_speaker_chain; e.enemy; e = e.enemy) {
		if (e.enemy.health < time) {
			e2 = e.enemy.enemy;
			remove(e.enemy);
			e.enemy = e2;
		}
		changed = TRUE;
	}
	if (changed)
		voip_note_update();
}

float(float client) voip_event { //called by engine
	if (mute_listed(client + 1)) return FALSE;
	entity e;
	for (e = voip_speaker_chain; e; e = e.enemy) {
		if (e.cnt == client) {
			e.health = time + 0.5;
			return TRUE;
		}
	}
	e = spawn();
	e.draw2dflag = 1;
	e.draw2d = voip_draw;
	e.enemy = voip_speaker_chain;
	e.cnt = client;
	e.health = time + 0.5;
	if (voip_speaker_chain) {
		voip_speaker_chain.draw2d = NULL;
		voip_speaker_chain.draw2dflag = 0;
	}
	voip_speaker_chain = e;
	voip_note_update();
	return TRUE;
}

void(float on) voip_talk { //called by engine
	voip_talk_on = on;
	voip_note_update();
}
