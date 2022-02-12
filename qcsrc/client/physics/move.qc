.float move_suspendedinair;
.float move_didgravity;

#if 0
void() physics_move_check_velocity { // SV_CheckVelocity
}

float() physics_move_check_water { // SV_CheckWater
	return FALSE;
}

void() physics_move_check_water_transition { // SV_CheckWaterTransition
}
#endif

void(entity oth) physics_move_impact { // SV_Impact
	entity oldother, oldself;
	oldself = self;
	oldother = other;
	if (self.move_touch) {
		other = oth;
		self.move_touch();
		other = oldother;
	}
	if (oth.move_touch) {
		other = self;
		self = oth;
		self.move_touch();
		self = oldself;
		other = oldother;
	}
}

#if 0
void() physics_move_link_edict_touch_area_grid { // SV_LinkEdict_TouchAreaGrid
	entity e, oldself, oldother;
	oldself = self;
	oldother = other;
	for (e = findradius(0.5 * (self.absmin + self.absmax), 0.5 * vlen(self.absmax - self.absmin)); e; e = e.chain) {
		if (e.move_touch)
		if (math_boxes_overlap(e.absmin, e.absmax, oldself.absmin, oldself.absmax)) {
			self = e;
			other = oldself;
			trace_allsolid = FALSE;
			trace_startsolid = FALSE;
			trace_fraction = 1;
			trace_inwater = FALSE;
			trace_inopen = TRUE;
			trace_endpos = e.origin;
			trace_plane_normal = '0 0 1';
			trace_plane_dist = 0;
			trace_ent = oldself;
			e.move_touch();
		}
	}
	other = oldother;
	self = oldself;
}

void(float touch_triggers) physics_move_link_edict { // SV_LinkEdict
	vector mi, ma;
	if (self.solid == SOLID_BSP) {
		// TODO set the absolute bbox
		mi = self.mins;
		ma = self.maxs;
	} else {
		mi = self.mins;
		ma = self.maxs;
	}
	mi = mi + self.origin;
	ma = ma + self.origin;
	if (self.move_flags & FL_ITEM) {
		mi_x -= 15;
		mi_y -= 15;
		mi_z -= 1;
		ma_x += 15;
		ma_y += 15;
		ma_z += 1;
	} else {
		mi_x -= 1;
		mi_y -= 1;
		mi_z -= 1;
		ma_x += 1;
		ma_y += 1;
		ma_z += 1;
	}
	self.absmin = mi;
	self.absmax = ma;
	if (touch_triggers)
		physics_move_link_edict_touch_area_grid();
}
#endif

float(vector ofs) physics_move_test_entity_position { // SV_TestEntityPosition
	vector org;
	float cont;
	org = self.move_origin + ofs;
	cont = self.dphitcontentsmask;
	self.dphitcontentsmask = DPCONTENTS_SOLID;
	tracebox(self.move_origin, self.mins, self.maxs, self.move_origin, TRACE_MOVE_NOMONSTERS, self);
	self.dphitcontentsmask = cont;
	if (trace_startsolid)
		return TRUE;

	if (vlen(trace_endpos - self.move_origin) > 0.0001)
		self.move_origin = trace_endpos;

	return FALSE;
}

float() physics_move_unstick_entity { // SV_UnstickEntity
	if not(physics_move_test_entity_position('0 0 0'))
		return TRUE;

	if not(physics_move_test_entity_position('-1 0 0')) goto success;
	if not(physics_move_test_entity_position('1 0 0')) goto success;
	if not(physics_move_test_entity_position('0 -1 0')) goto success;
	if not(physics_move_test_entity_position('0 1 0')) goto success;
	if not(physics_move_test_entity_position('-1 -1 0')) goto success;
	if not(physics_move_test_entity_position('1 -1 0')) goto success;
	if not(physics_move_test_entity_position('-1 1 0')) goto success;
	if not(physics_move_test_entity_position('1 1 0')) goto success;
	float i;
	for (i = 1; i <= 17; ++i) {
		if not(physics_move_test_entity_position('0 0 -1' * i)) goto success;
		if not(physics_move_test_entity_position('0 0 1' * i)) goto success;
	}
	return FALSE;
:success
	//physics_move_link_edict(TRUE);
	return TRUE;
}

vector(vector vel, vector norm, float f) physics_move_clip_velocity { // SV_ClipVelocity
	vel = vel - ((vel * norm) * norm) * f;
	if (vel_x > -0.1 && vel_x < 0.1) vel_x = 0;
	if (vel_y > -0.1 && vel_y < 0.1) vel_y = 0;
	if (vel_z > -0.1 && vel_z < 0.1) vel_z = 0;
	return vel;
}

void(vector push) physics_move_push_entity_trace {
	vector end;
	float type;
	end = self.move_origin + push;
	if (self.move_nomonsters)
		type = max(0, self.move_nomonsters);
	else if (self.move_movetype == MOVETYPE_FLYMISSILE)
		type = TRACE_MOVE_MISSILE;
	else if (self.solid == SOLID_TRIGGER || self.solid == SOLID_NOT)
		type = TRACE_MOVE_NOMONSTERS;
	else
		type = TRACE_MOVE_NORMAL;

	tracebox(self.move_origin, self.mins, self.maxs, end, type, self);
}

float(vector push, float failonstartsolid) physics_move_push_entity { // SV_PushEntity
	physics_move_push_entity_trace(push);
	if (trace_startsolid && failonstartsolid)
		return trace_fraction;

	self.move_origin = trace_endpos;
	if (trace_fraction < 1)
		if (self.solid >= SOLID_TRIGGER && (!(self.move_flags & FL_ONGROUND) || (self.move_groundentity != trace_ent)))
			physics_move_impact(trace_ent);

	return trace_fraction;
}

#define MAX_CLIP_PLANES 5
void(float dt) physics_move_toss { // SV_Physics_Toss
	if (self.move_flags & FL_ONGROUND) {
		if (self.move_velocity_z >= 1/32)
			self.move_flags &= ~FL_ONGROUND;
		else if not(self.move_groundentity)
			return;
		else if (self.move_suspendedinair && wasfreed(self.move_groundentity)) {
			self.move_groundentity = world;
			return;
		}
	}
	self.move_suspendedinair = FALSE;
	//physics_move_check_velocity();
	if (self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS) {
		self.move_didgravity = TRUE;
		if (self.gravity)
			self.move_velocity_z = self.move_velocity_z - dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
		else
			self.move_velocity_z = self.move_velocity_z - dt * getstatf(STAT_MOVEVARS_GRAVITY);
	}
	self.move_angles = self.move_angles + self.move_avelocity * dt;
	float movetime, bump;
	movetime = dt;
	for (bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump) {
		vector move;
		move = self.move_velocity * movetime;
		physics_move_push_entity(move, TRUE);
		if (wasfreed(self))
			return;

		if (trace_startsolid) {
			physics_move_unstick_entity();
			physics_move_push_entity(move, FALSE);
			if (wasfreed(self))
				return;
		}
		if (trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);
		if (self.move_movetype == MOVETYPE_BOUNCEMISSILE) {
			self.move_velocity = physics_move_clip_velocity(self.move_velocity, trace_plane_normal, 2.0);
			self.move_flags &= ~FL_ONGROUND;
		} else if (self.move_movetype == MOVETYPE_BOUNCE) {
			float d, bouncefac, bouncestop;
			bouncefac = self.move_bounce_factor;
			if not(bouncefac) bouncefac = 0.5;
			bouncestop = self.move_bounce_stopspeed;
			if not(bouncestop) bouncestop = 60 / 800;
			if (self.gravity)
				bouncestop *= self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
			else
				bouncestop *= getstatf(STAT_MOVEVARS_GRAVITY);

			self.move_velocity = physics_move_clip_velocity(self.move_velocity, trace_plane_normal, 1 + bouncefac);
			d = trace_plane_normal * self.move_velocity;
			if (trace_plane_normal_z > 0.7 && d < bouncestop && d > -bouncestop) {
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			} else
				self.move_flags &= ~FL_ONGROUND;
		} else {
			self.move_velocity = physics_move_clip_velocity(self.move_velocity, trace_plane_normal, 1.0);
			if (trace_plane_normal_z > 0.7) {
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				if (trace_ent.solid == SOLID_BSP)
					self.move_suspendedinair = TRUE;

				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			} else
				self.move_flags &= ~FL_ONGROUND;
		}
		// DP revision 8905 (just, WHY...)
		if (self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			break;

		// DP revision 8918 (WHY...)
		if (self.move_flags & FL_ONGROUND)
			break;
	}
	//physics_move_check_water_transition();
}

void(float movedt) physics_move_frame {
	self.move_didgravity = FALSE;
	switch (self.move_movetype) {
	case MOVETYPE_TOSS:
	case MOVETYPE_BOUNCE:
	case MOVETYPE_BOUNCEMISSILE:
	case MOVETYPE_FLYMISSILE:
	case MOVETYPE_FLY:
		physics_move_toss(movedt);
		break;
	case MOVETYPE_PUSH:
		error("SV_Physics_Pusher not implemented");
		break;
	case MOVETYPE_NONE:
		break;
	case MOVETYPE_FOLLOW:
		error("SV_Physics_Follow not implemented");
		break;
	case MOVETYPE_NOCLIP:
		//physics_move_check_water();
		self.move_origin = self.move_origin + server_ticrate * self.move_velocity;
		self.move_angles = self.move_angles + server_ticrate * self.move_avelocity;
		//physics_move_link_edict(FALSE);
		break;
	case MOVETYPE_STEP:
		error("SV_Physics_Step not implemented");
		break;
	case MOVETYPE_WALK:
		error("SV_Physics_Walk not implemented");
		break;
	}
}

void() physics_move_no_match_server { // optimized
	float movedt;
	movedt = time - self.move_time;
	self.move_time = time;
	//self.move_didgravity = ((self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS) && !(self.move_flags & FL_ONGROUND));
	// we use the field as set by the last run of this
	physics_move_frame(movedt);
	if (wasfreed(self))
		return;

	self.avelocity = self.move_avelocity;
	self.velocity = self.move_velocity;
	self.angles = self.move_angles;
	setorigin(self, self.move_origin);
}

void() physics_move_match_server { // SV_Physics_Entity
	float n, i, dt, movedt;
	if (server_ticrate <= 0) {
		physics_move_no_match_server();
		return;
	}
	dt = time - self.move_time;
	movedt = server_ticrate;
	n = max(0, floor(dt / server_ticrate));
	dt -= n * server_ticrate;
	self.move_time += n * server_ticrate;
	//self.move_didgravity = ((self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS) && !(self.move_flags & FL_ONGROUND));
	// we use the field as set by the last run of this
	for (i = 0; i < n; ++i) {
		physics_move_frame(movedt);
		if (wasfreed(self))
			return;
	}
	self.avelocity = self.move_avelocity;
	if (dt > 0 && self.move_movetype != MOVETYPE_NONE && !(self.move_flags & FL_ONGROUND)) {
		// now continue the move from move_time to time
		self.velocity = self.move_velocity;
		if (self.move_didgravity) {
			if (self.gravity)
				self.velocity_z = self.velocity_z - dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
			else
				self.velocity_z = self.velocity_z - dt * getstatf(STAT_MOVEVARS_GRAVITY);
		}
		self.angles = self.move_angles + dt * self.avelocity;
		if (self.movetype != MOVETYPE_NOCLIP) {
			physics_move_push_entity_trace(dt * self.velocity);
			if (!trace_startsolid)
				setorigin(self, trace_endpos);
		} else
			setorigin(self, self.move_origin + dt * self.velocity);
	} else {
		self.velocity = self.move_velocity;
		self.angles = self.move_angles;
		setorigin(self, self.move_origin);
	}
}
