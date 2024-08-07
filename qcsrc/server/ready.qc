#define RESTART_COUNTDOWN 10
entity ready_nagger;
float ready_ready;
float ready_wait;

float(entity to, float sendflags) ready_nagger_send {
	float nags, i, f, b;
	entity e;
	net_write_byte(MSG_ENTITY, NET_CSQC_NAGGER);
	nags = 0;
	if (ready_ready)
		nags |= 1;

	net_write_byte(MSG_ENTITY, nags);
	if (nags & 1) {
		for (i = 1; i <= client_max_count; i += 8) {
			for (f = 0, e = edict_num(i), b = 1; b < 256; b *= 2, e = nextent(e))
				if (clienttype(e) != CLIENTTYPE_REAL || e.ready)
					f |= b;

			net_write_byte(MSG_ENTITY, f);
		}
	}
	return TRUE;
}

void(void) ready_nagger_init {
	net_link_entity(ready_nagger = spawn(), FALSE, 0, ready_nagger_send);
}

void(void) ready_nagger_counted {
	if (ready_nagger)
		ready_nagger.SendFlags |= 1;
}

void(void) ready_count;
entity ready_restart_timer;

/**
 * Restarts the map after the countdown is over (and cvar sv_ready_restart_after_countdown
 * is set)
 */
void ready_restart_timer_think() {
	world_reset(TRUE);
	score_clear_all();
	remove(self);
	map_restart_active = 0;
	return;
}

void(void) ready_restart_force {
	entity e;
	map_restart_active = 1;
	print_all(PRINT_INFO, "^1Server is restarting...", "", "", "");
	vote_reset();
	// clear overtime
	float newTL;
	if (world_check_rules_overtimesadded > 0) {
		//we have to decrease timelimit to its original value again!!
		newTL = cvar("timelimit");
		newTL -= world_check_rules_overtimesadded * cvar("g_timelimit_overtime");
		cvar_set("timelimit", ftos(newTL));
	}
	if (world_check_rules_suddendeathend) {
		newTL = (world_check_rules_suddendeathend - time) / 60;
		newTL -= cvar("g_timelimit_suddendeath");
		cvar_set("timelimit", ftos(newTL));
	}
	world_check_rules_suddendeathend = world_check_rules_overtimesadded = world_check_rules_suddendeathwarning = 0;
	ready_restart_happened = 1;
	map_starttime = time + RESTART_COUNTDOWN;
	warmup_finish();
	//reset the .ready status of all players (also spectators)
	CLIENT_FOR_EACH_SLOT(e)
		e.ready = 0;

	ready_ready = 0;
	ready_nagger_counted(); // NOTE: this causes a resend of that entity, and will also turn off warmup state on the client
	if (cvar("teamplay_lockonrestart") && team_mode) {
		team_lock = 1;
		print_all(PRINT_INFO, "^1The teams are now locked.", "", "", "");
	}
	//initiate the restart-countdown-announcer entity
	ready_restart_timer = spawn();
	ready_restart_timer.think = ready_restart_timer_think;
	ready_restart_timer.nextthink = (cvar("sv_ready_restart_after_countdown") ? map_starttime : time);
	//after a restart every players number of allowed timeouts gets reset, too
	if (cvar("sv_timeout")) {
		PLAYER_FOR_EACH_REAL(e)
			e.allowedTimeouts = cvar("sv_timeout_number");
	}
}

void(void) ready_restart {
	if (plugin_ready_restart_hard() | map_finished | map_intermission_running) {
		localcmd("\nrestart\n");
		return;
	} else
		localcmd("\nsv_hook_gamerestart;");

	ready_restart_force();
	// reset ALL scores, but only do that at the beginning
	//of the countdown if sv_ready_restart_after_countdown is off!
	//Otherwise scores could be manipulated during the countdown!
	if (!cvar("sv_ready_restart_after_countdown"))
		score_clear_all();
}

/**
 * Counts how many players are ready. If not enough players are ready, the function
 * does nothing. If all players are ready, the timelimit will be extended and the
 * restart_countdown variable is set to allow other functions like PlayerPostThink
 * to detect that the countdown is now active. If the cvar sv_ready_restart_after_countdown
 * is not set the map will be resetted.
 *
 * Function is called after the server receives a 'ready' sign from a player.
 */
void(void) ready_count {
	entity e;
	ready_ready = ready_wait = 0;
	PLAYER_FOR_EACH_REAL(e) {
		++ready_wait;
		if (e.ready)
			++ready_ready;
	}
	ready_nagger_counted();
	if (ready_ready) // at least one is ready
	if (ready_ready == ready_wait) // and, everyone is ready
		ready_restart();
}
