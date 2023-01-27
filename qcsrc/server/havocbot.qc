float bot_ai_bunnyhop_firstjumpdelay;
float bot_ai_bunnyhop_skilloffset;
float bot_ai_bunnyhop_startdistance;
float bot_ai_bunnyhop_stopdistance;
float bot_ai_chooseweaponinterval;
float bot_ai_dodgeupdateinterval;
float bot_ai_enemydetectioninterval;
float bot_ai_enemydetectionradius;
float bot_ai_ignoregoal_timeout;
float bot_ai_keyboard_distance;
float bot_ai_keyboard_treshold;
float bot_ai_weapon_combo;
float bot_ai_weapon_combo_threshold;

void(void) havocbot_ai {
	if (bot_cmd_execute())
		return;

	if (bot_strategytoken == self)
	if (!bot_strategytoken_taken) {
		if (self.havocbot_blockhead) {
			self.havocbot_blockhead = FALSE;
		} else {
			self.havocbot_role();
		}
		// TODO: tracewalk() should take care of this job (better path finding under water)
		// if we don't have a goal and we're under water look for a waypoint near the "shore" and push it
		if (self.deadflag != DEAD_NO)
		if (self.goalcurrent==world)
		if (self.waterlevel==WATERLEVEL_SWIMMING || self.aistatus & AI_STATUS_OUT_WATER) {
			// Look for the closest waypoint out of water
			entity newgoal, head;
			float bestdistance, distance;
			newgoal = world;
			bestdistance = 10000;
			for (head = findchain(classname, "waypoint"); head; head = head.chain) {
				distance = vlen(head.origin - self.origin);
				if (distance>10000)
					continue;

				if (head.origin_z < self.origin_z)
					continue;

				if (head.origin_z - self.origin_z - self.view_ofs_z > 100)
					continue;

				if (pointcontents(head.origin + head.maxs + '0 0 1') != CONTENT_EMPTY)
					continue;

				trace_line(self.origin + self.view_ofs , head.origin, TRUE, head);
				if (trace_fraction<1)
					continue;

				if (distance<bestdistance) {
					newgoal = head;
					bestdistance = distance;
				}
			}
			if (newgoal) {
			//	te_wizspike(newgoal.origin);
				navigation_pushroute(newgoal);
			}
		}
		// token has been used this frame
		bot_strategytoken_taken = TRUE;
	}
	if (self.deadflag != DEAD_NO)
		return;

	havocbot_chooseenemy();
	if (self.bot_chooseweapontime < time ) {
		self.bot_chooseweapontime = time + bot_ai_chooseweaponinterval;
		havocbot_chooseweapon();
	}
	havocbot_aim();
	bot_aim_lag_update();
	if (self.bot_aimtarg && self.bot_aimtarg.bot_attack) {
		self.aistatus |= AI_STATUS_ATTACKING;
		self.aistatus &= ~AI_STATUS_ROAMING;
		if (self.weapon) {
			if not(plugin_chain_bot_aim())
				weapon_action(self.weapon, WEAPON_REQUEST_AIM);

			if (bot_nofire || PLAYER_IS_INDEPENDENT(self)) {
				self.BUTTON_ATCK = FALSE;
				self.BUTTON_ATCK2 = FALSE;
			} else {
				if (self.BUTTON_ATCK||self.BUTTON_ATCK2)
					self.lastfiredweapon = self.weapon;
			}
		} else {
			if (self.bot_aimtarg.classname=="player")
				bot_aim_dir(self.bot_aimtarg.origin + self.bot_aimtarg.view_ofs - self.origin - self.view_ofs , -1);
		}
	} else if (self.goalcurrent) {
		self.aistatus |= AI_STATUS_ROAMING;
		self.aistatus &= ~AI_STATUS_ATTACKING;
		vector now,v,next;//,heading;
		float aimdistance,skillblend,distanceblend,blend;
		next = now = self.goalcurrent.origin - (self.origin + self.view_ofs);
		aimdistance = vlen(now);
		//heading = self.velocity;
		if (self.goalstack01 != self && self.goalstack01 != world && self.aistatus & AI_STATUS_RUNNING == 0 &&
				!(self.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT))
			next = self.goalstack01.origin - (self.origin + self.view_ofs);

		skillblend=bound(0,(skill+self.bot_moveskill-2.5)*0.5,1); //lower skill player can't preturn
		distanceblend=bound(0,aimdistance/bot_ai_keyboard_distance,1);
		blend = skillblend * (1-distanceblend);
		//v = (now * (distanceblend) + next * (1-distanceblend)) * (skillblend) + now * (1-skillblend);
		//v = now * (distanceblend) * (skillblend) + next * (1-distanceblend) * (skillblend) + now * (1-skillblend);
		//v = now * ((1-skillblend) + (distanceblend) * (skillblend)) + next * (1-distanceblend) * (skillblend);
		v = now + blend * (next - now);
		//v = now * (distanceblend) + next * (1-distanceblend);
		if (self.waterlevel < WATERLEVEL_SWIMMING)
			v_z = 0;

		//te_lightning2(world, self.origin, self.goalcurrent.origin);
		bot_aim_dir(v, -1);
	}
	havocbot_movetogoal();
}

void(vector destorg) havocbot_keyboard_movement {
	vector keyboard;
	float blend;
	float sk;
	sk = skill + self.bot_moveskill;
	if (time < self.havocbot_keyboardtime)
		return;

	self.havocbot_keyboardtime = max(self.havocbot_keyboardtime
			+ bound(0,0.05/(sk+self.havocbot_keyboardskill),0.05)
			+ random()*bound(0,0.025/(skill+self.havocbot_keyboardskill),100)
			, time);
	keyboard = self.movement * (1.0 / sv_maxspeed);
	float trigger, trigger1;
	blend = bound(0,sk*0.1,1);
	trigger = bot_ai_keyboard_treshold;
	trigger1 = 0 - trigger;
	// categorize forward movement
	// at skill < 1.5 only forward
	// at skill < 2.5 only individual directions
	// at skill < 4.5 only individual directions, and forward diagonals
	// at skill >= 4.5, all cases allowed
	if (keyboard_x > trigger) {
		keyboard_x = 1;
		if (sk < 2.5)
			keyboard_y = 0;
	} else if (keyboard_x < trigger1 && sk > 1.5) {
		keyboard_x = -1;
		if (sk < 4.5)
			keyboard_y = 0;
	} else {
		keyboard_x = 0;
		if (sk < 1.5)
			keyboard_y = 0;
	}
	if (sk < 4.5)
		keyboard_z = 0;

	if (keyboard_y > trigger)
		keyboard_y = 1;
	else if (keyboard_y < trigger1)
		keyboard_y = -1;
	else
		keyboard_y = 0;

	if (keyboard_z > trigger)
		keyboard_z = 1;
	else if (keyboard_z < trigger1)
		keyboard_z = -1;
	else
		keyboard_z = 0;

	self.havocbot_keyboard = keyboard * sv_maxspeed;
	if (self.havocbot_ducktime>time) self.BUTTON_CROUCH=TRUE;
	keyboard = self.havocbot_keyboard;
	blend = bound(0,vlen(destorg-self.origin)/bot_ai_keyboard_distance,1); // When getting close move with 360 degree
	self.movement = self.movement + (keyboard - self.movement) * blend;
}

void(vector dir) havocbot_bunnyhop {
	float bunnyhopdistance;
	vector deviation;
	// Don't jump when using some weapons
	if (self.aistatus & AI_STATUS_ATTACKING)
	if (self.weapon & WEAPON_CAMPINGRIFLE)
		return;

	if (self.goalcurrent.classname == "player")
		return;

	if (self.aistatus & AI_STATUS_DANGER_AHEAD) {
		self.aistatus &= ~AI_STATUS_RUNNING;
		self.BUTTON_JUMP = FALSE;
		self.bot_canruntogoal = 0;
		self.bot_timelastseengoal = 0;
		return;
	}
	if (self.waterlevel > WATERLEVEL_WETFEET) {
		self.aistatus &= ~AI_STATUS_RUNNING;
		return;
	}
	if (self.bot_lastseengoal != self.goalcurrent && !(self.aistatus & AI_STATUS_RUNNING)) {
		self.bot_canruntogoal = 0;
		self.bot_timelastseengoal = 0;
	}
	bunnyhopdistance = vlen(self.origin - self.goalcurrent.origin);
	// Run only to visible goals
	if (self.flags & FL_ONGROUND)
	if (self.speed==sv_maxspeed)
	if (checkpvs(self.origin + self.view_ofs, self.goalcurrent)) {
			self.bot_lastseengoal = self.goalcurrent;
			// seen it before
			if (self.bot_timelastseengoal) {
				// for a period of time
				if (time - self.bot_timelastseengoal > bot_ai_bunnyhop_firstjumpdelay) {
					float checkdistance;
					checkdistance = TRUE;
					// don't run if it is too close
					if (self.bot_canruntogoal==0) {
						if (bunnyhopdistance > bot_ai_bunnyhop_startdistance)
							self.bot_canruntogoal = 1;
						else
							self.bot_canruntogoal = -1;
					}
					if (self.bot_canruntogoal != 1)
						return;

					if (self.aistatus & AI_STATUS_ROAMING)
					if (self.goalcurrent.classname=="waypoint")
					if not(self.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL)
					if (fabs(self.goalcurrent.origin_z - self.origin_z) < self.maxs_z - self.mins_z)
					if (self.goalstack01!=world) {
						deviation = vectoangles(self.goalstack01.origin - self.origin) - vectoangles(self.goalcurrent.origin - self.origin);
						while (deviation_y < -180) deviation_y = deviation_y + 360;
						while (deviation_y > 180) deviation_y = deviation_y - 360;
						if (fabs(deviation_y) < 20)
						if (bunnyhopdistance < vlen(self.origin - self.goalstack01.origin))
						if (fabs(self.goalstack01.origin_z - self.goalcurrent.origin_z) < self.maxs_z - self.mins_z) {
							if (vlen(self.goalcurrent.origin - self.goalstack01.origin) > bot_ai_bunnyhop_startdistance)
							if (checkpvs(self.origin + self.view_ofs, self.goalstack01)) {
								checkdistance = FALSE;
							}
						}
					}
					if (checkdistance) {
						self.aistatus &= ~AI_STATUS_RUNNING;
						if (bunnyhopdistance > bot_ai_bunnyhop_stopdistance)
							self.BUTTON_JUMP = TRUE;
					} else {
						self.aistatus |= AI_STATUS_RUNNING;
						self.BUTTON_JUMP = TRUE;
					}
				}
			} else {
				self.bot_timelastseengoal = time;
			}
	} else {
		self.bot_timelastseengoal = 0;
	}
	// Release jump button
	if (self.flags & FL_ONGROUND == 0) {
		if (self.velocity_z < 0 || vlen(self.velocity)<sv_maxspeed)
		if not(self.aistatus & AI_STATUS_JETPACK_FLYING)
			self.BUTTON_JUMP = FALSE;

		// Strafe
		if (self.aistatus & AI_STATUS_RUNNING)
		if (vlen(self.velocity)>sv_maxspeed) {
			deviation = vectoangles(dir) - vectoangles(self.velocity);
			while (deviation_y < -180) deviation_y = deviation_y + 360;
			while (deviation_y > 180) deviation_y = deviation_y - 360;
			if (fabs(deviation_y)>10)
				self.movement_x = 0;

			if (deviation_y>10)
				self.movement_y = sv_maxspeed * -1;
			else if (deviation_y<10)
				self.movement_y = sv_maxspeed;
		}
	}
}

void(void) havocbot_use_jetpack {
	if (self.flags & FL_JUMPRELEASED)
		self.BUTTON_JUMP = TRUE;
	else
		self.BUTTON_JUMP = FALSE;
}

void(void) havocbot_movetogoal {
	vector destorg;
	vector diff;
	vector dir;
	vector flatdir;
	vector m1;
	vector m2;
	vector evadeobstacle;
	vector evadelava;
	float s;
	vector dodge;
	self.movement = '0 0 0';
	if (self.bot_dontmove >= time)
		return;

	if (self.goalcurrent)
	if (wasfreed(self.goalcurrent))
		self.goalcurrent = NULL;

	// Jetpack navigation
	if (self.navigation_jetpack_goal)
	if (self.goalcurrent==self.navigation_jetpack_goal)
	if (self.ammo_fuel || (self.items & IT_UNLIMITED_WEAPON_AMMO)) {
		// Take off
		if not(self.aistatus & AI_STATUS_JETPACK_FLYING) {
			// Brake almost completely so it can get a good direction
			if (vlen(self.velocity - self.velocity_z * '0 0 1')>10)
				return;

			self.aistatus |= AI_STATUS_JETPACK_FLYING;
		}
		makevectors(self.v_angle_y * '0 1 0');
		dir = normalize(self.navigation_jetpack_point - self.origin);
		// Landing
		if (self.aistatus & AI_STATUS_JETPACK_LANDING) {
			// Calculate brake distance in xy
			float db, v, d;
			vector dxy;
			dxy = self.origin - self.goalcurrent.origin; dxy_z = 0;
			d = vlen(dxy);
			v = vlen(self.velocity -  self.velocity_z * '0 0 1');
			db = (pow(v,2) / (g_jetpack_acceleration_side * 2)) + 100;
			if (d < db || d < 500) {
				// Brake
				if (fabs(self.velocity_x)>sv_maxspeed*0.3) {
					self.movement_x = dir * v_forward * -sv_maxspeed;
					return;
				}
				// Switch to normal mode
				self.navigation_jetpack_goal = world;
				self.aistatus &= ~AI_STATUS_JETPACK_LANDING;
				self.aistatus &= ~AI_STATUS_JETPACK_FLYING;
				return;
			}
		} else if (checkpvs(self.origin,self.goalcurrent)) {
			// If I can see the goal switch to landing code
			self.aistatus &= ~AI_STATUS_JETPACK_FLYING;
			self.aistatus |= AI_STATUS_JETPACK_LANDING;
			return;
		}
		// Flying
		havocbot_use_jetpack();
		if (self.navigation_jetpack_point_z - PL_MAX_z + PL_MIN_z < self.origin_z) {
			self.movement_x = dir * v_forward * sv_maxspeed;
			self.movement_y = dir * v_right * sv_maxspeed;
		}
		return;
	}
	// If there is a trigger_hurt right below try to use the jetpack or make a rocketjump
	if (skill>6)
	if not(self.flags & FL_ONGROUND) {
		trace_box(self.origin, self.mins, self.maxs, self.origin + '0 0 -65536', TRACE_MOVE_NOMONSTERS, self);
		if (trigger_tracebox_hits_hurt(self.origin, self.mins, self.maxs, trace_endpos ))
		if (self.items & IT_JETPACK) {
			trace_box(self.origin, self.mins, self.maxs, self.origin + '0 0 65536', TRACE_MOVE_NOMONSTERS, self);
			if (trigger_tracebox_hits_hurt(self.origin, self.mins, self.maxs, trace_endpos + '0 0 1' )) {
				if (self.velocity_z<0) {
					havocbot_use_jetpack();
				}
			} else
				havocbot_use_jetpack();

			// If there is no goal try to move forward
			if (self.goalcurrent==world)
				dir = v_forward;
			else
				dir = normalize(self.goalcurrent.origin - self.origin);

			vector xyvelocity = self.velocity; xyvelocity_z = 0;
			float xyspeed = xyvelocity * dir;
			if (xyspeed < (sv_maxspeed / 2)) {
				makevectors(self.v_angle_y * '0 1 0');
				trace_box(self.origin, self.mins, self.maxs, self.origin + (dir * sv_maxspeed * 3), TRACE_MOVE_NOMONSTERS, self);
				if (trace_fraction==1) {
					self.movement_x = dir * v_forward * sv_maxspeed;
					self.movement_y = dir * v_right * sv_maxspeed;
					if (skill < 10)
						havocbot_keyboard_movement(self.origin + dir * 100);
				}
			}
			self.havocbot_blockhead = TRUE;
			return;
		} else if (self.health>g_balance_rocketlauncher_damage*0.5) {
			if (self.velocity_z < 0)
			if (weapon_carried(self, WEAPON_ROCKET_LAUNCHER, TRUE, FALSE)) {
				self.movement_x = sv_maxspeed;
				if (self.rocketjumptime) {
					if (time > self.rocketjumptime) {
						self.BUTTON_ATCK2 = TRUE;
						self.rocketjumptime = 0;
					}
					return;
				}
				self.switchweapon = WEAPON_ROCKET_LAUNCHER;
				self.v_angle_x = 90;
				self.BUTTON_ATCK = TRUE;
				self.rocketjumptime = time + g_balance_rocketlauncher_detonatedelay;
				return;
			}
		} else {
			// If there is no goal try to move forward
			if (self.goalcurrent==world)
				self.movement_x = sv_maxspeed;
		}
	}
	// If we are under water with no goals, swim up
	if (self.waterlevel)
	if (self.goalcurrent==world) {
		dir = '0 0 0';
		if (self.waterlevel>WATERLEVEL_SWIMMING)
			dir_z = 1;
		else if (self.velocity_z >= 0 && !(self.waterlevel == WATERLEVEL_WETFEET && self.watertype == CONTENT_WATER))
			self.BUTTON_JUMP = TRUE;
		else
			self.BUTTON_JUMP = FALSE;

		makevectors(self.v_angle_y * '0 1 0');
		self.movement_x = dir * v_forward * sv_maxspeed;
		self.movement_y = dir * v_right * sv_maxspeed;
		self.movement_z = dir * v_up * sv_maxspeed;
	}
	// if there is nowhere to go, exit
	if (self.goalcurrent == world)
		return;

	if (self.goalcurrent)
		navigation_poptouchedgoals();

	// if ran out of goals try to use an alternative goal or get a new strategy asap
	if (self.goalcurrent == world) {
		self.bot_strategytime = 0;
		return;
	}
	m1 = self.goalcurrent.origin + self.goalcurrent.mins;
	m2 = self.goalcurrent.origin + self.goalcurrent.maxs;
	destorg = self.origin;
	destorg_x = bound(m1_x, destorg_x, m2_x);
	destorg_y = bound(m1_y, destorg_y, m2_y);
	destorg_z = bound(m1_z, destorg_z, m2_z);
	diff = destorg - self.origin;
	//dist = vlen(diff);
	dir = normalize(diff);
	flatdir = diff;flatdir_z = 0;
	flatdir = normalize(flatdir);
	evadeobstacle = '0 0 0';
	evadelava = '0 0 0';
	if (self.waterlevel) {
		if (self.waterlevel>WATERLEVEL_SWIMMING) {
		//	flatdir_z = 1;
			self.aistatus |= AI_STATUS_OUT_WATER;
		} else {
			if (self.velocity_z >= 0 && !(self.watertype == CONTENT_WATER && self.goalcurrent.origin_z < self.origin_z) &&
					(!(self.waterlevel == WATERLEVEL_WETFEET && self.watertype == CONTENT_WATER) || self.aistatus & AI_STATUS_OUT_WATER))
				self.BUTTON_JUMP = TRUE;
			else
				self.BUTTON_JUMP = FALSE;
		}
		dir = normalize(flatdir);
		makevectors(self.v_angle_y * '0 1 0');
	} else {
		if (self.aistatus & AI_STATUS_OUT_WATER)
			self.aistatus &= ~AI_STATUS_OUT_WATER;

		// jump if going toward an obstacle that doesn't look like stairs we
		// can walk up directly
		trace_box(self.origin, self.mins, self.maxs, self.origin + self.velocity * 0.2, FALSE, self);
		if (trace_fraction < 1)
		if (trace_plane_normal_z < 0.7) {
			s = trace_fraction;
			trace_box(self.origin + '0 0 16', self.mins, self.maxs, self.origin + self.velocity * 0.2 + '0 0 16', FALSE, self);
			if (trace_fraction < s + 0.01)
			if (trace_plane_normal_z < 0.7) {
				s = trace_fraction;
				trace_box(self.origin + '0 0 48', self.mins, self.maxs, self.origin + self.velocity * 0.2 + '0 0 48', FALSE, self);
				if (trace_fraction > s)
					self.BUTTON_JUMP = 1;
			}
		}
		// avoiding dangers and obstacles
		vector dst_ahead, dst_down;
		makevectors(self.v_angle_y * '0 1 0');
		dst_ahead = self.origin + self.view_ofs + (self.velocity * 0.4) + (v_forward * 32 * 3);
		dst_down = dst_ahead + '0 0 -1500';
		// Look ahead
		trace_line(self.origin + self.view_ofs , dst_ahead, TRUE, world);
		// Check head-banging against walls
		if (vlen(self.origin + self.view_ofs - trace_endpos) < 25 && !(self.aistatus & AI_STATUS_OUT_WATER)) {
			self.BUTTON_JUMP = TRUE;
			if (self.facingwalltime && time > self.facingwalltime) {
				self.ignoregoal = self.goalcurrent;
				self.ignoregoaltime = time + bot_ai_ignoregoal_timeout;
				self.bot_strategytime = 0;
				return;
			} else {
				self.facingwalltime = time + 0.05;
			}
		} else {
			self.facingwalltime = 0;
			if (self.ignoregoal != world && time > self.ignoregoaltime) {
				self.ignoregoal = world;
				self.ignoregoaltime = 0;
			}
		}
		// Check for water/slime/lava and dangerous edges
		// (only when the bot is on the ground or jumping intentionally)
		self.aistatus &= ~AI_STATUS_DANGER_AHEAD;
		if (trace_fraction == 1)
		if (self.flags & FL_ONGROUND || self.aistatus & AI_STATUS_RUNNING || self.BUTTON_JUMP == TRUE) {
			// Look downwards
			trace_line(dst_ahead , dst_down, TRUE, world);
			if (trace_endpos_z < self.origin_z + self.mins_z) {
				s = pointcontents(trace_endpos + '0 0 1');
				if (s != CONTENT_SOLID)
				if (s == CONTENT_LAVA || s == CONTENT_SLIME)
					evadelava = normalize(self.velocity) * -1;
				else if (s == CONTENT_SKY)
					evadeobstacle = normalize(self.velocity) * -1;
				else if (!math_boxes_overlap(dst_ahead - self.view_ofs + self.mins, dst_ahead - self.view_ofs + self.maxs,
						self.goalcurrent.absmin, self.goalcurrent.absmax)) {
					// if ain't a safe goal with "holes" (like the jumpad on soylent)
					// and there is a trigger_hurt below
					if (trigger_tracebox_hits_hurt(dst_ahead, self.mins, self.maxs, trace_endpos)) {
						// Remove dangerous dynamic goals from stack
						if (self.goalcurrent.classname == "player" || self.goalcurrent.classname == "droppedweapon")
							navigation_poproute();

						// try to stop
						flatdir = '0 0 0';
						evadeobstacle = normalize(self.velocity) * -1;
					}
				}
			}
		}
		dir = flatdir;
		evadeobstacle_z = 0;
		evadelava_z = 0;
		makevectors(self.v_angle_y * '0 1 0');
		if (evadeobstacle!='0 0 0'||evadelava!='0 0 0')
			self.aistatus |= AI_STATUS_DANGER_AHEAD;
	}
	dodge = havocbot_dodge();
	dodge = dodge * bound(0,0.5+(skill+self.bot_dodgeskill)*0.1,1);
	evadelava = evadelava * bound(1,3-(skill+self.bot_dodgeskill),3); //Noobs fear lava a lot and take more distance from it
	trace_line(self.origin, self.enemy.origin, TRUE, world);
	if (trace_ent.classname == "player")
		dir = dir * bound(0,(skill+self.bot_dodgeskill)/7,1);

	dir = normalize(dir + dodge + evadeobstacle + evadelava);
	if (time < self.ladder_time) {
		if (self.goalcurrent.origin_z + self.goalcurrent.mins_z > self.origin_z + self.mins_z) {
			if (self.origin_z + self.mins_z  < self.ladder_entity.origin_z + self.ladder_entity.maxs_z)
				dir_z = 1;
		} else {
			if (self.origin_z + self.mins_z  > self.ladder_entity.origin_z + self.ladder_entity.mins_z)
				dir_z = -1;
		}
	}
	self.movement_x = dir * v_forward * sv_maxspeed;
	self.movement_y = dir * v_right * sv_maxspeed;
	self.movement_z = dir * v_up * sv_maxspeed;
	// Emulate keyboard interface
	if (skill < 10)
		havocbot_keyboard_movement(destorg);

	// Bunnyhop!
	if (self.goalcurrent)
	if (skill+self.bot_moveskill >= bot_ai_bunnyhop_skilloffset)
		havocbot_bunnyhop(dir);

	if ((dir * v_up) >= sv_jumpvelocity*0.5 && (self.flags & FL_ONGROUND)) self.BUTTON_JUMP=1;
	if (((dodge * v_up) > 0) && random()*frametime >= 0.2*bound(0,(10-skill-self.bot_dodgeskill)*0.1,1)) self.BUTTON_JUMP=TRUE;
	if (((dodge * v_up) < 0) && random()*frametime >= 0.5*bound(0,(10-skill-self.bot_dodgeskill)*0.1,1)) self.havocbot_ducktime=time+0.3/bound(0.1,skill+self.bot_dodgeskill,10);
}

void(void) havocbot_chooseenemy {
	entity head, best, head2;
	float rating, bestrating, i = 0, f = 0;
	vector eye, v;
	if (bot_nofire || PLAYER_IS_INDEPENDENT(self)) {
		self.enemy = world;
		return;
	}
	if (self.enemy) {
		if (!bot_aim_shouldattack(self.enemy)) {
			// enemy died or something, find a new target
			self.enemy = world;
			self.havocbot_chooseenemy_finished = time;
		} else if (self.havocbot_stickenemy) {
			// tracking last chosen enemy
			// if enemy is visible
			// and not really really far away
			// and we're not severely injured
			// then keep tracking for a half second into the future
			trace_line(self.origin+self.view_ofs, self.enemy.origin+self.enemy.view_ofs*0.5,FALSE,world);
			if (trace_ent == self.enemy || trace_fraction == 1)
			if (vlen(self.enemy.origin - self.origin) < 1000)
			if (self.health > 30) {
				// remain tracking him for a shot while (case he went after a small corner or pilar
				self.havocbot_chooseenemy_finished = time + bot_ai_enemydetectioninterval;
				return;
			}
			// enemy isn't visible, or is far away, or we're injured severely
			// so stop preferring this enemy
			// (it will still take a half second until a new one is chosen)
			self.havocbot_stickenemy = 0;
		}
	}
	if (time < self.havocbot_chooseenemy_finished)
		return;

	self.havocbot_chooseenemy_finished = time + bot_ai_enemydetectioninterval;
	eye = self.origin + self.view_ofs;
	best = world;
	bestrating = 100000000;
	head = head2 = findchainfloat(bot_attack, TRUE);
	// Search for enemies, if no enemy can be seen directly try to look through transparent objects
	for (;;) {
		while (head) {
			v = (head.absmin + head.absmax) * 0.5;
			rating = vlen(v - eye);
			if (rating<bot_ai_enemydetectionradius)
			if (bestrating > rating)
			if (bot_aim_shouldattack(head)) {
				trace_line(eye, v, TRUE, self);
				if (trace_ent == head || trace_fraction >= 1)
				{
					best = head;
					bestrating = rating;
				}
			}
			head = head.chain;
		}
		// I want to do a second scan if no enemy was found or I don't have weapons
		// TODO: Perform the scan when using the rifle (requires changes on the rifle code)
		if (best || self.weapons) // || self.weapon == WEAPON_CAMPINGRIFLE
			break;

		if (i)
			break;

		// Set flags to see through transparent objects
		f = self.dphitcontentsmask;
		self.dphitcontentsmask = DPCONTENTS_OPAQUE;
		head = head2;
		++i;
	}
	// Restore hit flags if needed
	if (i)
		self.dphitcontentsmask = f;

	self.enemy = best;
	self.havocbot_stickenemy = TRUE;
}

void(void) havocbot_chooseweapon {
	float i;
	// TODO: clean this up by moving it to weapon code
	// If no weapon was chosen get the first available weapon
	if (self.weapon==0)
	WEAPON_INFO_FOR_EACH_ID(i) {
		if (weapon_carried(self, i, TRUE, FALSE)) {
			self.switchweapon = i;
			return;
		}
	}
	// Do not change weapon during the next second after a combo
	i = time - self.lastcombotime;
	if (i < 1)
		return;

	// Workaround for rifle reloading (..)
	if (self.weapon == WEAPON_CAMPINGRIFLE)
	if (i < g_balance_campingrifle_reloadtime + 1)
		return;

	float w;
	float rocket  ; rocket   =-1000;
	float nex     ; nex      =-1000;
	float hagar   ; hagar    =-1000;
	float grenade ; grenade  =-1000;
	float electro ; electro  =-1000;
	float crylink ; crylink  =-1000;
	float uzi     ; uzi      =-1000;
	float shotgun ; shotgun  =-1000;
	float campingrifle ; campingrifle  =-1000;
	float laser   ; laser    =-1000;
	float minstanex ; minstanex =-1000;
	float bestscore; bestscore = 0;
	float bestweapon; bestweapon=self.switchweapon;
	float distance; distance=bound(10,vlen(self.origin-self.enemy.origin)-200,10000);
	float maxdelaytime=0.5;
	float spreadpenalty=10;
	// Should it do a weapon combo?
	float af, ct, combo_time, combo;
	af = WEAPON_ATTACK_FINISHED(self);
	ct = bot_ai_weapon_combo_threshold;
	// Bots with no skill will be 4 times more slower than "godlike" bots when doing weapon combos
	// Ideally this 4 should be calculated as longest_weapon_refire / bot_ai_weapon_combo_threshold
	combo_time = time + ct + (ct * ((-0.3*(skill+self.bot_weaponskill))+3));
	combo = FALSE;
	if (bot_ai_weapon_combo)
	if (self.weapon == self.lastfiredweapon)
	if (af > combo_time) {
		combo = TRUE;
		self.lastcombotime = time;
	}
	distance *= pow(2, self.bot_rangepreference);
	// Custom weapon list based on distance to the enemy
	if (bot_custom_weapon) {
		// Choose weapons for far distance
		if (distance > bot_distance_far) {
			for (i=0; i < WEAPON_COUNT && bot_weapons_far[i] != -1 ; ++i) {
				w = bot_weapons_far[i];
				if (weapon_carried(self, w, TRUE, FALSE)) {
					if (self.weapon == w && combo)
						continue;

					self.switchweapon = w;
					return;
				}
			}
		}
		// Choose weapons for mid distance
		if (distance > bot_distance_close) {
			for (i=0; i < WEAPON_COUNT && bot_weapons_mid[i] != -1 ; ++i) {
				w = bot_weapons_mid[i];
				if (weapon_carried(self, w, TRUE, FALSE)) {
					if (self.weapon == w && combo)
						continue;

					self.switchweapon = w;
					return;
				}
			}
		}
		// Choose weapons for close distance
		for (i=0; i < WEAPON_COUNT && bot_weapons_close[i] != -1 ; ++i) {
			w = bot_weapons_close[i];
			if (weapon_carried(self, w, TRUE, FALSE)) {
				if (self.weapon == w && combo)
					continue;

				self.switchweapon = w;
				return;
			}
		}
	}
}

void(void) havocbot_aim {
	vector selfvel, enemyvel;
	if (time < self.nextaim)
		return;

	self.nextaim = time + 0.1;
	selfvel = self.velocity;
	if (!self.waterlevel)
		selfvel_z = 0;

	if (self.enemy) {
		enemyvel = self.enemy.velocity;
		if (!self.enemy.waterlevel)
			enemyvel_z = 0;

		bot_aim_lag_additem(time + self.ping, 0, 0, self.enemy, self.origin, selfvel, self.enemy.origin, enemyvel);
	} else
		bot_aim_lag_additem(time + self.ping, 0, 0, world, self.origin, selfvel, self.goalcurrent.origin, '0 0 0');
}

float(void) havocbot_moveto_refresh_route {
	// Refresh path to goal if necessary
	entity wp;
	wp = self.havocbot_personal_waypoint;
	navigation_goalrating_start();
	navigation_routerating(wp, 10000, 10000);
	navigation_goalrating_end();
	return self.navigation_hasgoals;
}

float(vector pos) havocbot_moveto {
	entity wp;
	if (self.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING) {
		// Step 4: Move to waypoint
		if (self.havocbot_personal_waypoint==world) {
			self.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
			return BOT_CMD_STATUS_ERROR;
		}
		if (!bot_strategytoken_taken)
		if (self.havocbot_personal_waypoint_searchtime<time) {
			bot_strategytoken_taken = TRUE;
			if (havocbot_moveto_refresh_route()) {
				self.havocbot_personal_waypoint_searchtime = time + 10;
				self.havocbot_personal_waypoint_failcounter = 0;
			} else {
				self.havocbot_personal_waypoint_failcounter += 1;
				self.havocbot_personal_waypoint_searchtime = time + 2;
				if (self.havocbot_personal_waypoint_failcounter >= 30) {
					self.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_LINKING;
					remove(self.havocbot_personal_waypoint);
					return BOT_CMD_STATUS_ERROR;
				}
			}
		}
		// Heading
		vector dir = self.goalcurrent.origin - (self.origin + self.view_ofs);
		dir_z = 0;
		bot_aim_dir(dir, -1);
		// Go!
		havocbot_movetogoal();
		if (self.aistatus & AI_STATUS_WAYPOINT_PERSONAL_REACHED) {
			// Step 5: Waypoint reached
			remove(self.havocbot_personal_waypoint);
			self.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_REACHED;
			return BOT_CMD_STATUS_FINISHED;
		}
		return BOT_CMD_STATUS_EXECUTING;
	}
	// Step 2: Linking waypoint
	if (self.aistatus & AI_STATUS_WAYPOINT_PERSONAL_LINKING) {
		// Wait until it is linked
		if (!self.havocbot_personal_waypoint.wplinked)
			return BOT_CMD_STATUS_EXECUTING;

		self.havocbot_personal_waypoint_searchtime = time; // so we set the route next frame
		self.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_LINKING;
		self.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_GOING;
		// Step 3: Route to waypoint
		return BOT_CMD_STATUS_EXECUTING;
	}
	// Step 1: Spawning waypoint
	wp = waypoint_spawnpersonal(pos);
	if (wp==world) {
		return BOT_CMD_STATUS_ERROR;
	}
	self.havocbot_personal_waypoint = wp;
	self.havocbot_personal_waypoint_failcounter = 0;
	self.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_LINKING;
	return BOT_CMD_STATUS_EXECUTING;
}

float(void) havocbot_resetgoal {
	navigation_clearroute();
	return BOT_CMD_STATUS_FINISHED;
}

void(void) havocbot_setupbot {
	self.bot_ai = havocbot_ai;
	self.cmd_moveto = havocbot_moveto;
	self.cmd_resetgoal = havocbot_resetgoal;
	havocbot_role_choose();
}

vector(void) havocbot_dodge {
	entity head;
	vector dodge, v, n;
	float danger, bestdanger, vl, d;
	dodge = '0 0 0';
	bestdanger = -20;
	// check for dangerous objects near bot or approaching bot
	head = findchainfloat(bot_dodge, TRUE);
	while(head) {
		if (head.owner != self) {
			vl = vlen(head.velocity);
			if (vl > sv_maxspeed * 0.3) {
				n = normalize(head.velocity);
				v = self.origin - head.origin;
				d = v * n;
				if (d > (0 - head.bot_dodgerating))
				if (d < (vl * 0.2 + head.bot_dodgerating)) {
					// calculate direction and distance from the flight path, by removing the forward axis
					v = v - (n * (v * n));
					danger = head.bot_dodgerating - vlen(v);
					if (bestdanger < danger)
					{
						bestdanger = danger;
						// dodge to the side of the object
						dodge = normalize(v);
					}
				}
			} else {
				danger = head.bot_dodgerating - vlen(head.origin - self.origin);
				if (bestdanger < danger)
				{
					bestdanger = danger;
					dodge = normalize(self.origin - head.origin);
				}
			}
		}
		head = head.chain;
	}
	return dodge;
}

void(void) havocbot_init {
	CVAR_CACHE(bot_ai_bunnyhop_firstjumpdelay);
	CVAR_CACHE(bot_ai_bunnyhop_skilloffset);
	CVAR_CACHE(bot_ai_bunnyhop_startdistance);
	CVAR_CACHE(bot_ai_bunnyhop_stopdistance);
	CVAR_CACHE(bot_ai_chooseweaponinterval);
	CVAR_CACHE(bot_ai_dodgeupdateinterval);
	CVAR_CACHE(bot_ai_enemydetectioninterval);
	CVAR_CACHE(bot_ai_enemydetectionradius);
	CVAR_CACHE(bot_ai_ignoregoal_timeout);
	CVAR_CACHE(bot_ai_keyboard_distance);
	CVAR_CACHE(bot_ai_keyboard_treshold);
	CVAR_CACHE(bot_ai_weapon_combo);
	CVAR_CACHE(bot_ai_weapon_combo_threshold);
	CVAR_CACHE(bot_nofire);
	CVAR_CACHE(bot_ai_strategyinterval);
	havocbot_role_init();
}
