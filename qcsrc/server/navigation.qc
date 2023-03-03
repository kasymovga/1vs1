float bot_ai_navigation_jetpack;
float bot_ai_navigation_jetpack_mindistance;

// completely empty the goal stack, used when deciding where to go
void(void) navigation_clearroute {
	//print("bot ", etos(self), " clear\n");
	self.navigation_hasgoals = FALSE;
	self.goalcurrent = world;
	self.goalstack01 = world;
	self.goalstack02 = world;
	self.goalstack03 = world;
	self.goalstack04 = world;
	self.goalstack05 = world;
	self.goalstack06 = world;
	self.goalstack07 = world;
	self.goalstack08 = world;
	self.goalstack09 = world;
	self.goalstack10 = world;
	self.goalstack11 = world;
	self.goalstack12 = world;
	self.goalstack13 = world;
	self.goalstack14 = world;
	self.goalstack15 = world;
	self.goalstack16 = world;
	self.goalstack17 = world;
	self.goalstack18 = world;
	self.goalstack19 = world;
	self.goalstack20 = world;
	self.goalstack21 = world;
	self.goalstack22 = world;
	self.goalstack23 = world;
	self.goalstack24 = world;
	self.goalstack25 = world;
	self.goalstack26 = world;
	self.goalstack27 = world;
	self.goalstack28 = world;
	self.goalstack29 = world;
	self.goalstack30 = world;
	self.goalstack31 = world;
}

// add a new goal at the beginning of the stack
// (in other words: add a new prerequisite before going to the later goals)
// NOTE: when a waypoint is added, the WP gets pushed first, then the
// next-closest WP on the shortest path to the WP
// That means, if the stack overflows, the bot will know how to do the FIRST 32
// steps to the goal, and then recalculate the path.
void(entity e) navigation_pushroute {
	//print("bot ", etos(self), " push ", etos(e), "\n");
	self.goalstack31 = self.goalstack30;
	self.goalstack30 = self.goalstack29;
	self.goalstack29 = self.goalstack28;
	self.goalstack28 = self.goalstack27;
	self.goalstack27 = self.goalstack26;
	self.goalstack26 = self.goalstack25;
	self.goalstack25 = self.goalstack24;
	self.goalstack24 = self.goalstack23;
	self.goalstack23 = self.goalstack22;
	self.goalstack22 = self.goalstack21;
	self.goalstack21 = self.goalstack20;
	self.goalstack20 = self.goalstack19;
	self.goalstack19 = self.goalstack18;
	self.goalstack18 = self.goalstack17;
	self.goalstack17 = self.goalstack16;
	self.goalstack16 = self.goalstack15;
	self.goalstack15 = self.goalstack14;
	self.goalstack14 = self.goalstack13;
	self.goalstack13 = self.goalstack12;
	self.goalstack12 = self.goalstack11;
	self.goalstack11 = self.goalstack10;
	self.goalstack10 = self.goalstack09;
	self.goalstack09 = self.goalstack08;
	self.goalstack08 = self.goalstack07;
	self.goalstack07 = self.goalstack06;
	self.goalstack06 = self.goalstack05;
	self.goalstack05 = self.goalstack04;
	self.goalstack04 = self.goalstack03;
	self.goalstack03 = self.goalstack02;
	self.goalstack02 = self.goalstack01;
	self.goalstack01 = self.goalcurrent;
	self.goalcurrent = e;
}

// remove first goal from stack
// (in other words: remove a prerequisite for reaching the later goals)
// (used when a spawnfunc_waypoint is reached)
void(void) navigation_poproute {
	//print("bot ", etos(self), " pop\n");
	self.goalcurrent = self.goalstack01;
	self.goalstack01 = self.goalstack02;
	self.goalstack02 = self.goalstack03;
	self.goalstack03 = self.goalstack04;
	self.goalstack04 = self.goalstack05;
	self.goalstack05 = self.goalstack06;
	self.goalstack06 = self.goalstack07;
	self.goalstack07 = self.goalstack08;
	self.goalstack08 = self.goalstack09;
	self.goalstack09 = self.goalstack10;
	self.goalstack10 = self.goalstack11;
	self.goalstack11 = self.goalstack12;
	self.goalstack12 = self.goalstack13;
	self.goalstack13 = self.goalstack14;
	self.goalstack14 = self.goalstack15;
	self.goalstack15 = self.goalstack16;
	self.goalstack16 = self.goalstack17;
	self.goalstack17 = self.goalstack18;
	self.goalstack18 = self.goalstack19;
	self.goalstack19 = self.goalstack20;
	self.goalstack20 = self.goalstack21;
	self.goalstack21 = self.goalstack22;
	self.goalstack22 = self.goalstack23;
	self.goalstack23 = self.goalstack24;
	self.goalstack24 = self.goalstack25;
	self.goalstack25 = self.goalstack26;
	self.goalstack26 = self.goalstack27;
	self.goalstack27 = self.goalstack28;
	self.goalstack28 = self.goalstack29;
	self.goalstack29 = self.goalstack30;
	self.goalstack30 = self.goalstack31;
	self.goalstack31 = world;
}

// find the spawnfunc_waypoint near a dynamic goal such as a dropped weapon
entity(entity ent, float walkfromwp) navigation_findnearestwaypoint {
	entity waylist, w, best;
	float dist, bestdist;
	vector v, org, pm1, pm2;
	if (ent.flags & FL_ONGROUND || ent.waterlevel > WATERLEVEL_NONE) {
		pm1 = ent.origin + ent.mins;
		pm2 = ent.origin + ent.maxs;
	} else {
		trace_box(ent.origin, ent.mins, ent.maxs, ent.origin + '0 0 -1000', TRACE_MOVE_NOMONSTERS, ent);
		pm1 = trace_endpos + ent.mins;
		pm2 = trace_endpos + ent.maxs;
	}
	waylist = findchain(classname, "waypoint");
	// do two scans, because box test is cheaper
	w = waylist;
	while (w) {
		// if object is touching spawnfunc_waypoint
		if (w != ent)
			if (math_boxes_overlap(pm1, pm2, w.absmin, w.absmax))
				return w;
		w = w.chain;
	}
	org = (pm1 + pm2) / 2;
	vector _mins = self.mins;
	vector _maxs = self.maxs;
	org_z = org_z + ent.mins_z - _mins_z; // player height
	best = world;
	bestdist = 1050;
	// box check failed, try walk
	w = waylist;
	while (w) {
		// if object can walk from spawnfunc_waypoint
		if (w != ent) {
			if (w.wpisbox) {
				vector wm1, wm2;
				wm1 = w.origin + w.mins;
				wm2 = w.origin + w.maxs;
				v_x = bound(wm1_x, org_x, wm2_x);
				v_y = bound(wm1_y, org_y, wm2_y);
				v_z = bound(wm1_z, org_z, wm2_z);
			} else
				v = w.origin;

			dist = vlen(v - org);
			if (bestdist > dist) {
				trace_line(v, org, TRUE, ent);
				if (trace_fraction == 1) {
					if (walkfromwp) {
						//print("^1can I reach ", vtos(org), " from ", vtos(v), "?\n");
						if (trace_walk(ent, v, _mins, _maxs, org, bot_navigation_movemode)) {
							bestdist = dist;
							best = w;
						}
					} else {
						if (trace_walk(ent, org, _mins, _maxs, v, bot_navigation_movemode)) {
							bestdist = dist;
							best = w;
						}
					}
				}
			}
		}
		w = w.chain;
	}
	return best;
}

// finds the waypoints near the bot initiating a navigation query
float(entity waylist, float maxdist) navigation_markroutes_nearestwaypoints {
	entity head;
	vector v, m1, m2, diff;
	float c;
	c = 0;
	head = waylist;
	while (head) {
		if (!head.wpconsidered) {
			if (head.wpisbox) {
				m1 = head.origin + head.mins;
				m2 = head.origin + head.maxs;
				v = self.origin;
				v_x = bound(m1_x, v_x, m2_x);
				v_y = bound(m1_y, v_y, m2_y);
				v_z = bound(m1_z, v_z, m2_z);
			} else
				v = head.origin;

			diff = v - self.origin;
			diff_z = max(0, diff_z);
			if (vlen(diff) < maxdist) {
				head.wpconsidered = TRUE;
				if (trace_walk(self, self.origin, self.mins, self.maxs, v, bot_navigation_movemode)) {
					head.wpnearestpoint = v;
					head.wpcost = vlen(v - self.origin) + head.dmg;
					head.wpfire = 1;
					head.enemy = world;
					c = c + 1;
				}
			}
		}
		head = head.chain;
	}
	return c;
}

// updates a path link if a spawnfunc_waypoint link is better than the current one
void(entity w, entity wp, float cost2, vector p) navigation_markroutes_checkwaypoint {
	vector m1;
	vector m2;
	vector v;
	if (wp.wpisbox) {
		m1 = wp.absmin;
		m2 = wp.absmax;
		v_x = bound(m1_x, p_x, m2_x);
		v_y = bound(m1_y, p_y, m2_y);
		v_z = bound(m1_z, p_z, m2_z);
	} else
		v = wp.origin;

	cost2 = cost2 + vlen(v - p);
	if (wp.wpcost > cost2) {
		wp.wpcost = cost2;
		wp.enemy = w;
		wp.wpfire = 1;
		wp.wpnearestpoint = v;
	}
}

// queries the entire spawnfunc_waypoint network for pathes leading away from the bot
void(entity fixed_source_waypoint) navigation_markroutes {
	entity w, wp, waylist;
	float searching, cost, cost2;
	vector p;
	w = waylist = findchain(classname, "waypoint");
	while (w) {
		w.wpconsidered = FALSE;
		w.wpnearestpoint = '0 0 0';
		w.wpcost = 10000000;
		w.wpfire = 0;
		w.enemy = world;
		w = w.chain;
	}
	if (fixed_source_waypoint) {
		fixed_source_waypoint.wpconsidered = TRUE;
		fixed_source_waypoint.wpnearestpoint = fixed_source_waypoint.origin + 0.5 * (fixed_source_waypoint.mins + fixed_source_waypoint.maxs);
		fixed_source_waypoint.wpcost = fixed_source_waypoint.dmg;
		fixed_source_waypoint.wpfire = 1;
		fixed_source_waypoint.enemy = world;
	} else {
		// try a short range search for the nearest waypoints, and expand the search repeatedly if none are found
		// as this search is expensive we will use lower values if the bot is on the air
		float i, increment, maxdistance;
		if (self.flags & FL_ONGROUND) {
			increment = 750;
			maxdistance = 50000;
		} else {
			increment = 500;
			maxdistance = 1500;
		}
		for (i=increment;!navigation_markroutes_nearestwaypoints(waylist, i)&&i<maxdistance;i+=increment);
	}
	searching = TRUE;
	while (searching) {
		searching = FALSE;
		w = waylist;
		while (w) {
			if (w.wpfire) {
				searching = TRUE;
				w.wpfire = 0;
				cost = w.wpcost;
				p = w.wpnearestpoint;
				wp = w.wp00;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp00mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp01;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp01mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp02;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp02mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp03;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp03mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp04;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp04mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp05;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp05mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp06;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp06mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp07;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp07mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp08;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp08mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp09;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp09mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp10;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp10mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp11;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp11mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp12;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp12mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp13;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp13mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp14;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp14mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp15;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp15mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp16;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp16mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp17;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp17mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp18;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp18mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp19;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp19mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp20;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp20mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp21;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp21mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp22;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp22mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp23;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp23mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp24;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp24mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp25;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp25mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp26;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp26mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp27;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp27mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp28;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp28mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp29;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp29mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp30;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp30mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				wp = w.wp31;if (wp) { cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + w.wp31mincost) navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
			}
			w = w.chain;
		}
	}
}

// queries the entire spawnfunc_waypoint network for pathes leading to the bot
void(entity fixed_source_waypoint) navigation_markroutes_inverted {
	entity w, wp, waylist;
	float searching, cost, cost2;
	vector p;
	w = waylist = findchain(classname, "waypoint");
	while (w) {
		w.wpconsidered = FALSE;
		w.wpnearestpoint = '0 0 0';
		w.wpcost = 10000000;
		w.wpfire = 0;
		w.enemy = world;
		w = w.chain;
	}
	if (fixed_source_waypoint) {
		fixed_source_waypoint.wpconsidered = TRUE;
		fixed_source_waypoint.wpnearestpoint = fixed_source_waypoint.origin + 0.5 * (fixed_source_waypoint.mins + fixed_source_waypoint.maxs);
		fixed_source_waypoint.wpcost = fixed_source_waypoint.dmg; // the cost to get from X to fixed_source_waypoint
		fixed_source_waypoint.wpfire = 1;
		fixed_source_waypoint.enemy = world;
	} else {
		error("need to start with a waypoint\n");
	}
	searching = TRUE;
	while (searching) {
		searching = FALSE;
		w = waylist;
		while (w) {
			if (w.wpfire) {
				searching = TRUE;
				w.wpfire = 0;
				cost = w.wpcost; // cost to walk from w to home
				p = w.wpnearestpoint;
				for (wp = waylist; wp; wp = wp.chain) {
					if (w != wp.wp00) if (w != wp.wp01) if (w != wp.wp02) if (w != wp.wp03)
					if (w != wp.wp04) if (w != wp.wp05) if (w != wp.wp06) if (w != wp.wp07)
					if (w != wp.wp08) if (w != wp.wp09) if (w != wp.wp10) if (w != wp.wp11)
					if (w != wp.wp12) if (w != wp.wp13) if (w != wp.wp14) if (w != wp.wp15)
					if (w != wp.wp16) if (w != wp.wp17) if (w != wp.wp18) if (w != wp.wp19)
					if (w != wp.wp20) if (w != wp.wp21) if (w != wp.wp22) if (w != wp.wp23)
					if (w != wp.wp24) if (w != wp.wp25) if (w != wp.wp26) if (w != wp.wp27)
					if (w != wp.wp28) if (w != wp.wp29) if (w != wp.wp30) if (w != wp.wp31)
						continue;

					cost2 = cost + wp.dmg;
					navigation_markroutes_checkwaypoint(w, wp, cost2, p);
				}
			}
			w = w.chain;
		}
	}
}

// updates the best goal according to a weighted calculation of travel cost and item value of a new proposed item
void(entity e, float f, float rangebias) navigation_routerating {
	entity nwp;
	if (!e)
		return;

	//print("routerating ", etos(e), " = ", ftos(f), " - ", ftos(rangebias), "\n");
	// Evaluate path using jetpack
	if (self.items & IT_JETPACK)
	if (bot_ai_navigation_jetpack)
	if (vlen(self.origin - e.origin) > bot_ai_navigation_jetpack_mindistance) {
		vector pointa, pointb;
		// Point A
		trace_line(self.origin, self.origin + '0 0 65535', TRACE_MOVE_NORMAL, self);
		pointa = trace_endpos - '0 0 1';
		// Point B
		trace_line(e.origin, e.origin + '0 0 65535', TRACE_MOVE_NORMAL, e);
		pointb = trace_endpos - '0 0 1';
		// Can I see these two points from the sky?
		trace_line(pointa, pointb, TRACE_MOVE_NORMAL, self);
		if (trace_fraction==1) {
			// Lower the altitude of these points as much as possible
			float zdistance, xydistance, cost, t, fuel;
			vector down, npa, npb;
			down = '0 0 -1' * (self.maxs_z - self.mins_z) * 10;
			do {
				npa = pointa + down;
				npb = pointb + down;

				if (npa_z<=self.absmax_z)
					break;

				if (npb_z<=e.absmax_z)
					break;

				trace_line(npa, npb, TRACE_MOVE_NORMAL, self);
				if (trace_fraction==1)
				{
					pointa = npa;
					pointb = npb;
				}
			} while(trace_fraction == 1);
			// Rough estimation of fuel consumption
			// (ignores acceleration and current xyz velocity)
			xydistance = vlen(pointa - pointb);
			zdistance = fabs(pointa_z - self.origin_z);
			t = zdistance / g_jetpack_maxspeed_up;
			t += xydistance / g_jetpack_maxspeed_side;
			fuel = t * g_jetpack_fuel * 0.8;
			// enough fuel ?
			if (self.ammo_fuel>fuel || (self.items & IT_UNLIMITED_WEAPON_AMMO)) {
				// Estimate cost
				// (as onground costs calculation is mostly based on distances, here we do the same establishing some relationship
				//  - between air and ground speeds)
				cost = xydistance / (g_jetpack_maxspeed_side/sv_maxspeed);
				cost += zdistance / (g_jetpack_maxspeed_up/sv_maxspeed);
				cost *= 1.5;
				// Compare against other goals
				f = f * rangebias / (rangebias + cost);
				if (navigation_bestrating < f) {
					navigation_bestrating = f;
					navigation_bestgoal = e;
					self.navigation_jetpack_goal = e;
					self.navigation_jetpack_point = pointb;
				}
				return;
			}
		}
	}
	// update the cached spawnfunc_waypoint link on a dynamic item entity
	if (e.classname == "waypoint" && !(e.wpflags & WAYPOINTFLAG_PERSONAL)) {
		nwp = e;
	} else {
		if (time > e.nearestwaypointtimeout) {
			nwp = navigation_findnearestwaypoint(e, TRUE);
			if (nwp)
				e.nearestwaypoint = nwp;

			// TODO: Cleaner solution, probably handling this timeout from ctf.qc
			if (e.classname=="item_flag_team")
				e.nearestwaypointtimeout = time + 2;
			else
				e.nearestwaypointtimeout = time + random() * 3 + 5;
		}
		nwp = e.nearestwaypoint;
	}
	if (nwp && nwp.wpcost < 10000000)
		f = f * rangebias / (rangebias + (nwp.wpcost + vlen(e.origin - nwp.wpnearestpoint)));
	else
		f = 0;

	if (navigation_bestrating < f) {
		navigation_bestrating = f;
		navigation_bestgoal = e;
	}
}

// adds an item to the the goal stack with the path to a given item
float(entity e, vector startposition) navigation_routetogoal {
	self.goalentity = e;
	// if there is no goal, just exit
	if (!e)
		return FALSE;

	self.navigation_hasgoals = TRUE;
	// put the entity on the goal stack
	//print("routetogoal ", etos(e), "\n");
	navigation_pushroute(e);
	if (g_jetpack)
	if (e==self.navigation_jetpack_goal)
		return TRUE;

	// if it can reach the goal there is nothing more to do
	vector v1;
	vector v2;
	if (e.movetype == MOVETYPE_WALK || e.movetype == MOVETYPE_QCWALK) {
		trace_box(e.origin, e.mins, e.maxs, e.origin + '0 0 -1000', TRACE_MOVE_NORMAL, e);
		v1 = trace_endpos + e.mins;
		v2 = trace_endpos + e.maxs;
	} else {
		v1 = e.origin + e.mins;
		v2 = e.origin + e.maxs;
	}
	vector v;
	v_x = bound(v1_x, self.origin_x, v2_x);
	v_y = bound(v1_y, self.origin_y, v2_y);
	v_z = bound(v1_z, self.origin_z, v2_z);
	if (trace_walk(self, startposition, self.mins, self.maxs, v, bot_navigation_movemode)) {
		return TRUE;
	}
	// see if there are waypoints describing a path to the item
	if (e.classname != "waypoint" || (e.wpflags & WAYPOINTFLAG_PERSONAL))
		e = e.nearestwaypoint;
	else
		e = e.enemy; // we already have added it, so...

	if (e == world)
		return FALSE;

	for (;;) {
		// add the spawnfunc_waypoint to the path
		navigation_pushroute(e);
		e = e.enemy;

		if (e==world)
			break;
	}
	return FALSE;
}

// removes any currently touching waypoints from the goal stack
// (this is how bots detect if they reached a goal)
void(void) navigation_poptouchedgoals {
	vector org, m1, m2;
	org = self.origin;
	m1 = org + self.mins;
	m2 = org + self.maxs;
	if (self.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT) {
		if (self.lastteleporttime)
		if (time - self.lastteleporttime < 0.15) {
			navigation_poproute();
			self.lastteleporttime = 0;
			return;
		}
	}
	// Loose goal touching check when running
	if (self.aistatus & AI_STATUS_RUNNING)
	if (self.goalcurrent.classname=="waypoint") {
		if (vlen(self.origin - self.goalcurrent.origin)<150) {
			trace_line(self.origin + self.view_ofs , self.goalcurrent.origin, TRUE, world);
			if (trace_fraction==1) {
				// Detect personal waypoints
				if (self.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
				if (self.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && self.goalcurrent.owner==self) {
					self.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
					self.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
				}
				navigation_poproute();
			}
		}
	}
	while (self.goalcurrent && math_boxes_overlap(m1, m2, self.goalcurrent.absmin, self.goalcurrent.absmax)) {
		// Detect personal waypoints
		if (self.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
		if (self.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && self.goalcurrent.owner==self) {
			self.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
			self.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
		}
		navigation_poproute();
	}
}

// begin a goal selection session (queries spawnfunc_waypoint network)
void(void) navigation_goalrating_start {
	self.navigation_jetpack_goal = world;
	navigation_bestrating = -1;
	self.navigation_hasgoals = FALSE;
	navigation_bestgoal = world;
	navigation_markroutes(world);
}

// ends a goal selection session (updates goal stack to the best goal)
void(void) navigation_goalrating_end {
	navigation_routetogoal(navigation_bestgoal, self.origin);
	// Hack: if it can't walk to any goal just move blindly to the first visible waypoint
	if not (self.navigation_hasgoals) {
		entity head;
		random_selection_init();
		head = findradius(self.origin,1000);
		while(head) {
			if (head.classname=="waypoint")
			if (!(head.wpflags & WAYPOINTFLAG_GENERATED))
			if (vlen(self.origin-head.origin)>100)
			if (checkpvs(self.view_ofs,head))
				random_selection_add(head, 0, NULL, 1 + (vlen(self.origin-head.origin)<500), 0);

			head = head.chain;
		}
		if (random_selection_chosen_ent)
			navigation_routetogoal(random_selection_chosen_ent, self.origin);

		self.navigation_hasgoals = FALSE; // Reset this value
	}
}

void(void) navigation_init {
	CVAR_CACHE(bot_ai_navigation_jetpack);
	CVAR_CACHE(bot_ai_navigation_jetpack_mindistance);
}
