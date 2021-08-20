.vector warpzone_oldorigin, warpzone_oldvelocity, warpzone_oldangles;
.float warpzone_teleport_time;
.float warpzone_teleport_finishtime;
.entity warpzone_teleport_zone;
void(void) warpzone_init_delayed;
float(entity e) warpzone_move_out_of_solid;

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
	vector from;
	makevectors(to_angles);
	from = player.origin;
	player_teleport(player, to, 0);
	player.angles = to_angles;
	player.v_angle = to_angles;
	player.velocity = to_velocity;
	if (player.classname == "player")
		player.flags &= ~FL_ONGROUND;

	projectile_update_after_teleport(player);
}

float(entity to, float sf) warpzone_teleported_send {
	WriteByte(MSG_ENTITY, NET_CSQC_WARPZONE_TELEPORTED);
	WriteCoord(MSG_ENTITY, self.angles_x);
	WriteCoord(MSG_ENTITY, self.angles_y);
	WriteCoord(MSG_ENTITY, self.angles_z);
	return TRUE;
}

float(void) warpzone_teleported_customize {
	if (other == self.owner)
		return TRUE;

	if (other.enemy == self.owner && other.classname == "spectator")
		return TRUE;

	return FALSE;
}

float(entity wz, entity e, float f0, float f1) warpzone_teleport {
	vector o0, a0, v0, o1, a1, v1, o10;
	o0 = e.origin + e.view_ofs;
	v0 = e.velocity;
	a0 = e.angles;
	o10 = o1 = WarpZone_TransformOrigin(wz, o0);
	v1 = WarpZone_TransformVelocity(wz, v0);
	if not(clienttype(e) == CLIENTTYPE_NOTACLIENT)
		a1 = WarpZone_TransformVAngles(wz, e.v_angle);
	else
		a1 = WarpZone_TransformAngles(wz, a0);

	if (f0 != 0 || f1 != 0) {
		// retry last move but behind the warpzone!
		// we must first go back as far as we can, then forward again, to not cause double touch events!
		trace_box(o1 - e.view_ofs + v1 * frametime * f1, e.mins, e.maxs, o1 - e.view_ofs + v1 * frametime * f0, TRACE_MOVE_WORLDONLY, e); {
			entity own;
			own = e.owner;
			e.owner = world;
			trace_box(trace_endpos, e.mins, e.maxs, o1 - e.view_ofs + v1 * frametime * f1, TRACE_MOVE_NORMAL, e); // this should get us through the warpzone
			e.owner = own;
		}
		o1 = trace_endpos + e.view_ofs;
		float d, dv, md;
		md = max(vlen(e.mins), vlen(e.maxs));
		d = WarpZone_TargetPlaneDist(wz, o1);
		dv = WarpZone_TargetPlaneDist(wz, v1);
		if (d < 0)
			o1 = o1 - v1 * (d / dv);
	}
	// put him out of solid
	if (e.movetype != MOVETYPE_NOCLIP) {
		trace_box(o1 - e.view_ofs, e.mins, e.maxs, o1 - e.view_ofs, TRACE_MOVE_NOMONSTERS, e);
		if (trace_startsolid) {
			setorigin(e, o1 - e.view_ofs);
			if (warpzone_move_out_of_solid(e)) {
				o1 = e.origin + e.view_ofs;
				setorigin(e, o0 - e.view_ofs);
			} else {
				print("would have to put entity in solid, won't do that\n");
				setorigin(e, o0 - e.view_ofs);
				return 0;
			}
		}
	}
	// do the teleport
	WarpZone_RefSys_Add(e, wz);
	warzpone_teleport_player(wz, e, o1 - e.view_ofs, a1, v1);
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
		e.fixangle = FALSE;
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

	if (WarpZone_Find(o.origin + o.mins, o.origin + o.maxs) != self.enemy) {
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
	self.angles = WarpZone_TransformAngles(self.enemy, a);
	self.skin = b.skin;
	self.solid = o.solid;
	setorigin(self, WarpZone_TransformOrigin(self.enemy, o.origin));
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) warpzone_shadow_event_damage {
	if (damage_radius_running) //No need proxy splash damage
		return;

	damage(self.owner, inflictor, attacker, _damage, deathtype, WarpZone_UnTransformOrigin(self.enemy, hitloc), WarpZone_UnTransformVelocity(self.enemy, force));
	self.velocity = '0 0 0';
}

void(void) warpzone_touch {
	entity oldself;
	if (other.classname == "trigger_warpzone")
		return;

	if (time <= other.warpzone_teleport_finishtime) // already teleported this frame
		return;

	if (!WarpZone_BoxTouchesBrush(other.absmin, other.absmax, self, other))
		return;

	if (other.movetype == MOVETYPE_FOLLOW || other.tag_entity)
		return;

	if (WarpZone_PlaneDist(self, other.origin + other.view_ofs) >= 0) {// wrong side of the trigger_warpzone (don't teleport yet)
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

	float f;
	// number of frames we need to go back:
	//   dist = 16*sqrt(2) qu
	//   dist ~ 24 qu
	//   24 qu = v*t
	//   24 qu = v*frametime*n
	//       n = 24 qu/(v*frametime)
	// for clients go only one frame though, may be too irritating otherwise
	// but max 0.25 sec = 0.25/frametime frames
	//       24/(0.25/frametime)
	//       96*frametime
	float d;
	d = 24 + max(vlen(other.mins), vlen(other.maxs));
	if (clienttype(other) == CLIENTTYPE_NOTACLIENT)
		f = -d / bound(frametime * d * 1, frametime * vlen(other.velocity), d);
	else
		f = -1;

	if (other.classname == "observer") {
		warpzone_teleport(self, other, f, 0);
		return;
	}
	if (warpzone_teleport(self, other, f, 0)) {
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
	WriteByte(MSG_ENTITY, NET_CSQC_WARPZONE);
	// we need THESE to render the warpzone (and cull properly)...
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);
	WriteByte(MSG_ENTITY, bound(1, self.scale * 16, 255));
	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, self.warpzone_origin_x);
	WriteCoord(MSG_ENTITY, self.warpzone_origin_y);
	WriteCoord(MSG_ENTITY, self.warpzone_origin_z);
	WriteCoord(MSG_ENTITY, self.warpzone_angles_x);
	WriteCoord(MSG_ENTITY, self.warpzone_angles_y);
	WriteCoord(MSG_ENTITY, self.warpzone_angles_z);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin_x);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin_y);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin_z);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles_x);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles_y);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles_z);
	return TRUE;
}

float(void) warpzone_projectile_impact_check {
	// if self hit a warpzone, abort
	vector o0, v0, a0;
	float mpd, pd, dpd;
	entity wz;
	warpzone_save_trace_globals();
	wz = WarpZone_Find(self.origin + self.mins, self.origin + self.maxs);
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
	WarpZone_TraceBox_ThroughZone(self.warpzone_oldorigin, self.mins, self.maxs, self.warpzone_oldorigin + self.warpzone_oldvelocity * frametime, TRACE_MOVE_NORMAL, self, wz, NULL); // this will get us through the warpzone
	setorigin(self, trace_endpos);
	self.angles = WarpZone_TransformAngles(WarpZone_trace_transform, self.angles);
	self.velocity = WarpZone_TransformVelocity(WarpZone_trace_transform, self.velocity);
	if (trace_fraction < 1) //We hit something right behind warp
		return FALSE;
	
	// in case we are in our warp zone post-teleport, shift the projectile forward a bit
	mpd = max(vlen(self.mins), vlen(self.maxs));
	pd = WarpZone_TargetPlaneDist(wz, self.origin);
	if (pd < mpd) {
		dpd = normalize(self.velocity) * self.warpzone_targetforward;
		setorigin(self, self.origin + normalize(self.velocity) * ((mpd - pd) / dpd));
		if (!warpzone_move_out_of_solid(self)) {
			setorigin(self, o0);
			self.angles = a0;
			self.velocity = v0;
			return FALSE;
		}
	}
	WarpZone_RefSys_Add(self, wz);
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
		ang = vectoangles(norm);
		ang_x = -ang_x;
	} else
		error("cannot infer origin/angles for this warpzone, please use a killtarget or a trigger_warpzone_position");

	self.warpzone_origin = org;
	self.warpzone_angles = ang;
}

void(void) warpzone_init_finalize_transform {
	WarpZone_SetUp(self, self.warpzone_origin, self.warpzone_angles, self.enemy.warpzone_origin, self.enemy.warpzone_angles);
	self.touch = warpzone_touch;
	entity w = waypoint_spawn(self.warpzone_origin, self.warpzone_origin, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_NORELINK);
	entity dw = waypoint_spawn(self.enemy.warpzone_origin, self.enemy.warpzone_origin, WAYPOINTFLAG_GENERATED);
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

void warpzone_trace_toss_trough_zone_real(entity e, entity forent, float toss_frametime, float toss_count, entity zone, WarpZone_trace_callback_t cb) {
	float g, dt;
	vector vf, vr, vu, v0, o0;
	entity wz;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	o0 = e.origin;
	v0 = e.velocity;
	WarpZone_trace_warpcount = 0;
	WarpZone_Trace_InitTransform();
	// if starting in warpzone, first transform
	wz = WarpZone_Find(e.origin + e.mins, e.origin + e.maxs);
	if (wz) {
		if (zone && wz != zone) {
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.
			warpzone_trace_toss_time = 0;
			trace_endpos = o0;
			goto fail;
		}
		WarpZone_Trace_AddTransform(wz);
		setorigin(e, WarpZone_TransformOrigin(wz, e.origin));
		e.velocity = WarpZone_TransformVelocity(wz, e.velocity);
	}
	WarpZone_MakeAllSolid();
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

		WarpZone_Trace_AddTransform(wz);
		// we hit a warpzone... so, let's perform the trace after the warp again
		e.origin = WarpZone_TransformOrigin(wz, e.origin);
		e.velocity = WarpZone_TransformVelocity(wz, e.velocity);
		++WarpZone_trace_warpcount;
	}
	WarpZone_MakeAllOther();
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

void warpzone_trace_toss_trough_zone_stub(entity e, entity forent, float toss_frametime, float toss_count, entity zone, WarpZone_trace_callback_t cb) {
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
		gamehook_chain_damage_mod = gamehook_chain_damage_mod_force = gamehook_chain_damage_mod_mirror = gamehook_chain_damage_mod_force_mirror = 1;
		return;
	}
	warpzone_damage_mods_set_next(targ, attacker, deathtype);
}

void WarpZone_EnableHook() {
	warpzone_trace_toss = warpzone_trace_toss_real;
	warpzone_trace_toss_trough_zone = warpzone_trace_toss_trough_zone_real;
	warpzone_damage_mods_set_next = gamehook_chain_damage_mods_set;
	gamehook_chain_damage_mods_set = warpzone_damage_mods_set;
	warpzone_projectile_touch_handle_next = gamehook_chain_projectile_touch_handle;
	gamehook_chain_projectile_touch_handle = warpzone_projectile_touch_handle;
}

void WarpZone_InitHook() {
	warpzone_trace_toss = warpzone_trace_toss_stub;
	warpzone_trace_toss_trough_zone = warpzone_trace_toss_trough_zone_stub;
	warpzone_sound_transition = 0;
}

void WarpZone_ShutdownHook() {
}

void(entity e, vector by) warpzone_move_out_of_solid_expand {
	float eps = 0.0625;
	trace_box(e.origin, e.mins - '1 1 1' * eps, e.maxs + '1 1 1' * eps, e.origin + by, TRACE_MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return;

	if (trace_fraction < 1) {
		// hit something
		// adjust origin in the other direction...
		setorigin(e,e.origin - by * (1 - trace_fraction));
	}
}

float(entity e) warpzone_move_out_of_solid {
	vector o, m0, m1;
	o = e.origin;
	trace_line(o, o, TRACE_MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return FALSE;

	trace_box(o, e.mins, e.maxs, o, TRACE_MOVE_WORLDONLY, e);
	if (!trace_startsolid)
		return TRUE;

	m0 = e.mins;
	m1 = e.maxs;
	e.mins = '0 0 0';
	e.maxs = '0 0 0';
	warpzone_move_out_of_solid_expand(e, '1 0 0' * m0_x);
	e.mins_x = m0_x;
	warpzone_move_out_of_solid_expand(e, '1 0 0' * m1_x);
	e.maxs_x = m1_x;
	warpzone_move_out_of_solid_expand(e, '0 1 0' * m0_y);
	e.mins_y = m0_y;
	warpzone_move_out_of_solid_expand(e, '0 1 0' * m1_y);
	e.maxs_y = m1_y;
	warpzone_move_out_of_solid_expand(e, '0 0 1' * m0_z);
	e.mins_z = m0_z;
	warpzone_move_out_of_solid_expand(e, '0 0 1' * m1_z);
	e.maxs_z = m1_z;
	setorigin(e, e.origin);
	trace_box(e.origin, e.mins, e.maxs, e.origin, TRACE_MOVE_WORLDONLY, e);
	if (trace_startsolid) {
		setorigin(e, o);
		return FALSE;
	}
	return TRUE;
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
		WarpZone_Enable();
		entity e = spawn();
		e.think = warpzone_init_delayed;
		e.nextthink = time;
	}
	warpzone_first = self;
	WarpZone_ChainAdd(self);
}

void(void) warpzone_position_spawn {
	// "target", "angles", "origin"
	self.warpzone_next = warpzone_position_first;
	warpzone_position_first = self;
}
