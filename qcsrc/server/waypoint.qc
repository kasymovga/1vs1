float waypoint_count;
float waypoint_generated_count;
float waypoint_schedulerelink_count;
float waypoint_schedulerelink_save;
float waypoint_presents_on_map;
float g_waypoints_use_botclip;

void(entity wp) waypoint_clearlinks;
void(void) waypoint_save_links;

void(entity w) waypoint_show {
	vector m1, m2;
	if (g_waypointeditor) {
		w.culltracemode = CULLTRACEMODE_NONE;
		m1 = w.mins;
		m2 = w.maxs;
		setmodel(w, "models/runematch/rune.mdl"); w.effects = EFFECT_LOWPRECISION;
		setsize(w, m1, m2);
		if (w.wpflags & WAYPOINTFLAG_ITEM)
			w.colormod = '1 0 0';
		else if (w.wpflags & WAYPOINTFLAG_TELEPORT)
			w.colormod = '0 1 1';
		else if (w.wpflags & WAYPOINTFLAG_GENERATED)
			w.colormod = '1 1 0';
		else
			w.colormod = '1 1 1';
	} else
		w.model = "";
}

// create a new spawnfunc_waypoint and automatically link it to other waypoints, and link
// them back to it as well
// (suitable for spawnfunc_waypoint editor)
entity(vector m1, vector m2, float f) waypoint_spawn {
	entity w;
	if not(f & WAYPOINTFLAG_PERSONAL)
	for (w = findradius((m1 + m2) * 0.5, vlen(m1 - m2) * 0.5 + 0.125); w; w = w.chain) {
		if (w.classname != "waypoint") continue;
		// if a matching spawnfunc_waypoint already exists, don't add a duplicate
		if (math_boxes_overlap(m1, m2, w.absmin, w.absmax))
			return w;
	}
	w = spawn();
	w.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
	if (g_waypoints_use_botclip)
		w.dphitcontentsmask |= DPCONTENTS_BOTCLIP;
	else
		w.dphitcontentsmask |= (DPCONTENTS_PLAYERCLIP | DPCONTENTS_MONSTERCLIP);

	w.classname = "waypoint";
	w.wpflags = f;
	setorigin(w, (m1 + m2) * 0.5);
	setsize(w, m1 - w.origin, m2 - w.origin);
	if (vlen(w.size) > 0)
		w.wpisbox = TRUE;
	
	if (!w.wpisbox) {
		setsize(w, PL_MIN - '1 1 0', PL_MAX + '1 1 0');
		if (!entity_move_out_of_solid(w)) {
			if (!(f & WAYPOINTFLAG_GENERATED)) {
				remove(w);
				return world;
			} else {
				if(cvar("developer")) {
					print("A generated waypoint is stuck in solid at ", vtos(w.origin), "\n");
					backtrace("Waypoint stuck");
				}
			}
		}
		setsize(w, '0 0 0', '0 0 0');
	}
	waypoint_clearlinks(w);
	waypoint_show(w);
	waypoint_count++;
	if (f & WAYPOINTFLAG_GENERATED) waypoint_generated_count++;
	return w;
}

// add a new link to the spawnfunc_waypoint, replacing the furthest link it already has
void(entity from, entity to) waypoint_addlink {
	float c;
	if (from == to)
		return;

	if (from.wp00 == to) return;if (from.wp01 == to) return;if (from.wp02 == to) return;if (from.wp03 == to) return;
	if (from.wp04 == to) return;if (from.wp05 == to) return;if (from.wp06 == to) return;if (from.wp07 == to) return;
	if (from.wp08 == to) return;if (from.wp09 == to) return;if (from.wp10 == to) return;if (from.wp11 == to) return;
	if (from.wp12 == to) return;if (from.wp13 == to) return;if (from.wp14 == to) return;if (from.wp15 == to) return;
	if (from.wp16 == to) return;if (from.wp17 == to) return;if (from.wp18 == to) return;if (from.wp19 == to) return;
	if (from.wp20 == to) return;if (from.wp21 == to) return;if (from.wp22 == to) return;if (from.wp23 == to) return;
	if (from.wp24 == to) return;if (from.wp25 == to) return;if (from.wp26 == to) return;if (from.wp27 == to) return;
	if (from.wp28 == to) return;if (from.wp29 == to) return;if (from.wp30 == to) return;if (from.wp31 == to) return;
	if (to.wpisbox || from.wpisbox) {
		// if either is a box we have to find the nearest points on them to
		// calculate the distance properly
		vector v1, v2, m1, m2;
		v1 = from.origin;
		m1 = to.absmin;
		m2 = to.absmax;
		v1_x = bound(m1_x, v1_x, m2_x);
		v1_y = bound(m1_y, v1_y, m2_y);
		v1_z = bound(m1_z, v1_z, m2_z);
		v2 = to.origin;
		m1 = from.absmin;
		m2 = from.absmax;
		v2_x = bound(m1_x, v2_x, m2_x);
		v2_y = bound(m1_y, v2_y, m2_y);
		v2_z = bound(m1_z, v2_z, m2_z);
		v2 = to.origin;
		c = vlen(v2 - v1);
	}
	else
		c = vlen(to.origin - from.origin);

	if (from.wp31mincost < c) return;
	if (from.wp30mincost < c) {from.wp31 = to;from.wp31mincost = c;return;} from.wp31 = from.wp30;from.wp31mincost = from.wp30mincost;
	if (from.wp29mincost < c) {from.wp30 = to;from.wp30mincost = c;return;} from.wp30 = from.wp29;from.wp30mincost = from.wp29mincost;
	if (from.wp28mincost < c) {from.wp29 = to;from.wp29mincost = c;return;} from.wp29 = from.wp28;from.wp29mincost = from.wp28mincost;
	if (from.wp27mincost < c) {from.wp28 = to;from.wp28mincost = c;return;} from.wp28 = from.wp27;from.wp28mincost = from.wp27mincost;
	if (from.wp26mincost < c) {from.wp27 = to;from.wp27mincost = c;return;} from.wp27 = from.wp26;from.wp27mincost = from.wp26mincost;
	if (from.wp25mincost < c) {from.wp26 = to;from.wp26mincost = c;return;} from.wp26 = from.wp25;from.wp26mincost = from.wp25mincost;
	if (from.wp24mincost < c) {from.wp25 = to;from.wp25mincost = c;return;} from.wp25 = from.wp24;from.wp25mincost = from.wp24mincost;
	if (from.wp23mincost < c) {from.wp24 = to;from.wp24mincost = c;return;} from.wp24 = from.wp23;from.wp24mincost = from.wp23mincost;
	if (from.wp22mincost < c) {from.wp23 = to;from.wp23mincost = c;return;} from.wp23 = from.wp22;from.wp23mincost = from.wp22mincost;
	if (from.wp21mincost < c) {from.wp22 = to;from.wp22mincost = c;return;} from.wp22 = from.wp21;from.wp22mincost = from.wp21mincost;
	if (from.wp20mincost < c) {from.wp21 = to;from.wp21mincost = c;return;} from.wp21 = from.wp20;from.wp21mincost = from.wp20mincost;
	if (from.wp19mincost < c) {from.wp20 = to;from.wp20mincost = c;return;} from.wp20 = from.wp19;from.wp20mincost = from.wp19mincost;
	if (from.wp18mincost < c) {from.wp19 = to;from.wp19mincost = c;return;} from.wp19 = from.wp18;from.wp19mincost = from.wp18mincost;
	if (from.wp17mincost < c) {from.wp18 = to;from.wp18mincost = c;return;} from.wp18 = from.wp17;from.wp18mincost = from.wp17mincost;
	if (from.wp16mincost < c) {from.wp17 = to;from.wp17mincost = c;return;} from.wp17 = from.wp16;from.wp17mincost = from.wp16mincost;
	if (from.wp15mincost < c) {from.wp16 = to;from.wp16mincost = c;return;} from.wp16 = from.wp15;from.wp16mincost = from.wp15mincost;
	if (from.wp14mincost < c) {from.wp15 = to;from.wp15mincost = c;return;} from.wp15 = from.wp14;from.wp15mincost = from.wp14mincost;
	if (from.wp13mincost < c) {from.wp14 = to;from.wp14mincost = c;return;} from.wp14 = from.wp13;from.wp14mincost = from.wp13mincost;
	if (from.wp12mincost < c) {from.wp13 = to;from.wp13mincost = c;return;} from.wp13 = from.wp12;from.wp13mincost = from.wp12mincost;
	if (from.wp11mincost < c) {from.wp12 = to;from.wp12mincost = c;return;} from.wp12 = from.wp11;from.wp12mincost = from.wp11mincost;
	if (from.wp10mincost < c) {from.wp11 = to;from.wp11mincost = c;return;} from.wp11 = from.wp10;from.wp11mincost = from.wp10mincost;
	if (from.wp09mincost < c) {from.wp10 = to;from.wp10mincost = c;return;} from.wp10 = from.wp09;from.wp10mincost = from.wp09mincost;
	if (from.wp08mincost < c) {from.wp09 = to;from.wp09mincost = c;return;} from.wp09 = from.wp08;from.wp09mincost = from.wp08mincost;
	if (from.wp07mincost < c) {from.wp08 = to;from.wp08mincost = c;return;} from.wp08 = from.wp07;from.wp08mincost = from.wp07mincost;
	if (from.wp06mincost < c) {from.wp07 = to;from.wp07mincost = c;return;} from.wp07 = from.wp06;from.wp07mincost = from.wp06mincost;
	if (from.wp05mincost < c) {from.wp06 = to;from.wp06mincost = c;return;} from.wp06 = from.wp05;from.wp06mincost = from.wp05mincost;
	if (from.wp04mincost < c) {from.wp05 = to;from.wp05mincost = c;return;} from.wp05 = from.wp04;from.wp05mincost = from.wp04mincost;
	if (from.wp03mincost < c) {from.wp04 = to;from.wp04mincost = c;return;} from.wp04 = from.wp03;from.wp04mincost = from.wp03mincost;
	if (from.wp02mincost < c) {from.wp03 = to;from.wp03mincost = c;return;} from.wp03 = from.wp02;from.wp03mincost = from.wp02mincost;
	if (from.wp01mincost < c) {from.wp02 = to;from.wp02mincost = c;return;} from.wp02 = from.wp01;from.wp02mincost = from.wp01mincost;
	if (from.wp00mincost < c) {from.wp01 = to;from.wp01mincost = c;return;} from.wp01 = from.wp00;from.wp01mincost = from.wp00mincost;
	from.wp00 = to;
	from.wp00mincost = c;
	return;
}

// relink this spawnfunc_waypoint
// (precompile a list of all reachable waypoints from this spawnfunc_waypoint)
// (SLOW!)
void(void) waypoint_think {
	entity e;
	vector sv, sm1, sm2, ev, em1, em2, dv;
	stepheightvec = sv_stepheight * '0 0 1';
	bot_navigation_movemode = TRACE_MOVE_NOMONSTERS;
	sm1 = self.origin + self.mins;
	sm2 = self.origin + self.maxs;
	for (e = world; (e = find(e, classname, "waypoint")); ) {
		if (math_boxes_overlap(self.absmin, self.absmax, e.absmin, e.absmax)) {
			waypoint_addlink(self, e);
			waypoint_addlink(e, self);
		} else {
			if (!checkpvs(self.origin, e)) {
				continue;
			}
			sv = e.origin;
			sv_x = bound(sm1_x, sv_x, sm2_x);
			sv_y = bound(sm1_y, sv_y, sm2_y);
			sv_z = bound(sm1_z, sv_z, sm2_z);
			ev = self.origin;
			em1 = e.origin + e.mins;
			em2 = e.origin + e.maxs;
			ev_x = bound(em1_x, ev_x, em2_x);
			ev_y = bound(em1_y, ev_y, em2_y);
			ev_z = bound(em1_z, ev_z, em2_z);
			dv = ev - sv;
			dv_z = 0;
			if (vlen(dv) >= 1050) { // max search distance in XY
				continue;
			}
			if (!self.wpisbox) {
				trace_box(sv - PL_MIN_z * '0 0 1', PL_MIN, PL_MAX, sv, FALSE, self);
				if (!trace_startsolid) {
					sv = trace_endpos + '0 0 1';
				}
			}
			if (!e.wpisbox) {
				trace_box(ev - PL_MIN_z * '0 0 1', PL_MIN, PL_MAX, ev, FALSE, e);
				if (!trace_startsolid) {
					ev = trace_endpos + '0 0 1';
				}
			}
			if (!self.wpisbox && trace_walk(self, sv, PL_MIN, PL_MAX, ev, TRACE_MOVE_NOMONSTERS))
				waypoint_addlink(self, e);

			if (!e.wpisbox && trace_walk(e, ev, PL_MIN, PL_MAX, sv, TRACE_MOVE_NOMONSTERS))
				waypoint_addlink(e, self);
		}
	}
	self.wplinked = TRUE;
	waypoint_schedulerelink_count--;
	if not(waypoint_schedulerelink_count) {
		print("Relinking waypoints finished\n");
		if (waypoint_schedulerelink_save) {
			waypoint_save_links();
			waypoint_schedulerelink_save = FALSE;
		}
	}
}

void(entity wp) waypoint_clearlinks {
	// clear links to other waypoints
	float f;
	f = 10000000;
	wp.wp00 = wp.wp01 = wp.wp02 = wp.wp03 = wp.wp04 = wp.wp05 = wp.wp06 = wp.wp07 = world;
	wp.wp08 = wp.wp09 = wp.wp10 = wp.wp11 = wp.wp12 = wp.wp13 = wp.wp14 = wp.wp15 = world;
	wp.wp16 = wp.wp17 = wp.wp18 = wp.wp19 = wp.wp20 = wp.wp21 = wp.wp22 = wp.wp23 = world;
	wp.wp24 = wp.wp25 = wp.wp26 = wp.wp27 = wp.wp28 = wp.wp29 = wp.wp30 = wp.wp31 = world;
	wp.wp00mincost = wp.wp01mincost = wp.wp02mincost = wp.wp03mincost = wp.wp04mincost = wp.wp05mincost = wp.wp06mincost = wp.wp07mincost = f;
	wp.wp08mincost = wp.wp09mincost = wp.wp10mincost = wp.wp11mincost = wp.wp12mincost = wp.wp13mincost = wp.wp14mincost = wp.wp15mincost = f;
	wp.wp16mincost = wp.wp17mincost = wp.wp18mincost = wp.wp19mincost = wp.wp20mincost = wp.wp21mincost = wp.wp22mincost = wp.wp23mincost = f;
	wp.wp24mincost = wp.wp25mincost = wp.wp26mincost = wp.wp27mincost = wp.wp28mincost = wp.wp29mincost = wp.wp30mincost = wp.wp31mincost = f;
	wp.wplinked = FALSE;
}

// tell a spawnfunc_waypoint to relink
void(entity wp) waypoint_schedulerelink {
	if not(wp)
		return;

	// TODO: add some sort of visible box in edit mode for box waypoints
	waypoint_show(wp);
	wp.wpisbox = vlen(wp.size) > 0;
	wp.enemy = world;
	if (!(wp.wpflags & WAYPOINTFLAG_PERSONAL))
		wp.owner = world;

	if ((wp.wpflags & WAYPOINTFLAG_NORELINK))
		return;

	waypoint_clearlinks(wp);
	// schedule an actual relink on next frame
	wp.think = waypoint_think;
	wp.nextthink = time;
	waypoint_schedulerelink_count++;
}

void(void) waypoint_target_init {
	entity e, e2 = NULL;
	if (self.target2 != "") e2 = find(NULL, targetname, self.target2);
	if not(e2) e2 = self;
	if ((e = find(NULL, targetname, self.target)))
	if (e.classname == "waypoint") {
		waypoint_spawnforteleporter(e2, e.origin, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_NORELINK);
		waypoint_presents_on_map = TRUE;
	}
	remove(self);
}

// spawnfunc_waypoint map entity
void(void) spawnfunc_waypoint {
	if (self.target != "") {
		entity_initialize(self, waypoint_target_init, INITPRIO_FINDTARGET);
		return;
	}
	vector v = self.origin;
	remove(self);
	waypoint_spawn(v, v, WAYPOINTFLAG_GENERATED);
	waypoint_presents_on_map = TRUE;
}

// remove a spawnfunc_waypoint, and schedule all neighbors to relink
void(entity e) waypoint_remove {
	// tell all linked waypoints that they need to relink
	waypoint_schedulerelink(e.wp00);
	waypoint_schedulerelink(e.wp01);
	waypoint_schedulerelink(e.wp02);
	waypoint_schedulerelink(e.wp03);
	waypoint_schedulerelink(e.wp04);
	waypoint_schedulerelink(e.wp05);
	waypoint_schedulerelink(e.wp06);
	waypoint_schedulerelink(e.wp07);
	waypoint_schedulerelink(e.wp08);
	waypoint_schedulerelink(e.wp09);
	waypoint_schedulerelink(e.wp10);
	waypoint_schedulerelink(e.wp11);
	waypoint_schedulerelink(e.wp12);
	waypoint_schedulerelink(e.wp13);
	waypoint_schedulerelink(e.wp14);
	waypoint_schedulerelink(e.wp15);
	waypoint_schedulerelink(e.wp16);
	waypoint_schedulerelink(e.wp17);
	waypoint_schedulerelink(e.wp18);
	waypoint_schedulerelink(e.wp19);
	waypoint_schedulerelink(e.wp20);
	waypoint_schedulerelink(e.wp21);
	waypoint_schedulerelink(e.wp22);
	waypoint_schedulerelink(e.wp23);
	waypoint_schedulerelink(e.wp24);
	waypoint_schedulerelink(e.wp25);
	waypoint_schedulerelink(e.wp26);
	waypoint_schedulerelink(e.wp27);
	waypoint_schedulerelink(e.wp28);
	waypoint_schedulerelink(e.wp29);
	waypoint_schedulerelink(e.wp30);
	waypoint_schedulerelink(e.wp31);
	// and now remove the spawnfunc_waypoint
	remove(e);
	waypoint_count--;
}

// empties the map of waypoints
void(void) waypoint_removeall {
	entity head, next;
	head = findchain(classname, "waypoint");
	while (head) {
		next = head.chain;
		remove(head);
		head = next;
	}
	waypoint_count = 0;
}

// tell all waypoints to relink
// (is this useful at all?)
void(void) waypoint_schedulerelinkall {
	print("Relinking all waypoints\n");
	entity head;
	head = findchain(classname, "waypoint");
	float t = 0;
	while (head) {
		waypoint_schedulerelink(head);
		if (head.nextthink) {
			t += 0.01;
			head.nextthink += t;
		}
		head = head.chain;
	}
}

string(string mapname) waypoint_link_cache_path {
	return strcat("maps/", mapname, ".waypoints.", ftos(waypoint_count), (g_waypoints_use_botclip ? ".cache-monster" : ".cache-bot"));
}

// Load waypoint links from file
float(void) waypoint_load_links {
	string filename, s;
	float file, tokens, found;
	entity wp_from = NULL, wp_to;
	vector wp_to_pos, wp_from_pos;
	filename = waypoint_link_cache_path(mapname);
	file = fopen(filename, FILE_READ);
	if (file < 0) {
		print("Cannot open file: ", filename, "\n");
		return FALSE;
	}
	print("Loading waypoint links from ", filename, "\n");
	while (1) {
		s = fgets(file);
		if (!s)
			break;

		tokens = tokenizebyseparator(s, "*");
		if (tokens!=2) {
			// bad file format
			fclose(file);
			return FALSE;
		}
		wp_from_pos = stov(argv(0));
		wp_to_pos = stov(argv(1));
		// Search "from" waypoint
		if (wp_from.origin!=wp_from_pos) {
			wp_from = findradius(wp_from_pos, 1);
			found = FALSE;
			while (wp_from) {
				if (vlen(wp_from.origin-wp_from_pos) < 1)
				if (wp_from.classname == "waypoint") {
					found = TRUE;
					break;
				}
				wp_from = wp_from.chain;
			}
			if (!found) {
				// can't find that waypoint
				fclose(file);
				return FALSE;
			}
		}
		// Search "to" waypoint
		wp_to = findradius(wp_to_pos, 1);
		found = FALSE;
		while (wp_to) {
			if (vlen(wp_to.origin-wp_to_pos) < 1)
			if (wp_to.classname == "waypoint") {
				found = TRUE;
				break;
			}
			wp_to = wp_to.chain;
		}
		if (!found) {
			// can't find that waypoint
			fclose(file);
			return FALSE;
		}
		waypoint_addlink(wp_from, wp_to);
	}
	fclose(file);
	return TRUE;
}

// Save all waypoint links to a file
void(void) waypoint_save_links {
	string filename, s;
	float file, c, i;
	entity w, link = NULL;
	filename = waypoint_link_cache_path(mapname);
	file = fopen(filename, FILE_WRITE);
	if (file < 0) {
		print("waypoint links save to ");
		print(filename);
		print(" failed\n");
	}
	c = 0;
	w = findchain(classname, "waypoint");
	while (w) {
		for (i = 0; i < 32; ++i) {
			switch(i) {
			case 0:link = w.wp00; break;
			case 1:link = w.wp01; break;
			case 2:link = w.wp02; break;
			case 3:link = w.wp03; break;
			case 4:link = w.wp04; break;
			case 5:link = w.wp05; break;
			case 6:link = w.wp06; break;
			case 7:link = w.wp07; break;
			case 8:link = w.wp08; break;
			case 9:link = w.wp09; break;
			case 10:link = w.wp10; break;
			case 11:link = w.wp11; break;
			case 12:link = w.wp12; break;
			case 13:link = w.wp13; break;
			case 14:link = w.wp14; break;
			case 15:link = w.wp15; break;
			case 16:link = w.wp16; break;
			case 17:link = w.wp17; break;
			case 18:link = w.wp18; break;
			case 19:link = w.wp19; break;
			case 20:link = w.wp20; break;
			case 21:link = w.wp21; break;
			case 22:link = w.wp22; break;
			case 23:link = w.wp23; break;
			case 24:link = w.wp24; break;
			case 25:link = w.wp25; break;
			case 26:link = w.wp26; break;
			case 27:link = w.wp27; break;
			case 28:link = w.wp28; break;
			case 29:link = w.wp29; break;
			case 30:link = w.wp30; break;
			case 31:link = w.wp31; break;
			}
			if (link == world)
				continue;

			s = strcat(vtos(w.origin), "*", vtos(link.origin), "\n");
			fputs(file, s);
			++c;
		}
		w = w.chain;
	}
	fclose(file);
	print("saved ");
	print(ftos(c));
	print(" waypoints links to ");
	print(filename);
	print("\n");
}

// save waypoints to gamedir/data/maps/mapname.waypoints
void(float autogenerated) waypoint_saveall {
	string filename, s;
	float file, c;
	entity w;
	filename = strcat("maps/", mapname);
	filename = strcat(filename, ".waypoints", (autogenerated ? strcat(".autogenerated-", ftos(waypoint_generated_count)) : ""));
	file = fopen(filename, FILE_WRITE);
	if (file >= 0) {
		c = 0;
		w = findchain(classname, "waypoint");
		while (w) {
			if (!(w.wpflags & WAYPOINTFLAG_GENERATED)) {
				s = strcat(vtos(w.origin + w.mins), "\n");
				s = strcat(s, vtos(w.origin + w.maxs));
				s = strcat(s, "\n");
				s = strcat(s, ftos(w.wpflags));
				s = strcat(s, "\n");
				fputs(file, s);
				c = c + 1;
			}
			w = w.chain;
		}
		fputs(file, "//end\n"); //prevent empty waypoints file
		fclose(file);
		print("saved ");
		print(ftos(c));
		print(" waypoints to ");
		print(filename);
		print("\n");
	} else {
		print("waypoint save to ");
		print(filename);
		print(" failed\n");
	}
	if not(waypoint_schedulerelink_save)
		waypoint_save_links();
}

float waypoint_path_generator_count;
entity(float dir, vector from, vector lastwp, float depth) waypoint_path_generator_spawn;
void(void) waypoint_path_generator_think {
	vector dirv = '0 0 0';
	float dirback = -1;
	switch (self.cnt) {
	case 0:
		dirv = '1 0 0';
		dirback = 2;
		break;
	case 1:
		dirv = '0 1 0';
		dirback = 3;
		break;
	case 2:
		dirv = '-1 0 0';
		dirback = 0;
		break;
	case 3:
		dirv = '0 -1 0';
		dirback = 1;
		break;
	}
	trace_walk(self, self.origin, PL_MIN, PL_MAX, self.origin + dirv * 225, TRACE_MOVE_NOMONSTERS);
	if (vlen(trace_endpos - self.pos1) <= 50) goto removegenerator;
	trace_walk(self, trace_endpos, PL_MIN, PL_MAX, trace_endpos - dirv * 25, TRACE_MOVE_NOMONSTERS);
	vector v = trace_endpos;
	trace_box(self.origin, PL_MIN, PL_MAX, self.origin - '0 0 1', TRACE_MOVE_NOMONSTERS, self);
	if (trace_fraction < 1 && trace_plane_normal_z < 0.7) goto removegenerator;
	if ((trace_dpstartcontents | trace_dphitcontents) & DPCONTENTS_NODROP)
		goto removegenerator;

	for (entity e = findradius(v, 50); e; e = e.chain) {
		if (e == self) continue;
		if (e.classname == "waypoint" && !e.wpflags) goto removegenerator;
		if (e.classname == "waypoint_path_generator") goto removegenerator;
		if (e.classname == "trigger_hurt") goto removegenerator;
	}
	if (vlen(v - self.pos1) > 800 || !trace_walk(self, self.pos1, PL_MIN, PL_MAX, v, TRACE_MOVE_NOMONSTERS)) {
		waypoint_spawn(self.origin, self.origin, 0);
		self.pos1 = self.origin;
	}
	if not(v_x > world.mins_x && v_x < world.maxs_x
			&& v_y > world.mins_y && v_y < world.maxs_y
			&& v_z > world.mins_z && v_z < world.maxs_z)
		goto removegenerator;

	for (entity e = findradius(v, 500); e; e = e.chain) {
		if (e != self)
		if ((e.classname == "waypoint_path_generator" && e.cnt != self.cnt) || (e.classname == "waypoint" && !e.wpflags))
		if (dirv * (e.origin - v) > 0.5)
		if (trace_walk(self, v, PL_MIN, PL_MAX, e.origin, TRACE_MOVE_NOMONSTERS))
		if (trace_walk(self, e.origin, PL_MIN, PL_MAX, v, TRACE_MOVE_NOMONSTERS)) {
			if not(trace_walk(self, self.pos1, PL_MIN, PL_MAX, e.origin, TRACE_MOVE_NOMONSTERS))
			if not(trace_walk(self, e.origin, PL_MIN, PL_MAX, self.pos1, TRACE_MOVE_NOMONSTERS)) {
				for (entity e2 = findradius(v, 50); e2; e2 = e2.chain) {
					if (e2.classname == "waypoint" && !e2.wpflags) goto removegenerator;
				}
				waypoint_spawn(v, v, 0);
			}
			goto removegenerator;
		}
	}
	self.count--;
	if (self.count <= 0) {
		goto removegenerator;
	}
	setorigin(self, v);
	for (float i = 0; i < 4; i++) {
		if (i != self.cnt && i != dirback)
			waypoint_path_generator_spawn(i, v, self.pos1, self.count);
	}
	self.nextthink = time + 0.1;
	return;
:removegenerator
	waypoint_path_generator_count--;
	if (waypoint_path_generator_count == 0) {
		print(strcat("Automatic waypoint generation finished with ", ftos(waypoint_count - waypoint_generated_count), " waypoints\n"));
		waypoint_schedulerelink_save = TRUE;
		waypoint_schedulerelinkall();
		waypoint_saveall(TRUE);
	}
	remove(self);
	return;
}

float waypoint_path_generator_count_warning;
entity(float dir, vector from, vector lastwp, float depth) waypoint_path_generator_spawn {
	if (waypoint_path_generator_count >= 2048) {
		if not(waypoint_path_generator_count_warning) {
			waypoint_path_generator_count_warning = TRUE;
			print("waypoint_path_generator_spawn: too much path generators\n");
		}
		return NULL;
	}
	entity e = spawn();
	e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setorigin(e, from);
	e.pos1 = lastwp;
	e.cnt = dir;
	e.count = depth;
	e.think = waypoint_path_generator_think;
	e.nextthink = time + 0.1;
	e.classname = "waypoint_path_generator";
	if (!entity_move_out_of_solid(e)) {
		remove(e);
		return NULL;
	}
	waypoint_path_generator_count++;
	return e;
}

void(void) waypoint_generate_waypoints {
	entity e;
	float i;
	for (e = NULL; (e = find(e, classname, "waypoint")); ) {
		if not(e.wpflags) {
			remove(e);
			waypoint_count--;
		}
	}
	for (e = NULL; (e = find(e, classname, "waypoint")); ) {
		if not(e.wpflags & WAYPOINTFLAG_GENERATED) continue;
		for (i = 0; i < 4; i++) {
			waypoint_path_generator_spawn(i, e.origin, e.origin, 18);
		}
	}
	print(strcat("Automatic waypoint generation started with ", ftos(waypoint_path_generator_count), " path generators\n"));
}

// load waypoints from file
float(void) waypoint_loadall {
	string filename, s;
	float file, cwp, cwb, fl;
	vector m1, m2;
	cwp = 0;
	cwb = 0;
	filename = strcat("maps/", mapname);
	filename = strcat(filename, ".waypoints");
	file = fopen(filename, FILE_READ);
	if (file < 0) {
		filename = strcat("maps/", mapname);
		filename = strcat(filename, strcat(".waypoints.autogenerated-", ftos(waypoint_generated_count)));
		file = fopen(filename, FILE_READ);
	}
	if (file >= 0) {
		print("Loading waypoints from ", filename, "\n");
		while (1) {
			s = fgets(file);
			if (!s)
				break;

			m1 = stov(s);
			s = fgets(file);
			if (!s)
				break;

			m2 = stov(s);
			s = fgets(file);
			if (!s)
				break;

			fl = stof(s);
			waypoint_spawn(m1, m2, fl);
			if (m1 == m2)
				cwp = cwp + 1;
			else
				cwb = cwb + 1;
		}
		fclose(file);
	}
	return cwp + cwb;
}

vector(vector position) waypoint_fixorigin {
	trace_box(position + '0 0 1' * (1 - PL_MIN_z), PL_MIN, PL_MAX, position + '0 0 -512', TRACE_MOVE_NOMONSTERS, world);
	if(trace_fraction < 1)
		position = trace_endpos;

	return position;
}

void(entity e, vector org) waypoint_spawnforitem_force {
	entity w;
	// Fix the waypoint altitude if necessary
	org = waypoint_fixorigin(org);
	// don't spawn an item spawnfunc_waypoint if it already exists
	w = findchain(classname, "waypoint");
	while (w) {
		if (w.wpisbox) {
			if (math_boxes_overlap(org, org, w.absmin, w.absmax)) {
				e.nearestwaypoint = w;
				return;
			}
		} else {
			if (vlen(w.origin - org) < 16) {
				e.nearestwaypoint = w;
				return;
			}
		}
		w = w.chain;
	}
	e.nearestwaypoint = waypoint_spawn(org, org, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_ITEM);
}

void(entity e) waypoint_spawnforitem {
	if (!bot_waypoints_for_items)
		return;

	waypoint_spawnforitem_force(e, e.origin);
}

void(entity e, vector destination, float timetaken) waypoint_spawnforteleporter {
	entity w;
	entity dw;
	w = waypoint_spawn(e.absmin, e.absmax, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_NORELINK);
	dw = waypoint_spawn(destination, destination, WAYPOINTFLAG_GENERATED);
	// one way link to the destination
	w.wp00 = dw;
	w.wp00mincost = timetaken; // this is just for jump pads
	// the teleporter's nearest spawnfunc_waypoint is this one
	// (teleporters are not goals, so this is probably useless)
	e.nearestwaypoint = w;
	e.nearestwaypointtimeout = time + 1000000000;
}

entity(vector position) waypoint_spawnpersonal {
	entity w;
	// drop the waypoint to a proper location:
	//   first move it up by a player height
	//   then move it down to hit the floor with player bbox size
	position = waypoint_fixorigin(position);
	w = waypoint_spawn(position, position, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_PERSONAL);
	w.nearestwaypoint = world;
	w.nearestwaypointtimeout = 0;
	w.owner = self;
	waypoint_schedulerelink(w);
	return w;
}

float waypoint_editorlightningtime;
void(void) waypoint_show_links {
	entity player, head, w;
	if (time < waypoint_editorlightningtime)
		return;

	waypoint_editorlightningtime = time + 0.5;
	player = find(world, classname, "player");
	while (player) {
		if (!player.isbot)
		if (player.flags & FL_ONGROUND || player.waterlevel > WATERLEVEL_NONE) {
			head = navigation_findnearestwaypoint(player, FALSE);
			if (head) {
				w = head     ;if (w) te_lightning2(world, w.origin, player.origin);
				w = head.wp00;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp01;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp02;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp03;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp04;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp05;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp06;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp07;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp08;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp09;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp10;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp11;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp12;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp13;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp14;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp15;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp16;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp17;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp18;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp19;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp20;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp21;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp22;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp23;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp24;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp25;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp26;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp27;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp28;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp29;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp30;if (w) te_lightning2(world, w.origin, head.origin);
				w = head.wp31;if (w) te_lightning2(world, w.origin, head.origin);
			}
		}
		player = find(player, classname, "player");
	}
}

void(float imp) waypoint_impulse {
	if (g_waypointeditor) {
		entity e, e2;
		float i, m;
		vector org;
		switch (imp) {
		case 103:
			waypoint_schedulerelink(waypoint_spawn(self.origin, self.origin, 0));
			bprint(strcat("Waypoint spawned at ",vtos(self.origin),"\n"));
			break;
		case 104:
			e = navigation_findnearestwaypoint(self, FALSE);
			if (e)
			if not(e.wpflags & WAYPOINTFLAG_GENERATED) {
				bprint(strcat("Waypoint removed at ",vtos(e.origin),"\n"));
				waypoint_remove(e);
			}
			break;
		case 105:
			waypoint_schedulerelinkall();
			break;
		case 106:
			waypoint_saveall(FALSE);
			break;
		case 107:
			for (e = findchain(classname, "waypoint"); e; e = e.chain) {
				e.colormod_x = 1;
				e.effects &= ~(EFFECT_NODEPTHTEST | EFFECT_RED | EFFECT_BLUE);
			}
			e2 = navigation_findnearestwaypoint(self, FALSE);
			navigation_markroutes(e2);
			i = 0;
			m = 0;
			for (e = findchain(classname, "waypoint"); e; e = e.chain) {
				if (e.wpcost >= 10000000) {
					print("unreachable: ", etos(e), " ", vtos(e.origin), "\n");
					e.colormod_x = 0.1;
					e.effects |= EFFECT_NODEPTHTEST | EFFECT_BLUE;
					++i;
					++m;
				}
			}
			if (i)
				print(ftos(i), " waypoints cannot be reached from here in any way (marked with blue light)\n");

			navigation_markroutes_inverted(e2);
			i = 0;
			for (e = findchain(classname, "waypoint"); e; e = e.chain) {
				if (e.wpcost >= 10000000) {
					print("cannot reach me: ", etos(e), " ", vtos(e.origin), "\n");
					e.colormod_x = 0.1;
					if not(e.effects & EFFECT_NODEPTHTEST) // not already reported before
						++m;
					e.effects |= EFFECT_NODEPTHTEST | EFFECT_RED;
					++i;
				}
			}
			if (i)
				print(ftos(i), " waypoints cannot walk to here in any way (marked with red light)\n");

			if (m)
				print(ftos(m), " waypoints have been marked total\n");

			i = 0;
			for (e = findchain(classname, "info_player_deathmatch"); e; e = e.chain) {
				org = e.origin;
				trace_box(e.origin, PL_MIN, PL_MAX, e.origin - '0 0 512', TRACE_MOVE_NOMONSTERS, world);
				setorigin(e, trace_endpos);
				if (navigation_findnearestwaypoint(e, FALSE)) {
					setorigin(e, org);
					e.effects &= ~EFFECT_NODEPTHTEST;
					e.model = "";
				} else {
					setorigin(e, org);
					print("spawn without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
					e.effects |= EFFECT_NODEPTHTEST;
					setmodel(e, self.body.model);
					e.frame = self.body.frame;
					e.skin = self.body.skin;
					setsize(e, '0 0 0', '0 0 0');
					++i;
				}
			}
			if (i)
				print(ftos(i), " spawnpoints have no nearest waypoint (marked by player model)\n");

			break;
		}
	}
}

void(void) waypoint_init_delayed {
	if (!waypoint_loadall()) {
		print("Loading waypoints failed\n");
		if (cvar("g_waypoints_auto_generate") && !waypoint_presents_on_map) {
			waypoint_generate_waypoints();
			return;
		}
	}
	if (!waypoint_load_links()) {
		print("Loading cached waypoint links failed\n");
		waypoint_schedulerelinkall();
		waypoint_schedulerelink_save = TRUE;
	}
}

void(void) waypoint_init {
	CVAR_CACHE(g_waypointeditor);
	CVAR_CACHE(g_waypoints_use_botclip);
	entity w = world;
	while ((w = find(w, classname, "waypoint"))) {
		waypoint_show(w);
	}
	precache_model("models/runematch/rune.mdl");
	if not(waypoint_count)
		entity_initialize(self, waypoint_init_delayed, INITPRIO_LAST);
}
