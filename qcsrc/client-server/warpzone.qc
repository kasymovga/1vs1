void(vector org, vector min, vector max, vector end, float nomonsters, entity forent) warpzone_trace_box_real;
void(vector org, vector min, vector max, vector end, float nomonsters, entity forent, entity zone, warpzone_trace_callback_t cb) warpzone_trace_box_trough_zone_real;
void(vector org, vector end, float nomonsters, entity forent) warpzone_trace_line_real;
void(vector org, vector end, float nomonsters, entity forent, entity zone, warpzone_trace_callback_t cb) warpzone_trace_line_trough_zone_real;
entity(vector org, float radius, float needlineofsight) warpzone_find_radius_real;
vector(entity wz, vector v) warpzone_transform_origin_real;
vector(entity wz, vector v) warpzone_transform_velocity_real;
vector(entity wz, vector v) warpzone_untransform_origin_real;
vector(vector from, vector to, float trace_check) warpzone_find_nearest_origin_real;
void(vector org, vector org_visual, vector end, warpzone_trace_callback_t cb) warpzone_draw_effect_triangle_real;
vector(vector mi, vector ma, vector org) warpzone_nearest_point_on_box;

void(entity acc) warpzone_accumulator_clear {
	acc.warpzone_transform = '0 0 0';
	acc.warpzone_shift = '0 0 0';
}

void(entity acc, vector t, vector s) warpzone_accumulator_add_transform {
	vector tr, st;
	tr = AnglesTransform_Multiply(t, acc.warpzone_transform);
	st = AnglesTransform_Multiply_GetPostShift(t, s, acc.warpzone_transform, acc.warpzone_shift);
	acc.warpzone_transform = tr;
	acc.warpzone_shift = st;
}

void(entity acc, entity wz) warpzone_accumulator_add {
	vector t, st;
	t = AnglesTransform_Multiply(wz.warpzone_transform, acc.warpzone_transform);
	st = AnglesTransform_Multiply_GetPostShift(wz.warpzone_transform, wz.warpzone_shift, acc.warpzone_transform, acc.warpzone_shift);
	acc.warpzone_transform = t;
	acc.warpzone_shift = st;
}

var float autocvar_cl_warpzone_usetrace = 1;
vector(vector org, vector ang) warpzone_camera_transform {
	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	org = warpzone_transform_origin(self, org);
	vf = warpzone_transform_velocity(self, vf);
	vr = warpzone_transform_velocity(self, vr);
	vu = warpzone_transform_velocity(self, vu);
	if (autocvar_cl_warpzone_usetrace)
		trace_line(self.warpzone_targetorigin, org, TRACE_MOVE_NOMONSTERS, world);
	else
		trace_endpos = self.warpzone_targetorigin;

	v_forward = vf;
	v_right = vr;
	v_up = vu;
	return org;
}

void(entity e, vector my_org, vector my_ang, vector other_org, vector other_ang) warpzone_setup {
	e.warpzone_transform = AnglesTransform_RightDivide(other_ang, AnglesTransform_TurnDirectionFR(my_ang));
	e.warpzone_shift = AnglesTransform_PrePostShift_GetPostShift(my_org, e.warpzone_transform, other_org);
	e.warpzone_origin = my_org;
	e.warpzone_targetorigin = other_org;
	e.warpzone_angles = my_ang;
	e.warpzone_targetangles = other_ang;
	makevectors(my_ang); e.warpzone_forward = v_forward;
	makevectors(other_ang); e.warpzone_targetforward = v_forward;
	e.camera_transform = warpzone_camera_transform;
}

.entity enemy;

vector warpzone_box_touches_brush_mins;
vector warpzone_box_touches_brush_maxs;
entity warpzone_box_touches_brush_ent;
entity warpzone_box_touches_brush_ignore;
float() warpzone_box_touches_brush_recurse {
	float s;
	entity se;
	float f;
	trace_box('0 0 0', warpzone_box_touches_brush_mins, warpzone_box_touches_brush_maxs, '0 0 0', TRACE_MOVE_NOMONSTERS, warpzone_box_touches_brush_ignore);
	if not(trace_ent)
		return 0;

	if (trace_ent == warpzone_box_touches_brush_ent)
		return 1;

	se = trace_ent;
	s = se.solid;
	se.solid = SOLID_NOT;
	f = warpzone_box_touches_brush_recurse();
	se.solid = s;
	return f;
}

float(vector mi, vector ma, entity e, entity ig) warpzone_box_touches_brush {
	float f, s;
	if not(e.modelindex)
		return 1;

	s = e.solid;
	e.solid = SOLID_BSP;
	warpzone_box_touches_brush_mins = mi;
	warpzone_box_touches_brush_maxs = ma;
	warpzone_box_touches_brush_ent = e;
	warpzone_box_touches_brush_ignore = ig;
	f = warpzone_box_touches_brush_recurse();
	e.solid = s;
	return f;
}

entity(vector mi, vector ma) warpzone_find {
	// if we are near any warpzone planes - MOVE AWAY (work around nearclip)
	entity e;
	for (e = warpzone_chain_begin; e; e  = e.warpzone_chain)
		if (warpzone_box_touches_brush(mi, ma, e, world))
			return e;

	return world;
}

void() warpzone_make_all_solid {
	entity e;
	for (e = warpzone_chain_begin; e; e  = e.warpzone_chain)
		e.solid = SOLID_BSP;
}

void() warpzone_make_all_other {
	entity e;
	for (e = warpzone_chain_begin; e; e  = e.warpzone_chain)
		e.solid = SOLID_TRIGGER;
}

void() warpzone_trace_init_transform {
	if (!warpzone_trace_transform) {
		warpzone_trace_transform = spawn();
		warpzone_trace_transform.classname = "warpzone_trace_transform";
	}
	warpzone_accumulator_clear(warpzone_trace_transform);
}

void(entity wz) warpzone_trace_add_transform {
	warpzone_accumulator_add(warpzone_trace_transform, wz);
}

void(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent, entity zone, warpzone_trace_callback_t cb) warpzone_trace_box_trough_zone_real {
	float frac, sol;
	vector o0, e0;
	entity wz;
	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	o0 = org;
	e0 = end;
	warpzone_trace_warpcount = 0;
	warpzone_trace_init_transform();
	// if starting in warpzone, first transform
	wz = warpzone_find(org + mi, org + ma);
	if (wz) {
		if (zone && wz != zone) {
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.
			sol = 1;
			trace_fraction = 0;
			trace_endpos = org;
			goto fail;
		}
		warpzone_trace_add_transform(wz);
		org = warpzone_transform_origin(wz, org);
		end = warpzone_transform_origin(wz, end);
	}
	warpzone_make_all_solid();
	sol = -1;
	frac = 0;
	float i;
	for (i = 10; i; i--) {
		warpzone_trace_dir = normalize(end - org);
		trace_box(org, mi, ma, end, nomonsters, forent);
		if (cb)
			cb(org, trace_endpos, end);

		if (sol < 0)
			sol = trace_startsolid;

		frac = trace_fraction = frac + (1 - frac) * trace_fraction;
		if (trace_fraction >= 1) {
            if (trace_ent.classname == "trigger_warpzone")
                trace_ent = world;

			break;
		}
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
		org = warpzone_transform_origin(wz, trace_endpos);
		end = warpzone_transform_origin(wz, end);
		++warpzone_trace_warpcount;
	}
	if (i == 0) {
		//print("warpzone_trace_box_trough_zone: escape from loop\n");
		trace_ent = world;
	}
	warpzone_make_all_other();
:fail
	trace_startsolid = sol;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
}

void(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent) warpzone_trace_box_real {
	warpzone_trace_box_trough_zone(org, mi, ma, end, nomonsters, forent, world, NULL);
}

void(vector org, vector end, float nomonsters, entity forent) warpzone_trace_line_real {
	warpzone_trace_box_real(org, '0 0 0', '0 0 0', end, nomonsters, forent);
}

entity warpzone_trail_particles_trace_callback_own;
float warpzone_trail_particles_trace_callback_eff;
void(vector from, vector endpos, vector to) warpzone_trail_particles_trace_callback {
    trailparticles(warpzone_trail_particles_trace_callback_own, warpzone_trail_particles_trace_callback_eff, from, endpos);
}

void(entity own, float eff, vector org, vector org_visual, vector end) warpzone_trail_particles {
    warpzone_trail_particles_trace_callback_own = own;
    warpzone_trail_particles_trace_callback_eff = eff;
    warpzone_trace_triangle(org, org_visual, end, TRACE_MOVE_NOMONSTERS, world, warpzone_trail_particles_trace_callback);
}

float(entity wz, vector v) warpzone_plane_dist {
	return (v - wz.warpzone_origin) * wz.warpzone_forward;
}

float(entity wz, vector v) warpzone_target_plane_dist {
	return (v - wz.warpzone_targetorigin) * wz.warpzone_targetforward;
}

vector(entity wz, vector v) warpzone_transform_origin_real {
	return wz.warpzone_shift + AnglesTransform_Apply(wz.warpzone_transform, v);
}

vector(entity wz, vector v) warpzone_transform_velocity_real {
	return AnglesTransform_Apply(wz.warpzone_transform, v);
}

vector(entity wz, vector v) warpzone_transform_angles {
	return AnglesTransform_ApplyToAngles(wz.warpzone_transform, v);
}

vector(entity wz, vector ang) warpzone_transform_vangles {
	ang = AnglesTransform_ApplyToVAngles(wz.warpzone_transform, ang);
	ang = AnglesTransform_Normalize(ang, FALSE);
	return ang;
}

vector(entity wz, vector v) warpzone_untransform_origin_real {
	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	v = AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), v - wz.warpzone_shift);
	v_forward = vf;
	v_right = vr;
	v_up = vu;
	return v;
}

vector(entity wz, vector v) warpzone_untransform_velocity {
	return AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), v);
}

vector(entity wz, vector v) warpzone_untransform_angles {
	return AnglesTransform_ApplyToAngles(AnglesTransform_Invert(wz.warpzone_transform), v);
}

vector(entity wz, vector ang) warpzone_untransform_vangles {
	float roll;
	roll = ang_z;
	ang_z = 0;
	ang = AnglesTransform_ApplyToVAngles(AnglesTransform_Invert(wz.warpzone_transform), ang);
	ang = AnglesTransform_Normalize(ang, TRUE);
	ang = AnglesTransform_CancelRoll(ang);
	ang_z = roll;
	return ang;
}

vector(vector mi, vector ma, vector org) warpzone_nearest_point_on_box {
	vector nearest;
	nearest_x = bound(mi_x, org_x, ma_x);
	nearest_y = bound(mi_y, org_y, ma_y);
	nearest_z = bound(mi_z, org_z, ma_z);
	return nearest;
}

.float warpzone_findradius_hit;
.entity warpzone_findradius_next;
void(vector org, float rad, vector org0, vector transform, vector shift, float needlineofsight) warpzone_find_radius_recurse {
	vector org_new;
	vector org0_new;
	vector shift_new, transform_new;
	vector p;
	entity e, e0;
	entity wz;
	if (rad <= 0)
		return;

	e0 = findradius(org, rad);
	wz = world;
	for (e = e0; e; e = e.chain) {
		p = warpzone_nearest_point_on_box(e.origin + e.mins, e.origin + e.maxs, org0);
		if (needlineofsight) {
			trace_line(org, p, TRACE_MOVE_NOMONSTERS, e);
			if (trace_fraction < 1)
				continue;
		}
		if (!e.warpzone_findradius_hit || vlen(e.warpzone_findradius_dist) > vlen(org0 - p)) {
			e.warpzone_findradius_nearest = p;
			e.warpzone_findradius_dist = org0 - p;
			e.warpzone_findradius_findorigin = org;
			e.warpzone_findradius_findradius = rad;
			if (e.classname == "warpzone_refsys") {
				// ignore, especially: do not overwrite the refsys parameters
			} else if (e.classname == "trigger_warpzone") {
				e.warpzone_findradius_next = wz;
				wz = e;
				e.warpzone_findradius_hit = 1;
				e.enemy.warpzone_findradius_dist = '0 0 0'; // we don't want to go through this zone ever again
				e.enemy.warpzone_findradius_hit = 1;
			} else {
				e.warpzone_transform = transform;
				e.warpzone_shift = shift;
				e.warpzone_findradius_hit = 1;
			}
		}
	}
	for (e = wz; e; e = e.warpzone_findradius_next) {
		org0_new = warpzone_transform_origin(e, org);
		trace_line(e.warpzone_targetorigin, org0_new, TRACE_MOVE_NOMONSTERS, e);
		org_new = trace_endpos;
		transform_new = AnglesTransform_Multiply(e.warpzone_transform, transform);
		shift_new = AnglesTransform_Multiply_GetPostShift(e.warpzone_transform, e.warpzone_shift, transform, shift);
		warpzone_find_radius_recurse(
			org_new,
			bound(0, rad - vlen(org_new - org0_new), rad - 8),
			org0_new,
			transform_new, shift_new,
			needlineofsight);
		e.warpzone_findradius_hit = 0;
		e.enemy.warpzone_findradius_hit = 0;
	}
}

entity(vector org, float rad, float needlineofsight) warpzone_find_radius_real {
	entity e0, e;
	warpzone_find_radius_recurse(org, rad, org, '0 0 0', '0 0 0', needlineofsight);
	e0 = findchainfloat(warpzone_findradius_hit, 1);
	for (e = e0; e; e = e.chain)
		e.warpzone_findradius_hit = 0;

	return e0;
}

entity(vector org, float rad, float needlineofsight) warpzone_find_radius_stub {
	entity e0 = findradius(org, rad);
	entity e;
	for (e = e0; e; e = e.chain) {
		e.warpzone_findradius_nearest = warpzone_nearest_point_on_box(e.origin + e.mins, e.origin + e.maxs, org);
		e.warpzone_findradius_dist = e.warpzone_findradius_nearest - org;
	}
	return e0;
}

vector(vector planep, vector planen, vector linep, vector linev) warpzone_plane_and_line_cross {
	//Teh Analytic Geometry
	vector crosspoint;
	float common_denom = ((planen_x * linev_x) + (planen_y * linev_y) + (planen_z * linev_z));
	if (linev_x == 0) {
		crosspoint_x = linep_x;
	} else {
		crosspoint_x = (linev_x * ((planep_x * planen_x) + (planen_y * (planep_y - linep_y)) + (planen_z * (planep_z - linep_z))) +
			(linep_x * ((planen_y * linev_y) + (planen_z * linev_z)))) /
			common_denom;
	}
	if (linev_y == 0) {
		crosspoint_y = linep_y;
	} else {
		crosspoint_y = (linev_y * ((planep_y * planen_y) + (planen_x * (planep_x - linep_x)) + (planen_z * (planep_z - linep_z))) +
			(linep_y * ((planen_x * linev_x) + (planen_z * linev_z)))) /
			common_denom;
	}
	if (linev_z == 0) {
		crosspoint_z = linep_z;
	} else {
		crosspoint_z = (linev_z * ((planep_z * planen_z) + (planen_y * (planep_y - linep_y)) + (planen_x * (planep_x - linep_x))) +
			(linep_z * ((planen_y * linev_y) + (planen_x * linev_x)))) /
			common_denom;
	}
	return crosspoint;
}

var warpzone_trace_callback_t warpzone_trace_triangle_real_callback;
vector warpzone_trace_triangle_visual_from;
void(vector from, vector endpos, vector to) warpzone_trace_triangle_callback {
	vector o = warpzone_transform_origin(warpzone_trace_transform, warpzone_trace_triangle_visual_from);
	vector to_visual;
	if (trace_fraction < 1) {
		vector normal;
		if (trace_ent && trace_ent.classname == "trigger_warpzone")
			normal = trace_ent.warpzone_forward;
		else
			normal = warpzone_trace_dir;
		to_visual = warpzone_plane_and_line_cross(endpos, normal, o, o - to);
	} else
		to_visual = endpos;

	if (warpzone_trace_triangle_real_callback)
		warpzone_trace_triangle_real_callback(o, to_visual, to);

	warpzone_trace_triangle_visual_from = warpzone_untransform_origin(warpzone_trace_transform, to_visual);
}

void(vector org, vector org_visual, vector end, float nomonsters, entity forent, warpzone_trace_callback_t cb) warpzone_trace_triangle {
	warpzone_trace_triangle_visual_from = org_visual;
	warpzone_trace_triangle_real_callback = cb;
	float antiloop;
	for (antiloop = 0; antiloop < 10; antiloop++) {
		warpzone_trace_box_trough_zone(org, '0 0 0', '0 0 0', end, nomonsters, forent, world, warpzone_trace_triangle_callback);
		if (trace_fraction == 1) break;
		end = warpzone_transform_origin(warpzone_trace_transform, end);
		if (vlen(trace_endpos - end) < 1) break;
		org = trace_endpos + warpzone_trace_dir;
		warpzone_trace_triangle_visual_from = warpzone_transform_origin(warpzone_trace_transform, warpzone_trace_triangle_visual_from);
	}
}

float warpzone_find_nearest_origin_length;
vector(vector from, vector to, float trace_check) warpzone_find_nearest_origin_real {
	entity e;
	float length_warped;
    vector to_warped, to_nearest = to;
	if (trace_check > 1) {
		warpzone_trace_line(from, to, TRACE_MOVE_NOMONSTERS, world);
		if (vlen(trace_endpos - to) < 1) {
			warpzone_find_nearest_origin_length = vlen(to - from);
		} else {
			warpzone_find_nearest_origin_length = -1;
		}
	} else {
		warpzone_find_nearest_origin_length = vlen(to - from);
	}
	for (e = warpzone_chain_begin; e; e  = e.warpzone_chain) {
		to_warped = warpzone_transform_origin(e, to);
		length_warped = vlen(to_warped - from);
		if (length_warped < warpzone_find_nearest_origin_length || warpzone_find_nearest_origin_length < 0) {
			if (trace_check) {
				warpzone_trace_line(from, to_warped, TRACE_MOVE_NOMONSTERS, world);
				if (vlen(trace_endpos - to) < 1) {
					warpzone_find_nearest_origin_length = length_warped;
					to_nearest = to_warped;
				}
			} else {
				warpzone_find_nearest_origin_length = length_warped;
				to_nearest = to_warped;
			}
		}
	}
	return to_nearest;
}

void(entity wz) warpzone_chain_add {
	for (entity e = warpzone_chain_begin; e; e = e.warpzone_chain) {
		if (e == wz) {
			//backtrace("warpzone chain loop");
			return;
		}
	}
	wz.warpzone_chain = warpzone_chain_begin;
	warpzone_chain_begin = wz;
}

float warpzone_sound_transition;

void(vector org, vector end, float nomonsters, entity forent, entity zone, warpzone_trace_callback_t cb) warpzone_trace_line_trough_zone_real {
	warpzone_trace_box_trough_zone_real(org, '0 0 0', '0 0 0', end, nomonsters, forent, zone, cb);
}

vector(entity wz, vector o) warpzone_untransform_origin_stub {
	return o;
}

vector(entity wz, vector o) warpzone_transform_origin_stub {
	return o;
}

vector(entity wz, vector v) warpzone_transform_velocity_stub {
	return v;
}

void(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent, entity zone, warpzone_trace_callback_t cb) warpzone_trace_box_trough_zone_stub {
	trace_box(org, mi, ma, end, nomonsters, forent);
	if (cb)
		cb(org, trace_endpos, trace_endpos);
}

void(vector org, vector end, float nomonsters, entity forent, entity zone, warpzone_trace_callback_t cb) warpzone_trace_line_trough_zone_stub {
	trace_line(org, end, nomonsters, forent);
	if (cb)
		cb(org, trace_endpos, trace_endpos);
}

void(vector org, vector org_visual, vector end, warpzone_trace_callback_t cb) warpzone_draw_effect_triangle_real {
	warpzone_trace_triangle(org, org_visual, end, TRACE_MOVE_NOMONSTERS, world, cb);
}

void(vector org, vector org_visual, vector end, warpzone_trace_callback_t cb) warpzone_draw_effect_triangle_stub {
	cb(org_visual, end, end);
}

vector(vector from, vector to, float trace_check) warpzone_find_nearest_origin_stub {
	if (trace_check > 1) {
		trace_line(from, to, TRACE_MOVE_NOMONSTERS, world);
		if (vlen(trace_endpos - to) < 1) {
			warpzone_find_nearest_origin_length = vlen(to - from);
		} else {
			warpzone_find_nearest_origin_length = -1;
		}
	} else {
		warpzone_find_nearest_origin_length = vlen(to - from);
	}
	return to;
}

void() warpzone_init {
	warpzone_find_nearest_origin = warpzone_find_nearest_origin_stub;
	warpzone_find_radius = warpzone_find_radius_stub;
	warpzone_draw_effect_triangle = warpzone_draw_effect_triangle_stub;
	warpzone_trace_box = trace_box;
	warpzone_trace_line = trace_line;
	warpzone_trace_box_trough_zone = warpzone_trace_box_trough_zone_stub;
	warpzone_trace_line_trough_zone = warpzone_trace_line_trough_zone_stub;
	warpzone_untransform_origin = warpzone_untransform_origin_stub;
	warpzone_transform_origin = warpzone_transform_origin_stub;
	warpzone_transform_velocity = warpzone_transform_velocity_stub;
	warpzone_chain_begin = world;
	warpzone_init_hook();
}

void() warpzone_enable {
	warpzone_find_nearest_origin = warpzone_find_nearest_origin_real;
	warpzone_find_radius = warpzone_find_radius_real;
	warpzone_draw_effect_triangle = warpzone_draw_effect_triangle_real;
	warpzone_trace_box = warpzone_trace_box_real;
	warpzone_trace_line = warpzone_trace_line_real;
	warpzone_trace_box_trough_zone = warpzone_trace_box_trough_zone_real;
	warpzone_trace_line_trough_zone = warpzone_trace_line_trough_zone_real;
	warpzone_untransform_origin = warpzone_untransform_origin_real;
	warpzone_transform_origin = warpzone_transform_origin_real;
	warpzone_transform_velocity = warpzone_transform_velocity_real;
	warpzone_enable_hook();
}

void() warpzone_shutdown {
	warpzone_shutdown_hook();
}

#if 0
void(entity e, float chan, string sound_path, float vol, float attn) warpzone_sound {
	sound(e, chan, sound_path, vol, attn);
	if (warpzone_sound_transition) {
		vector find_area = '1 1 1';
		find_area *= warpzone_sound_transition;
		entity wz = warpzone_find(e.origin - find_area, e.origin + find_area);
		if (wz) {
			entity e_transited = spawn();
			setorigin(e_transited, warpzone_transform_origin(wz, e.origin));
			sound(e_transited, chan, sound_path, vol, attn);
			remove(e_transited);
		}
	}
}

vector(vector fwd, vector viewer, vector viewee, float traceflag, entity traceent) warpzone_find_line_of_sight {
	vector dir = normalize(viewee - viewer);
	vector viewee_warped;
	// try a direct trace first
	if (fwd != '0 0 0' && dir * fwd < 0) {
		// no eyes on our back
	} else {
		warpzone_trace_line(viewer, viewee, traceflag, traceent);
		if (vlen(trace_endpos - viewee) < 1) {
			// a line of sight exists
			return dir;
		}
	}
	// failed, let's try the nearest warpzone
	float nearest_dst = 1250; // initialize with the maximum distance
	entity nearest_wz = NULL;
	vector nearest_wz_vw = '0 0 0';
	vector nearest_dir = '0 0 0';
	for (entity wz = warpzone_chain_begin; wz; wz = wz.warpzone_chain) {
		vector org = wz.origin;
		if (org == '0 0 0')
			org = 0.5 * (wz.mins + wz.maxs);

		float dst = vlen(org - viewer);
		if (dst < nearest_dst) {
			viewee_warped = warpzone_untransform_origin(wz, viewee);
			dir = normalize(viewee_warped - viewer);

			if (fwd != '0 0 0' && dir * fwd < 0)
				continue; // no eyes on our back

			nearest_dst = dst;
			nearest_wz = wz;
			nearest_wz_vw = viewee_warped;
			nearest_dir = dir;
		}
	}
	if (nearest_wz) {
		warpzone_trace_line(viewer, nearest_wz_vw, traceflag, traceent);
		if (vlen(trace_endpos - viewee) < 1) {
			// a line of sight exists
			return nearest_dir;
		}
	}
	// nope, give up
	return '0 0 0';
}
#endif
