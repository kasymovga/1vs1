#define TIMEOUT_SLOWMO_VALUE 0.0001
entity timeout; //responsible for centerprinting the timeout countdowns and playing sounds
entity timeout_initiator; // contains the entity of the player who started the last timeout
float timeout_remaining_time; // contains the time in seconds that the active timeout has left
float timeout_remaining_leadtime; // contains the number of seconds left of the leadtime (before the timeout starts)

/**
 * When sv_timeout is used this function returs strings like
 * "Timeout begins in 2 seconds!\n" or "Timeout ends in 23 seconds!\n".
 * Called by centerprint functions
 * @param addOneSecond boolean, set to 1 if the welcome-message centerprint asks for the text
 */
string(float addOneSecond) timeout_text {
	string retStr;
	if (timeout_status == 1) {
		if (addOneSecond == 1) {
			retStr = strcat("Timeout begins in ", ftos(timeout_remaining_leadtime + 1), " seconds!\n");
		}
		else {
			retStr = strcat("Timeout begins in ", ftos(timeout_remaining_leadtime), " seconds!\n");
		}
		return retStr;
	}
	else if (timeout_status == 2) {
		if (addOneSecond) {
			retStr = strcat("Timeout ends in ", ftos(timeout_remaining_time + 1), " seconds!\n");
			//don't show messages like "Timeout ends in 0 seconds"...
			if ((timeout_remaining_time + 1) > 0)
				return retStr;
			else
				return "";
		}
		else {
			retStr = strcat("Timeout ends in ", ftos(timeout_remaining_time), " seconds!\n");
			//don't show messages like "Timeout ends in 0 seconds"...
			if (timeout_remaining_time > 0)
				return retStr;
			else
				return "";
		}
	}
	else return "";
}

/**
 * Takes care of pausing and unpausing the game.
 * Centerprints the information about an upcoming or active timeout to all active
 * players. Also plays reminder sounds.
 */
void() timeout_handler_think {
	string timeStr;
	entity plr;
	if (timeout_status == 1) {
		if (timeout_remaining_leadtime > 0) {
			timeStr = timeout_text(0);
			game_status_set(timeStr, 2);
			timeout_remaining_leadtime -= 1;
			//think again in 1 second:
			self.nextthink = time + 1;
		} else {
			//now pause the game:
			timeout_status = 2;
			//reset all the flood variables
			FOR_EACH_CLIENT(plr) {
				plr.floodcontrol_chat = plr.floodcontrol_chatteam = plr.floodcontrol_chattell = plr.floodcontrol_voice = plr.floodcontrol_voiceteam = 0;
			}
			//copy .v_angle to .lastV_angle for every player in order to fix their view during pause (see PlayerPreThink)
			FOR_EACH_REALPLAYER(plr) {
				plr.lastV_angle = plr.v_angle;
			}
			self.nextthink = time;
			slowmo_update();
		}
	} else if (timeout_status == 2) {
		if (timeout_remaining_time > 0) {
			timeStr = timeout_text(0);
			game_status_set(timeStr, 2);
			if (timeout_remaining_time == cvar("sv_timeout_resumetime")) { //play a warning sound when only <sv_timeout_resumetime> seconds are left
				sound_play2all("announcer/robotic/prepareforbattle.wav");
			}
			timeout_remaining_time -= 1;
			self.nextthink = time + TIMEOUT_SLOWMO_VALUE;
		} else {
			//unpause the game again
			timeout_remaining_time = timeout_status = 0;
			//and unlock the fixed view again once there is no timeout active anymore
			FOR_EACH_REALPLAYER(plr) {
				plr.fixangle = FALSE;
			}
			//get rid of the countdown message
			game_status_set("", 2);
			remove(self);
			return;
		}
	} else if (timeout_status == 0) { //if a player called the resumegame command (which set timeout_status to 0 already)
		game_status_set("", 2);
		remove(self);
		return;
	}
}

void() timeout_evaluate_timeout {
	if (warmup_active && !g_warmup_allow_timeout)
		return sprint(self, "\{1}^1You can not call a timeout in warmup-stage!\n");

	if (time < map_starttime )
		return sprint(self, "\{1}^1You can not call a timeout while the map is being restarted!\n");

	if (timeout_status != 2) {
		if (timeout_status == 1)
			return;

		float timelimit;
		timelimit = cvar("timelimit");
		if (timelimit) {
			float lastPossibleTimeout;
			lastPossibleTimeout = (timelimit * 60) - cvar("sv_timeout_leadtime") - 1;
			if (lastPossibleTimeout < time - map_starttime)
				return sprint(self, "\{1}^1It is too late to call a timeout now!\n");
		}
	}
	//player may not call a timeout if he has no calls left
	if (self.allowedTimeouts < 1)
		return sprint(self, "\{1}^1You already used all your timeout calls for this map!\n");
	//now all required checks are passed
	self.allowedTimeouts -= 1;
	bprint("\{1}^2* ^7", self.netname, " ^7called a timeout (", ftos(self.allowedTimeouts), " timeouts left)!\n"); //write a bprint who started the timeout (and how many he has left)
	timeout_remaining_time = cvar("sv_timeout_length");
	timeout_remaining_leadtime = cvar("sv_timeout_leadtime");
	timeout_initiator = self;
	if (timeout_status == 0) { //if another timeout was already active, don't change its status (which was 1 or 2) to 1, only change it to 1 if no timeout was active yet
		timeout_status = 1;
		//create the timeout indicator which centerprints the information to all players and takes care of pausing/unpausing
		timeout = spawn();
		timeout.think = timeout_handler_think;
	}
	timeout.nextthink = time; //always let the entity think asap
	//inform all connected clients about the timeout call
	sound_play2all("announcer/robotic/timeoutcalled.wav");
}

void(entity plr) timeout_evaluate_timein {
	if (plr && plr != timeout_initiator)
		return sprint(plr, "\{1}^1You may not abort the active timeout. Only the player who called it can do that!\n");

	if (timeout_status == 1) {
		timeout_remaining_time = timeout_status = 0;
		timeout.nextthink = time; //timeout has to take care of it immediately
		bprint(strcat("\{1}^2* ^7The timeout was aborted by ", plr.netname, " !\n"));
	} else if (timeout_status == 2) {
		//only shorten the timeout_remaining_time if it makes sense
		if (timeout_remaining_time > (cvar("sv_timeout_resumetime") + 1)) {
			bprint(strcat("\{1}^2* ^1Attention: ^7", plr.netname, " resumed the game! Prepare for battle!\n"));
			timeout_remaining_time = cvar("sv_timeout_resumetime");
			timeout.nextthink = time; //timeout has to take care of it immediately
		}
	}
}

var float(string cmd, float tokens) timeout_cmd_game_handle_NextLink;
float(string cmd, float tokens) timeout_cmd_game_handle {
	if (cmd == "timeout" || (cmd == "timeoutin" && timeout_status == 0)) {
		timeout_evaluate_timeout();
		return TRUE;
	}
	if (cmd == "timein" || (cmd == "timeoutin" && timeout_status != 0)) {
		timeout_evaluate_timein(world);
		return TRUE;
	}
	return timeout_cmd_game_handle_NextLink(cmd, tokens);
}

var float(string cmd, float tokens) timeout_ClientCommandHandle_NextLink;
float(string cmd, float tokens) timeout_ClientCommandHandle {
	if (self.flags & FL_CLIENT) {
		if (cmd == "timeout" || (cmd == "timeoutin" && timeout_status == 0)) {
			if (self.classname == "player") {
				if (vote_called)
					sprint(self, "\{1}^1You can not call a timeout while a vote is active!\n");
				else
					timeout_evaluate_timeout();
			} else
				sprint(self, "\{1}^1Only players can call a timeout!\n");

			return TRUE;
		}
		if (cmd == "timein" || (cmd == "timeoutin" && timeout_status != 0)) {
			timeout_evaluate_timein(self);
			return TRUE;
		}
	}
	return timeout_ClientCommandHandle_NextLink(cmd, tokens);
}

var float(float tempo) timeout_slowmo_update_mod_NextLink;
float(float tempo) timeout_slowmo_update_mod {
	if (timeout_status == 2)
		return TIMEOUT_SLOWMO_VALUE;

	return timeout_slowmo_update_mod_NextLink(tempo);
}

var void(void(string item, string cmd) Add_Item) timeout_gamemenu_send_NextLink;
void timeout_gamemenu_send(void(string item, string cmd) Add_Item) {
	Add_Item("Timeout/Timein", "cmd timeoutin;");
	timeout_gamemenu_send_NextLink(Add_Item);
}

void() timeout_init {
	if not(cvar("sv_timeout"))
		return;

	timeout_ClientCommandHandle_NextLink = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = timeout_ClientCommandHandle;
	timeout_cmd_game_handle_NextLink = gamehook_chain_cmd_game_handle;
	gamehook_chain_cmd_game_handle = timeout_cmd_game_handle;
	timeout_slowmo_update_mod_NextLink = gamehook_chain_slowmo_update_mod;
	gamehook_chain_slowmo_update_mod = timeout_slowmo_update_mod;
	timeout_gamemenu_send_NextLink = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = timeout_gamemenu_send;
}
