float bot_ai_navigation_jetpack;
float bot_ai_navigation_jetpack_mindistance;
float navigation_bestdirect;

// completely empty the goal stack, used when deciding where to go
void(void) navigation_clearroute {
	//print("bot ", etos(self), " clear\n");
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
	entity w, best;
	float dist, bestdist;
	vector v, org, pm1, pm2;
	if (ent.classname == "waypoint") return NULL;
	if ((ent.flags & FL_ONGROUND) || ent.waterlevel > WATER_LEVEL_NONE) {
		pm1 = ent.origin + ent.mins;
		pm2 = ent.origin + ent.maxs;
	} else {
		if not(ent.iscreature) return NULL;
		trace_box(ent.origin, ent.mins, ent.maxs, ent.origin + '0 0 -1000', TRACE_MOVE_NOMONSTERS, ent);
		pm1 = trace_endpos + ent.mins;
		pm2 = trace_endpos + ent.maxs;
	}
	org = (pm1 + pm2) / 2;
	vector _mins = ent.mins;
	vector _maxs = ent.maxs;
	org_z = min(org_z, pm1_z + 1);
	best = world;
	bestdist = 1050;
	// box check failed, try walk
	for (w = waypoint_list; w; w = w.aiment) {
		// if object can walk from spawnfunc_waypoint
		if (w.size != '0 0 0') {
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
			if (math_boxes_overlap(pm1, pm2, w.absmin, w.absmax))
				return w;

			trace_line(v, org, TRUE, ent);
			if (trace_fraction == 1) {
				if (walkfromwp) {
					//print("^1can I reach ", vtos(org), " from ", vtos(v), "?\n");
					if (trace_walk(ent, v + '0 0 -1' * _mins_z, _mins, _maxs, org, bot_navigation_movemode)) {
						bestdist = dist;
						best = w;
					}
				} else {
					if (trace_walk(ent, ent.origin, _mins, _maxs, v, bot_navigation_movemode)) {
						bestdist = dist;
						best = w;
					}
				}
			}
		}
	}
	return best;
}

entity navigation_markroutes_edge_current;
entity navigation_markroutes_edge_list;

//float(void) navigation_markroutes_edge_validate {
//	float n = 0;
//	entity w;
//	for (w = navigation_markroutes_edge_list; w; w = w.weaponentity) {
//		n++;
//		if (n > waypoint_count) {
//			return FALSE;
//		}
//	}
//	return TRUE;
//}

void(entity w) navigation_markroutes_edge_add {
	if (w.weaponentity || w.exteriorweaponentity || w == navigation_markroutes_edge_list) return; //already added
	w.weaponentity = navigation_markroutes_edge_list;
	//w.exteriorweaponentity = NULL; //must be already NULL
	if (navigation_markroutes_edge_list) {
		navigation_markroutes_edge_list.exteriorweaponentity = w;
	}
	navigation_markroutes_edge_list = w;
}

void(entity w) navigation_markroutes_edge_remove {
	if (w == navigation_markroutes_edge_list) {
		navigation_markroutes_edge_list = w.weaponentity;
		if (navigation_markroutes_edge_list)
			navigation_markroutes_edge_list.exteriorweaponentity = NULL;

		w.exteriorweaponentity = NULL;
		w.weaponentity = NULL;
		return;
	}
	entity next = w.weaponentity;
	entity prev = w.exteriorweaponentity;
	if (next) next.exteriorweaponentity = w.exteriorweaponentity;
	if (prev) prev.weaponentity = w.weaponentity;
	w.exteriorweaponentity = NULL;
	w.weaponentity = NULL;
}

float navigation_markroutes_astar;
vector navigation_markroutes_astar_origin;
void(void) navigation_markroutes_clear {
	entity w;
	if (navigation_markroutes_astar) {
		for (w = waypoint_list; w; w = w.aiment) {
			w.height = 10000000;
			w.enemy = NULL;
			w.weaponentity = NULL;
			w.exteriorweaponentity = NULL;
			w.dmg_edge = w.dmg;
			w.dmg += vlen(navigation_markroutes_astar_origin - w.origin) * 10;
		}
	} else {
		for (w = waypoint_list; w; w = w.aiment) {
			w.height = 10000000;
			w.enemy = NULL;
			w.weaponentity = NULL;
			w.exteriorweaponentity = NULL;
		}
	}
	navigation_markroutes_edge_list = NULL;
	navigation_markroutes_edge_current = NULL;
}

float navigation_markroutes_started;
entity navigation_markroutes_start_from;
void(entity fixed_source_waypoint) navigation_markroutes_start {
	navigation_markroutes_started = TRUE;
	navigation_markroutes_start_from = fixed_source_waypoint;
}

void(entity fixed_source_waypoint) navigation_markroutes_start_delayed {
	navigation_markroutes_clear();
	if (fixed_source_waypoint) {
		fixed_source_waypoint.height = 0;
		fixed_source_waypoint.enemy = NULL;
		navigation_markroutes_edge_current = fixed_source_waypoint;
		navigation_markroutes_edge_add(fixed_source_waypoint);
	} else {
		entity w;
		vector v, m1, m2, diff;
		float maxdist = 750;
		for (w = waypoint_list; w; w = w.aiment) {
			if (w.size != '0 0 0') {
				m1 = w.origin + w.mins;
				m2 = w.origin + w.maxs;
				v = self.origin + self.mins_z * '0 0 1';
				v_x = bound(m1_x, v_x, m2_x);
				v_y = bound(m1_y, v_y, m2_y);
				v_z = bound(m1_z, v_z, m2_z);
			} else
				v = w.origin;

			diff = v - self.origin;
			diff_z = max(0, diff_z);
			if (vlen(diff) < maxdist) {
				if (trace_walk(self, self.origin, self.mins, self.maxs, v, bot_navigation_movemode)) {
					w.height = vlen(v - self.origin) + w.dmg;
				}
				navigation_markroutes_edge_add(w);
				if (!navigation_markroutes_edge_current || navigation_markroutes_edge_current.height > w.height)
					navigation_markroutes_edge_current = w;
			}
		}
	}
}

void(entity t) navigation_markroutes_astar_start {
	entity w;
	navigation_markroutes_astar_origin = ENTITY_CENTER(t);
	navigation_markroutes_astar = TRUE;
}

void(void) navigation_markroutes_astar_end {
	entity w;
	for (w = waypoint_list; w; w = w.aiment) {
		w.dmg = w.dmg_edge;
	}
	navigation_markroutes_astar = FALSE;
}

// find path to specified waypoint with Dijkstra's algorithm
void(entity target_waypoint) navigation_markroutes {
	entity w, wp;
	float cost, cost2;
	if (navigation_markroutes_started) {
		navigation_markroutes_start_delayed(navigation_markroutes_start_from);
		navigation_markroutes_started = FALSE;
	}
	if (target_waypoint && target_waypoint.height < 10000000 &&
			!target_waypoint.weaponentity && !target_waypoint.exteriorweaponentity)
		return; // route is already exists
	while (navigation_markroutes_edge_current && target_waypoint != navigation_markroutes_edge_current) {
		w = navigation_markroutes_edge_current;
		navigation_markroutes_edge_remove(w);
		cost = w.height;
		if ((wp = w.wp00)) { cost2 = cost + wp.dmg + w.wp00mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp01)) { cost2 = cost + wp.dmg + w.wp01mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp02)) { cost2 = cost + wp.dmg + w.wp02mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp03)) { cost2 = cost + wp.dmg + w.wp03mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp04)) { cost2 = cost + wp.dmg + w.wp04mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp05)) { cost2 = cost + wp.dmg + w.wp05mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp06)) { cost2 = cost + wp.dmg + w.wp06mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp07)) { cost2 = cost + wp.dmg + w.wp07mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp08)) { cost2 = cost + wp.dmg + w.wp08mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp09)) { cost2 = cost + wp.dmg + w.wp09mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp10)) { cost2 = cost + wp.dmg + w.wp10mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp11)) { cost2 = cost + wp.dmg + w.wp11mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp12)) { cost2 = cost + wp.dmg + w.wp12mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp13)) { cost2 = cost + wp.dmg + w.wp13mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp14)) { cost2 = cost + wp.dmg + w.wp14mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp15)) { cost2 = cost + wp.dmg + w.wp15mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp16)) { cost2 = cost + wp.dmg + w.wp16mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp17)) { cost2 = cost + wp.dmg + w.wp17mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp18)) { cost2 = cost + wp.dmg + w.wp18mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp19)) { cost2 = cost + wp.dmg + w.wp19mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp20)) { cost2 = cost + wp.dmg + w.wp20mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp21)) { cost2 = cost + wp.dmg + w.wp21mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp22)) { cost2 = cost + wp.dmg + w.wp22mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp23)) { cost2 = cost + wp.dmg + w.wp23mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp24)) { cost2 = cost + wp.dmg + w.wp24mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp25)) { cost2 = cost + wp.dmg + w.wp25mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp26)) { cost2 = cost + wp.dmg + w.wp26mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp27)) { cost2 = cost + wp.dmg + w.wp27mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp28)) { cost2 = cost + wp.dmg + w.wp28mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp29)) { cost2 = cost + wp.dmg + w.wp29mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp30)) { cost2 = cost + wp.dmg + w.wp30mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		if ((wp = w.wp31)) { cost2 = cost + wp.dmg + w.wp31mincost; if (wp.height > cost2) { wp.height = cost2; wp.enemy = w; navigation_markroutes_edge_add(wp); }
		}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
		if ((navigation_markroutes_edge_current = navigation_markroutes_edge_list))
			for (w = navigation_markroutes_edge_list.weaponentity; w; w = w.weaponentity) {
				if (navigation_markroutes_edge_current.height > w.height)
					navigation_markroutes_edge_current = w;
			}
	}
}

// queries the entire spawnfunc_waypoint network for pathes leading to the bot
void(entity fixed_source_waypoint) navigation_markroutes_inverted {
	entity w, wp;
	float searching;
	navigation_markroutes_clear();
	if (fixed_source_waypoint) {
		fixed_source_waypoint.height = 0; // the cost to get from X to fixed_source_waypoint
		fixed_source_waypoint.enemy = world;
		navigation_markroutes_edge_current = fixed_source_waypoint;
		navigation_markroutes_edge_add(fixed_source_waypoint);
	} else {
		error("need to start with a waypoint\n");
	}
	while (navigation_markroutes_edge_list) {
		while ((w = navigation_markroutes_edge_list)) {
			navigation_markroutes_edge_remove(w);
			for (wp = waypoint_list; wp; wp = wp.aiment) {
				if (wp.height == 0) continue;
				if (w != wp.wp00) if (w != wp.wp01) if (w != wp.wp02) if (w != wp.wp03)
				if (w != wp.wp04) if (w != wp.wp05) if (w != wp.wp06) if (w != wp.wp07)
				if (w != wp.wp08) if (w != wp.wp09) if (w != wp.wp10) if (w != wp.wp11)
				if (w != wp.wp12) if (w != wp.wp13) if (w != wp.wp14) if (w != wp.wp15)
				if (w != wp.wp16) if (w != wp.wp17) if (w != wp.wp18) if (w != wp.wp19)
				if (w != wp.wp20) if (w != wp.wp21) if (w != wp.wp22) if (w != wp.wp23)
				if (w != wp.wp24) if (w != wp.wp25) if (w != wp.wp26) if (w != wp.wp27)
				if (w != wp.wp28) if (w != wp.wp29) if (w != wp.wp30) if (w != wp.wp31)
					continue;

				wp.height = 0;
				wp.enemy = w;
				navigation_markroutes_edge_add(wp);
			}
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
					navigation_bestdirect = TRUE;
					self.navigation_jetpack_goal = e;
					self.navigation_jetpack_point = pointb;
				}
				return;
			}
		}
	}
	// if it can reach the goal there is nothing more to do
	vector o = ENTITY_CENTER(self);
	if (checkpvs(o, e)) {
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
		f = vlen(v - o);
		if (f < 2000 + self.maxs_x)
		if (trace_walk(self, self.origin, self.mins, self.maxs, v, bot_navigation_movemode)) {
			f = f * rangebias / (rangebias + f);
			if (navigation_bestrating < f) {
				navigation_bestrating = f;
				navigation_bestgoal = e;
				navigation_bestdirect = TRUE;
			}
			return;
		}
	}
	// update the cached spawnfunc_waypoint link on a dynamic item entity
	if (e.classname == "waypoint" && !(e.wpflags & WAYPOINTFLAG_PERSONAL)) {
		nwp = e;
		navigation_markroutes(nwp);
	} else {
		if (time > e.nearestwaypointtimeout) {
			e.nearestwaypoint = navigation_findnearestwaypoint(e, TRUE);
			// TODO: Cleaner solution, probably handling this timeout from ctf.qc
			e.nearestwaypointtimeout = time + random() * 2 + 2;
		}
		nwp = e.nearestwaypoint;
		if (nwp) navigation_markroutes(nwp);
	}
	if (nwp && nwp.height < 10000000)
		f = f * rangebias / (rangebias + nwp.height);
	else
		f = 0;

	if (navigation_bestrating < f) {
		navigation_bestrating = f;
		navigation_bestgoal = e;
		navigation_bestdirect = FALSE;
	}
}

// adds an item to the the goal stack with the path to a given item
float(entity e) navigation_routetogoal {
	self.goalentity = e;
	// if there is no goal, just exit
	if (!e)
		return FALSE;

	navigation_hasgoals = TRUE;
	// put the entity on the goal stack
	//print("routetogoal ", etos(e), "\n");
	navigation_pushroute(e);
	if (navigation_bestdirect)
		return TRUE;

	// see if there are waypoints describing a path to the item
	if (e.classname != "waypoint" || (e.wpflags & WAYPOINTFLAG_PERSONAL)) {
		e = e.nearestwaypoint;
	} else
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

void(entity e) navigation_teleported {
	if (e.goalcurrent)
	if (e.goalcurrent.classname == "waypoint")
	if (e.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT) {
		entity oldself = self;
		self = e;
		navigation_poproute();
		self = oldself;
	}
}

// removes any currently touching waypoints from the goal stack
// (this is how bots detect if they reached a goal)
void(void) navigation_poptouchedgoals {
	vector org, m1, m2;
	org = self.origin;
	m1 = org + self.mins;
	m2 = org + self.maxs;
	// Loose goal touching check when running
	if (self.aistatus & AI_STATUS_RUNNING)
	if (self.goalcurrent.classname=="waypoint") {
		if (vlen(self.origin - self.goalcurrent.origin)<150) {
			trace_line(self.origin + self.view_ofs , self.goalcurrent.origin, TRUE, world);
			if (trace_fraction==1) {
				// Detect personal waypoints
				if (self.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
				if ((self.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) && self.goalcurrent.owner==self) {
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
		if ((self.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) && self.goalcurrent.owner==self) {
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
	navigation_hasgoals = FALSE;
	navigation_bestgoal = NULL;
	navigation_markroutes_start(NULL);
}

// ends a goal selection session (updates goal stack to the best goal)
void(void) navigation_goalrating_end {
	navigation_routetogoal(navigation_bestgoal);
	// Hack: if it can't walk to any goal just move blindly to the first visible waypoint
	if not(navigation_hasgoals) {
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
			navigation_routetogoal(random_selection_chosen_ent);

		navigation_hasgoals = FALSE;
	}
}

void(entity t) navigation_single {
	navigation_goalrating_start();
	navigation_markroutes_astar_start(t);
	navigation_markroutes_start(NULL);
	navigation_routerating(t, 1, 1);
	navigation_goalrating_end();
	navigation_markroutes_astar_end();
}

void(void) navigation_init {
	CVAR_CACHE(bot_ai_navigation_jetpack);
	CVAR_CACHE(bot_ai_navigation_jetpack_mindistance);
}
