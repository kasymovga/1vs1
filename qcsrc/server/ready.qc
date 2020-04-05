#define RESTART_COUNTDOWN 10
entity ready_nagger;
float readycount;
float readywait;
float ready_nagger_send(entity to, float sendflags)
{
	float nags, i, f, b;
	entity e;
	WriteByte(MSG_ENTITY, ENT_CLIENT_NAGGER);

	nags = 0;
	if (readycount)
		nags |= 1;

	WriteByte(MSG_ENTITY, nags);
	if(nags & 1)
	{
		for(i = 1; i <= client_max_count; i += 8)
		{
			for(f = 0, e = edict_num(i), b = 1; b < 256; b *= 2, e = nextent(e))
				if(clienttype(e) != CLIENTTYPE_REAL || e.ready)
					f |= b;
			WriteByte(MSG_ENTITY, f);
		}
	}
	return TRUE;
}
void(void) ready_nagger_init {
	net_link_entity(ready_nagger = spawn(), FALSE, 0, ready_nagger_send);
}

void ready_nagger_counted()
{
	if(ready_nagger)
		ready_nagger.SendFlags |= 1;
}

void ready_count();
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
	local entity e;
	map_restart_active = 1;

	bprint("^1Server is restarting...\n");
	vote_reset();
	// clear overtime
	if (checkrules_overtimesadded > 0) {
		//we have to decrease timelimit to its original value again!!
		float newTL;
		newTL = cvar("timelimit");
		newTL -= checkrules_overtimesadded * cvar("timelimit_overtime");
		cvar_set("timelimit", ftos(newTL));
	}

	checkrules_suddendeathend = checkrules_overtimesadded = checkrules_suddendeathwarning = 0;


	ready_restart_happened = 1;
	map_starttime = time + RESTART_COUNTDOWN;

	warmup_finish();
	//reset the .ready status of all players (also spectators)
	FOR_EACH_CLIENTSLOT(e)
		e.ready = 0;
	readycount = 0;
	ready_nagger_counted(); // NOTE: this causes a resend of that entity, and will also turn off warmup state on the client

	if(cvar("teamplay_lockonrestart") && team_mode) {
		team_lock = 1;
		bprint("^1The teams are now locked.\n");
	}

	//initiate the restart-countdown-announcer entity
	ready_restart_timer = spawn();
	ready_restart_timer.think = ready_restart_timer_think;
	ready_restart_timer.nextthink = (cvar("sv_ready_restart_after_countdown") ? map_starttime : time);

	//after a restart every players number of allowed timeouts gets reset, too
	if(cvar("sv_timeout"))
	{
		FOR_EACH_REALPLAYER(e)
			e.allowedTimeouts = cvar("sv_timeout_number");
	}
}

void(void) ready_restart {
	if(GameHook_ReadyRestartHard() | map_finished | map_intermission_running) {
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
	local entity e;
	readycount = readywait = 0;

	FOR_EACH_REALPLAYER(e)
	{
		++readywait;
		if(e.ready)
			++readycount;
	}

	ready_nagger_counted();

	if(readycount) // at least one is ready
	if(readycount == readywait) // and, everyone is ready
		ready_restart();
}
