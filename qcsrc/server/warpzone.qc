.vector warpzone_oldorigin, warpzone_oldvelocity, warpzone_oldangles;
.float warpzone_teleport_time;
.float warpzone_teleport_finishtime;
.entity warpzone_teleport_zone;
void(void) warpzone_init_delayed;
void(entity me, entity wz) warpzone_refsys_add;

float warpzone_trace_allsolid_saved;
float warpzone_trace_startsolid_saved;
float warpzone_trace_fraction_saved;
vector warpzone_trace_endpos_saved;
vector warpzone_trace_plane_normal_saved;
float warpzone_trace_plane_dist_saved;
entity warpzone_trace_ent_saved;
float warpzone_trace_dpstartcontents_saved;
float warpzone_trace_dphitcontents_saved;
float warpzone_trace_dphitq3surfaceflags_saved;
//string warpzone_trace_dphittexturename_saved;
vector warpzone_v_forward_saved;
vector warpzone_v_up_saved;
vector warpzone_v_right_saved;

void(void) warpzone_save_trace_globals {
	warpzone_trace_allsolid_saved = trace_allsolid;
	warpzone_trace_startsolid_saved = trace_startsolid;
	warpzone_trace_fraction_saved = trace_fraction;
	warpzone_trace_endpos_saved = trace_endpos;
	warpzone_trace_plane_normal_saved = trace_plane_normal;
	warpzone_trace_plane_dist_saved = trace_plane_dist;
	warpzone_trace_ent_saved = trace_ent;
	warpzone_trace_dpstartcontents_saved = trace_dpstartcontents;
	warpzone_trace_dphitcontents_saved = trace_dphitcontents;
	warpzone_trace_dphitq3surfaceflags_saved = trace_dphitq3surfaceflags;
	//warpzone_trace_dphittexturename_saved = trace_dphittexturename;
	warpzone_v_forward_saved = v_forward;
	warpzone_v_up_saved = v_up;
	warpzone_v_right_saved = v_right;
}

void(void) warpzone_restore_trace_globals {
	trace_allsolid = warpzone_trace_allsolid_saved;
	trace_startsolid = warpzone_trace_startsolid_saved;
	trace_fraction = warpzone_trace_fraction_saved;
	trace_endpos = warpzone_trace_endpos_saved;
	trace_plane_normal = warpzone_trace_plane_normal_saved;
	trace_plane_dist = warpzone_trace_plane_dist_saved;
	trace_ent = warpzone_trace_ent_saved;
	trace_dpstartcontents = warpzone_trace_dpstartcontents_saved;
	trace_dphitcontents = warpzone_trace_dphitcontents_saved;
	trace_dphitq3surfaceflags = warpzone_trace_dphitq3surfaceflags_saved;
	//trace_dphittexturename = warpzone_trace_dphittexturename_saved;
	v_forward = warpzone_v_forward_saved;
	v_up = warpzone_v_up_saved;
	v_right = warpzone_v_right_saved;
}

void(entity e) warpzone_projectile_store {
	e.warpzone_oldorigin = e.origin;
	e.warpzone_oldvelocity = e.velocity;
	e.warpzone_oldangles = e.angles;
}

void(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity) warzpone_teleport_player { //actually it's not only players
	makevectors(to_angles);
	teleport_origin_set(player, to, 0);
	player.angles = to_angles;
	player.velocity = to_velocity;
	if (player.classname == "player")
		player.flags &= ~FL_ONGROUND;

	projectile_update_after_teleport(player);
}

float(entity to, float sf) warpzone_teleported_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_WARPZONE_TELEPORTED);
	net_write_coord(MSG_ENTITY, self.angles_x);
	net_write_coord(MSG_ENTITY, self.angles_y);
	net_write_coord(MSG_ENTITY, self.angles_z);
	net_write_coord(MSG_ENTITY, self.owner.v_angle_x);
	net_write_coord(MSG_ENTITY, self.owner.v_angle_y);
	net_write_coord(MSG_ENTITY, num_for_edict(self.enemy));
	return TRUE;
}

float(void) warpzone_teleported_customize {
	if (other == self.owner)
		return TRUE;

	if (other.enemy == self.owner && other.classname == "spectator")
		return TRUE;

	return FALSE;
}

vector(entity e) warpzone_entity_origin_offset {
	vector ofs;
	if (e.classname == "player" || e.classname == "observer") {
		ofs = e.view_ofs;
		ofs_x = bound(e.mins_x, ofs_x, e.maxs_x);
		ofs_y = bound(e.mins_y, ofs_y, e.maxs_y);
		ofs_z = bound(e.mins_z, ofs_z, e.maxs_z);
	} else {
		ofs = (e.mins + e.maxs) * .5;
	}
	return ofs;
}

float(entity wz, entity e) warpzone_teleport {
	vector o0, a0, v0, o1, a1, v1, o10;
	vector ofs = warpzone_entity_origin_offset(e);
	o0 = e.origin + ofs;
	//if not(warpzone_find(o0, o0)) return 0; // this check not needed, already done in warpzone_touch trough warpzone_plane_dist
	v0 = e.velocity;
	a0 = e.angles;
	o10 = o1 = warpzone_transform_origin(wz, o0);
	v1 = warpzone_transform_velocity(wz, v0);
	if not(clienttype(e) == CLIENTTYPE_NOTACLIENT)
		a1 = warpzone_transform_vangles(wz, e.v_angle);
	else
		a1 = warpzone_transform_angles(wz, a0);

	entity w2 = warpzone_find(o1, o1);
	if (w2 && w2 == wz.enemy) {
		float d = warpzone_plane_dist(w2, o1);
		o1 += w2.warpzone_forward * (0.125 - min(d, 0));
	}
	// put him out of solid
	if (e.movetype != MOVETYPE_NOCLIP && e.classname != "observer") {
		if (warpzone_move_out_of_solid(wz, e, o1 - ofs, ofs)) {
			o1 = warpzone_move_out_of_solid_origin + ofs;
		} else
			return 0;
	}
	if (wz.enemy) {
		if (wz.enemy.warpzone_forward_z != 0) {
			float s = sv_gravity * .5;
			float s2 = v1 * wz.enemy.warpzone_forward;
			if (s2 < s)
				v1 += wz.enemy.warpzone_forward * (s - s2);
		}
	}
	// do the teleport
	warpzone_refsys_add(e, wz);
	if not(e.flags & FL_PROJECTILE) {
		entity h;
		for (h = world; (h = findentity(h, aiment, e)); ) {
			if (h.movetype == MOVETYPE_FOLLOW) {
				warpzone_refsys_add(h, wz);
			}
		}
	}
	warzpone_teleport_player(wz, e, o1 - ofs, a1, v1);
	warpzone_projectile_store(e);
	e.warpzone_teleport_time = time;
	e.warpzone_teleport_finishtime = time;
	e.warpzone_teleport_zone = wz;
	// prevent further teleports back
	float dt = (o1 - o10) * v1 * (1 / (v1 * v1));
	if (dt < frametime)
		e.warpzone_teleport_finishtime += frametime - dt;

	if (e.classname == "player" || e.classname == "observer") {
		// instead of fixangle, send the transform to the client for smoother operation
		entity ts = spawn();
		setmodel(ts, "null");
		ts.SendEntity = warpzone_teleported_send;
		ts.SendFlags = 0xFFFFFF;
		ts.think = stdproc_remove;
		ts.nextthink = time + 1;
		ts.owner = e;
		ts.enemy = wz;
		ts.effects = EFFECT_NODEPTHTEST;
		ts.classname = "warpzone_teleported";
		ts.angles = wz.warpzone_transform;
		ts.customizeentityforclient = warpzone_teleported_customize;
	}
	return 1;
}

float(void) warpzone_shadow_customizeentity {
	if (other == self.owner)
		return FALSE;

	entity o = self.owner;
	if (o.body.body) o = o.body.body;
	if (o.customizeentityforclient) {
		entity e = self;
		self = o;
		float f = self.customizeentityforclient();
		self = e;
		if not(f)
			return FALSE;
	}
	self.alpha = o.alpha;
	self.effects = o.effects;
	return TRUE;
}

.entity wz_shadow;
void(void) warpzone_shadow_think {
	float remove_needed;
	remove_needed = FALSE;
	if (self.owner.wz_shadow != self) {
		remove_needed = TRUE;
	}
	entity o = self.owner;
	entity b;
	vector a = o.angles;
	if (o.body) {
		b = o.body;
		a += b.angles;
	} else
		b = o;

	if (warpzone_find(o.origin + o.mins, o.origin + o.maxs) != self.enemy) {
		self.owner.wz_shadow = world;
		remove_needed = TRUE;
	}
	if (remove_needed) {
		if (self.takedamage)
			antilag_remove(self);

		remove(self);
		return;
	}
	self.nextthink = time;
	if (self.modelindex != b.modelindex)
		setmodel(self, b.model);

	setsize(self, o.mins, o.maxs);
	self.frame = b.frame;
	self.colormap = b.colormap;
	self.color = b.color;
	self.angles = warpzone_transform_angles(self.enemy, a);
	self.skin = b.skin;
	self.solid = o.solid;
	setorigin(self, warpzone_transform_origin(self.enemy, o.origin));
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) warpzone_shadow_event_damage {
	if (damage_radius_running) //No need proxy splash damage
		return;

	damage(self.owner, inflictor, attacker, _damage, deathtype, warpzone_untransform_origin(self.enemy, hitloc), warpzone_untransform_velocity(self.enemy, force));
	self.velocity = '0 0 0';
}

void(void) warpzone_touch {
	entity oldself;
	if (other.classname == "trigger_warpzone")
		return;

	if (time <= other.warpzone_teleport_finishtime) // already teleported this frame
		return;

	if (!warpzone_box_touches_brush(other.absmin, other.absmax, self, other))
		return;

	if (other.movetype == MOVETYPE_FOLLOW || other.tag_entity)
		return;

	if (warpzone_plane_dist(self, other.origin + warpzone_entity_origin_offset(other)) >= 0) {// wrong side of the trigger_warpzone (don't teleport yet)
		if (other.modelindex) {
			entity e = other.wz_shadow;
			if (!e || e.enemy != self) {
				e = other.wz_shadow = spawn();
				e.classname = "wzshadow";
				e.enemy = self;
				e.customizeentityforclient = warpzone_shadow_customizeentity;
				e.nextthink = time;
				e.think = warpzone_shadow_think;
				e.owner = other;
				e.solid = other.solid;
				if (other.takedamage) {
					e.takedamage = other.takedamage;
					e.event_damage = warpzone_shadow_event_damage;
				}
				if (antilag_have(e))
					antilag_add(e);
			}
		}
		return;
	}
	// FIXME needs a better check to know what is safe to teleport and what not
	if (other.movetype == MOVETYPE_NONE)
		return;

	if (other.classname == "observer") {
		warpzone_teleport(self, other);
		return;
	}
	if (warpzone_teleport(self, other)) {
		string save1, save2;
		activator = other;
		save1 = self.target; self.target = NULL;
		save2 = self.target3; self.target3 = NULL;
		trigger_use_targets();
		if not(self.target) self.target = save1;
		if not(self.target3) self.target3 = save2;
		oldself = self;
		self = self.enemy;
		save1 = self.target; self.target = NULL;
		save2 = self.target2; self.target2 = NULL;
		trigger_use_targets();
		if not(self.target) self.target = save1;
		if not(self.target2) self.target2 = save2;
		self = oldself;
	}
}

float(entity to, float sendflags) warpzone_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_WARPZONE);
	// we need THESE to render the warpzone (and cull properly)...
	net_write_coord(MSG_ENTITY, self.origin_x);
	net_write_coord(MSG_ENTITY, self.origin_y);
	net_write_coord(MSG_ENTITY, self.origin_z);
	net_write_short(MSG_ENTITY, self.modelindex);
	net_write_coord(MSG_ENTITY, self.mins_x);
	net_write_coord(MSG_ENTITY, self.mins_y);
	net_write_coord(MSG_ENTITY, self.mins_z);
	net_write_coord(MSG_ENTITY, self.maxs_x);
	net_write_coord(MSG_ENTITY, self.maxs_y);
	net_write_coord(MSG_ENTITY, self.maxs_z);
	net_write_byte(MSG_ENTITY, bound(1, self.scale * 16, 255));
	// we need THESE to calculate the proper transform
	net_write_coord(MSG_ENTITY, self.warpzone_origin_x);
	net_write_coord(MSG_ENTITY, self.warpzone_origin_y);
	net_write_coord(MSG_ENTITY, self.warpzone_origin_z);
	net_write_coord(MSG_ENTITY, self.warpzone_angles_x);
	net_write_coord(MSG_ENTITY, self.warpzone_angles_y);
	net_write_coord(MSG_ENTITY, self.warpzone_angles_z);
	net_write_coord(MSG_ENTITY, self.warpzone_targetorigin_x);
	net_write_coord(MSG_ENTITY, self.warpzone_targetorigin_y);
	net_write_coord(MSG_ENTITY, self.warpzone_targetorigin_z);
	net_write_coord(MSG_ENTITY, self.warpzone_targetangles_x);
	net_write_coord(MSG_ENTITY, self.warpzone_targetangles_y);
	net_write_coord(MSG_ENTITY, self.warpzone_targetangles_z);
	net_write_coord(MSG_ENTITY, num_for_edict(self));
	return TRUE;
}

float(void) warpzone_projectile_impact_check {
	// if self hit a warpzone, abort
	vector o0, v0, a0;
	float mpd, pd, dpd;
	entity wz;
	warpzone_save_trace_globals();
	wz = warpzone_find(self.origin + self.mins, self.origin + self.maxs);
	warpzone_restore_trace_globals();
	if (!wz)
		return FALSE;

	o0 = self.origin;
	v0 = self.velocity;
	a0 = self.angles;
	// this approach transports the projectile at its full speed, but does
	// not properly retain the projectile trail (but we can't retain it
	// easily anyway without delaying the projectile by two frames, so who
	// cares)
	warpzone_trace_box_trough_zone(self.warpzone_oldorigin, self.mins, self.maxs, self.warpzone_oldorigin + self.warpzone_oldvelocity * frametime, TRACE_MOVE_NORMAL, self, wz, NULL); // this will get us through the warpzone
	setorigin(self, trace_endpos);
	self.angles = warpzone_transform_angles(warpzone_trace_transform, self.angles);
	self.velocity = warpzone_transform_velocity(warpzone_trace_transform, self.velocity);
	if (trace_fraction < 1) //We hit something right behind warp
		return FALSE;
	
	// in case we are in our warp zone post-teleport, shift the projectile forward a bit
	mpd = max(vlen(self.mins), vlen(self.maxs));
	pd = warpzone_target_plane_dist(wz, self.origin);
	if (pd < mpd) {
		dpd = normalize(self.velocity) * self.warpzone_targetforward;
		setorigin(self, self.origin + normalize(self.velocity) * ((mpd - pd) / dpd));
		if (!entity_move_out_of_solid(self)) {
			setorigin(self, o0);
			self.angles = a0;
			self.velocity = v0;
			return FALSE;
		}
	}
	warpzone_refsys_add(self, wz);
	warpzone_projectile_store(self);
	self.warpzone_teleport_time = time;
	return TRUE;
}

var float() warpzone_projectile_touch_handle_next;
float() warpzone_projectile_touch_handle {
	if (other.classname == "trigger_warpzone")
		goto return_true;

	if (warpzone_projectile_impact_check())
		goto return_true;

	if (self.warpzone_teleport_time == time) { // already got teleported this frame? no collision then please
		setorigin(self, self.warpzone_oldorigin);
		self.velocity = self.warpzone_oldvelocity;
		self.angles = self.warpzone_oldangles;
		goto return_true;
	}
	return warpzone_projectile_touch_handle_next();
:return_true
	projectile_update_after_teleport(self);
	return TRUE;
}

void(void) warpzone_init_find_target {
	entity e;
	if (self.killtarget != "") {
		self.aiment = find(world, targetname, self.killtarget);
		if (self.aiment == world)
		{
			error("Warp zone with nonexisting killtarget");
			return;
		}
	}
	// this way only one of the two ents needs to target
	if (self.target != "") {
		e = find(world, targetname, self.target);
		if (e) {
			self.enemy = e;
			self.enemy.enemy = self;
		}
	}
}

void(void) warpzone_position_init_find_target {
	if (self.target == "") {
		error("Warp zone position with no target");
		return;
	}
	self.enemy = find(world, targetname, self.target);
	if (self.enemy == world) {
		error("Warp zone position with nonexisting target");
		return;
	}
	if (self.enemy.aiment) {
		// already is positioned
		error("Warp zone position targeting already oriented warpzone");
		return;
	}
	self.enemy.aiment = self;
}

void(void) warpzone_init_update_transform {
	vector org, ang = '0 0 0', norm, point;
	float area;
	vector tri, a, b, c, p, q, n;
	float i_s, i_t, n_t;
	string tex;
	if (!self.enemy || self.enemy.enemy != self) {
		error("Invalid warp zone detected. Killed.");
		return;
	}
	org = self.origin;
	if (org == '0 0 0')
		org = 0.5 * (self.mins + self.maxs);

	norm = point = '0 0 0';
	area = 0;
	for (i_s = 0; ; ++i_s) {
		tex = getsurfacetexture(self, i_s);
		if not(tex)
			break; // this is beyond the last one

		if (tex == "texture/common/trigger")
			continue;

		n_t = getsurfacenumtriangles(self, i_s);
		for (i_t = 0; i_t < n_t; ++i_t) {
			tri = getsurfacetriangle(self, i_s, i_t);
			a = getsurfacepoint(self, i_s, tri_x);
			b = getsurfacepoint(self, i_s, tri_y);
			c = getsurfacepoint(self, i_s, tri_z);
			p = b - a;
			q = c - a;
			n = '1 0 0' * (q_y * p_z - q_z * p_y)
					+ '0 1 0' * (q_z * p_x - q_x * p_z)
					+ '0 0 1' * (q_x * p_y - q_y * p_x);
			area = area + vlen(n);
			norm = norm + n;
			point = point + vlen(n) * (a + b + c);
		}
	}
	if (area > 0) {
		norm = norm * (1 / area);
		point = point * (1 / (3 * area));
		if (vlen(norm) < 0.99) {
			print("trigger_warpzone near ", vtos(self.aiment.origin), " is nonplanar. BEWARE.\n");
			area = 0; // no autofixing in this case
		}
		norm = normalize(norm);
	}
	if (self.aiment) {
		org = self.aiment.origin;
		ang = self.aiment.angles;
		if (area > 0) {
			org = org - ((org - point) * norm) * norm; // project to plane
			makevectors(ang);
			if (norm * v_forward < 0) {
				print("Position target of trigger_warpzone near ", vtos(self.aiment.origin), " points into trigger_warpzone. BEWARE.\n");
				norm = -1 * norm;
			}
			ang = vectoangles(norm, v_up); // keep rotation, but turn exactly against plane
			ang_x = -ang_x;
			if (norm * v_forward < 0.99)
				print("trigger_warpzone near ", vtos(self.aiment.origin), " has been turned to match plane orientation (", vtos(self.aiment.angles), " -> ", vtos(ang), "\n");

			if (vlen(org - self.aiment.origin) > 0.5)
				print("trigger_warpzone near ", vtos(self.aiment.origin), " has been moved to match the plane (", vtos(self.aiment.origin), " -> ", vtos(org), ").\n");
		}
	} else if (area > 0) {
		org = point;
		if (self.movedir != '0 0 0')
			ang = vectoangles(norm, self.movedir);
		else
			ang = vectoangles(norm);

		ang_x = -ang_x;
	} else
		error("cannot infer origin/angles for this warpzone, please use a killtarget or a trigger_warpzone_position");

	self.warpzone_origin = org;
	self.warpzone_angles = ang;
}

void(void) warpzone_init_finalize_transform {
	warpzone_setup(self, self.warpzone_origin, self.warpzone_angles, self.enemy.warpzone_origin, self.enemy.warpzone_angles);
	self.touch = warpzone_touch;
	makevectors(self.warpzone_angles);
	vector v = self.warpzone_origin - v_forward * 32 - v_up * 32;
	entity w = waypoint_spawn(v, v, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_NORELINK);
	makevectors(self.enemy.warpzone_angles);
	v = self.enemy.warpzone_origin + v_forward * 32 - v_up * 32;
	entity dw = waypoint_spawn(v, v, WAYPOINTFLAG_GENERATED);
	w.wp00 = dw;
	w.wp00mincost = 0; // this is just for jump pads
	self.nearestwaypoint = w;
	self.nearestwaypointtimeout = time + 1000000000;
}

entity warpzone_position_first;
entity warpzone_first;
.entity warpzone_next;

void() warpzone_init_delayed {
	entity e = self;
	for (self = warpzone_first; self; self = self.warpzone_next)
		warpzone_init_find_target();

	for (self = warpzone_position_first; self; self = self.warpzone_next)
		warpzone_position_init_find_target();

	for (self = warpzone_first; self; self = self.warpzone_next)
		warpzone_init_update_transform();

	for (self = warpzone_first; self; self = self.warpzone_next)
		warpzone_init_finalize_transform();

	self = e;
}

void warpzone_trace_toss_trough_zone_real(entity e, entity forent, float toss_frametime, float toss_count, entity zone, warpzone_trace_callback_t cb) {
	float g, dt;
	vector vf, vr, vu, v0, o0;
	entity wz;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	o0 = e.origin;
	v0 = e.velocity;
	warpzone_trace_warpcount = 0;
	warpzone_trace_init_transform();
	// if starting in warpzone, first transform
	wz = warpzone_find(e.origin + e.mins, e.origin + e.maxs);
	if (wz) {
		if (zone && wz != zone) {
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.
			warpzone_trace_toss_time = 0;
			trace_endpos = o0;
			goto fail;
		}
		warpzone_trace_add_transform(wz);
		setorigin(e, warpzone_transform_origin(wz, e.origin));
		e.velocity = warpzone_transform_velocity(wz, e.velocity);
	}
	warpzone_make_all_solid();
	g = sv_gravity * e.gravity;
	warpzone_trace_toss_time = 0;
	for (;;) {
		trace_toss(e, forent, toss_frametime, toss_count);
		if (cb)
			cb(e.origin, trace_endpos, trace_endpos);

		e.origin = trace_endpos;
		e.velocity_z -= warpzone_trace_toss_time * g;
		dt = vlen(e.origin - o0) / vlen(e.velocity);
		warpzone_trace_toss_time += dt;
		if (trace_fraction >= 1)
			break;

		if (trace_ent.classname != "trigger_warpzone")
			break;

		if (trace_ent == wz) {
			//print("I transformed into the same zone again, wtf, aborting the trace\n");
			break;
		}
		wz = trace_ent;
		if (zone && wz != zone)
			break;

		warpzone_trace_add_transform(wz);
		// we hit a warpzone... so, let's perform the trace after the warp again
		e.origin = warpzone_transform_origin(wz, e.origin);
		e.velocity = warpzone_transform_velocity(wz, e.velocity);
		++warpzone_trace_warpcount;
	}
	warpzone_make_all_other();
:fail
	warpzone_trace_toss_velocity = e.velocity;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
	// restore old entity data (caller just uses trace_endpos, warpzone_trace_toss_velocity and the transform)
	e.velocity = v0;
	e.origin = o0;
}

void warpzone_trace_toss_real(entity e, entity forent, float toss_frametime, float toss_count) {
	warpzone_trace_toss_trough_zone_real(e, forent, toss_frametime, toss_count, world, NULL);
}

void warpzone_trace_toss_trough_zone_stub(entity e, entity forent, float toss_frametime, float toss_count, entity zone, warpzone_trace_callback_t cb) {
	trace_toss(e, forent, toss_frametime, toss_count);
	if (cb)
		cb(e.origin, trace_endpos, trace_endpos);

	warpzone_trace_toss_velocity = e.velocity;
	warpzone_trace_toss_velocity_z -= sv_gravity * (vlen(trace_endpos - self.origin) / vlen(self.velocity));
}

void warpzone_trace_toss_stub(entity e, entity forent, float toss_frametime, float toss_count) {
	trace_toss(e, forent, toss_frametime, toss_count);
	warpzone_trace_toss_velocity = e.velocity;
	warpzone_trace_toss_velocity_z -= sv_gravity * (vlen(trace_endpos - self.origin) / vlen(self.velocity));
}

var void(entity targ, entity attacker, float deathtype) warpzone_damage_mods_set_next;
void(entity targ, entity attacker, float deathtype) warpzone_damage_mods_set { //prevent damage modificator chaining with warpzone shadow
	if (targ.classname == "wzshadow") {
		plugin_chain_damage_mod = plugin_chain_damage_mod_force = plugin_chain_damage_mod_mirror = plugin_chain_damage_mod_force_mirror = 1;
		return;
	}
	warpzone_damage_mods_set_next(targ, attacker, deathtype);
}

.entity WarpZone_refsys;
void() warpzone_refsys_gc {
	// garbage collect unused reference systems
	self.nextthink = time + 1;
	if (self.owner.WarpZone_refsys != self)
		remove(self);
}

void(entity me, entity wz) warpzone_refsys_add {
	if (me.WarpZone_refsys.owner != me) {
		me.WarpZone_refsys = spawn();
		me.WarpZone_refsys.classname = "warpzone_refsys";
		me.WarpZone_refsys.owner = me;
		me.WarpZone_refsys.think = warpzone_refsys_gc;
		me.WarpZone_refsys.nextthink = time + 1;
		warpzone_accumulator_clear(me.WarpZone_refsys);
	}
	if (wz)
		warpzone_accumulator_add(me.WarpZone_refsys, wz);
}

vector(entity from, entity to, vector org) warpzone_refsys_transform_origin_real {
	if (from.WarpZone_refsys)
		org = warpzone_untransform_origin(from.WarpZone_refsys, org);

	if (to.WarpZone_refsys)
		org = warpzone_transform_origin(to.WarpZone_refsys, org);

	return org;
}

vector(entity from, entity to, vector vel) warpzone_refsys_transform_velocity_real {
	if (from.WarpZone_refsys)
		vel = warpzone_untransform_velocity(from.WarpZone_refsys, vel);

	if (to.WarpZone_refsys)
		vel = warpzone_transform_velocity(to.WarpZone_refsys, vel);

	return vel;
}

vector(entity from, entity to, vector ang) warpzone_refsys_transform_angles_real {
	if (from.WarpZone_refsys)
		ang = warpzone_untransform_angles(from.WarpZone_refsys, ang);

	if(to.WarpZone_refsys)
		ang = warpzone_transform_angles(to.WarpZone_refsys, ang);

	return ang;
}

void(entity e, entity e_orig) warpzone_refsys_copy_stub {}

void(entity e, entity e_orig) warpzone_refsys_copy_real {
	if (e_orig.WarpZone_refsys) {
		e.WarpZone_refsys = spawn();
		e.WarpZone_refsys.classname = "warpzone_refsys";
		e.WarpZone_refsys.owner = e;
		e.WarpZone_refsys.think = warpzone_refsys_gc;
		e.WarpZone_refsys.nextthink = time + 1;
		e.WarpZone_refsys.warpzone_shift = e_orig.WarpZone_refsys.warpzone_shift;
		e.WarpZone_refsys.warpzone_transform = e_orig.WarpZone_refsys.warpzone_transform;
	} else
		e.WarpZone_refsys = NULL;
}

entity(entity me) warpzone_refsys_spawn_same_refsys_real {
	entity e;
	e = spawn();
	warpzone_refsys_copy_real(e, me);
	return e;
}

vector(entity from, entity to, vector org) warpzone_refsys_transform_origin_stub {
	return org;
}

vector(entity from, entity to, vector vel) warpzone_refsys_transform_velocity_stub {
	return vel;
}

entity(entity e) warpzone_refsys_spawn_same_refsys_stub {
	return spawn();
}

vector(entity from, entity to, vector ang) warpzone_refsys_transform_angles_stub {
	return ang;
}

void() warpzone_enable_hook {
	warpzone_refsys_transform_angles = warpzone_refsys_transform_angles_real;
	warpzone_refsys_spawn_same_refsys = warpzone_refsys_spawn_same_refsys_real;
	warpzone_refsys_transform_origin = warpzone_refsys_transform_origin_real;
	warpzone_refsys_transform_velocity = warpzone_refsys_transform_velocity_real;
	warpzone_refsys_copy = warpzone_refsys_copy_real;
	warpzone_trace_toss = warpzone_trace_toss_real;
	warpzone_trace_toss_trough_zone = warpzone_trace_toss_trough_zone_real;
	warpzone_damage_mods_set_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = warpzone_damage_mods_set;
	warpzone_projectile_touch_handle_next = plugin_chain_projectile_touch_handle;
	plugin_chain_projectile_touch_handle = warpzone_projectile_touch_handle;
}

void() warpzone_init_hook {
	warpzone_refsys_transform_angles = warpzone_refsys_transform_angles_stub;
	warpzone_refsys_spawn_same_refsys = warpzone_refsys_spawn_same_refsys_stub;
	warpzone_refsys_transform_origin = warpzone_refsys_transform_origin_stub;
	warpzone_refsys_transform_velocity = warpzone_refsys_transform_velocity_stub;
	warpzone_refsys_copy = warpzone_refsys_copy_stub;
	warpzone_trace_toss = warpzone_trace_toss_stub;
	warpzone_trace_toss_trough_zone = warpzone_trace_toss_trough_zone_stub;
	warpzone_sound_transition = 0;
}

void() warpzone_shutdown_hook {
}

void(void) warpzone_dlc_load {
	float i;
	string tex;
	for (i = 0; ; ++i) {
		tex = getsurfacetexture(self, i);
		if not(tex)
			break;

		if (tex == "texture/common/warpzone" || tex == "textures/common/camera") {
			dlc_require(DLC_WARPZONE);
			break;
		}
	}
}

void(void) warpzone_spawn {
	// warp zone entities must have:
	// "killtarget" pointing to a target_position with a direction arrow
	//              that points AWAY from the warp zone, and that is inside
	//              the warp zone trigger
	// "target"     pointing to an identical warp zone at another place in
	//              the map, with another killtarget to designate its
	//              orientation
	if (!self.scale)
		self.scale = self.modelscale;

	if (!self.scale)
		self.scale = 1;

	string m;
	m = self.model;
	if (self.model != "") {
		precache_model(self.model);
		setmodel(self, self.model);
	}
	setorigin(self, self.origin);
	if (self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);

	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.model = "";
	if (m != "") {
		precache_model(m);
		setmodel(self, m); // no precision needed
	}
	setorigin(self, self.origin);
	if (self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);

	self.SendEntity = warpzone_send;
	self.SendFlags = 0xFFFFFF;
	self.effects |= EFFECT_NODEPTHTEST;
	self.warpzone_next = warpzone_first;
	if not(warpzone_first) {
		warpzone_enable();
		entity_initialize(self, warpzone_init_delayed, INITPRIO_FINDTARGET);
	}
	warpzone_first = self;
	warpzone_chain_add(self);
	warpzone_dlc_load();
}

void(void) warpzone_position_spawn {
	// "target", "angles", "origin"
	self.warpzone_next = warpzone_position_first;
	warpzone_position_first = self;
}
