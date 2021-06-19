void WarpZone_Accumulator_Clear(entity acc)
{
	acc.warpzone_transform = '0 0 0';
	acc.warpzone_shift = '0 0 0';
}
void WarpZone_Accumulator_AddTransform(entity acc, vector t, vector s)
{
	vector tr, st;
	tr = AnglesTransform_Multiply(t, acc.warpzone_transform);
	st = AnglesTransform_Multiply_GetPostShift(t, s, acc.warpzone_transform, acc.warpzone_shift);
	acc.warpzone_transform = tr;
	acc.warpzone_shift = st;
}
void WarpZone_Accumulator_Add(entity acc, entity wz)
{
	vector t, st;
	t = AnglesTransform_Multiply(wz.warpzone_transform, acc.warpzone_transform);
	st = AnglesTransform_Multiply_GetPostShift(wz.warpzone_transform, wz.warpzone_shift, acc.warpzone_transform, acc.warpzone_shift);
	acc.warpzone_transform = t;
	acc.warpzone_shift = st;
}

var float autocvar_cl_warpzone_usetrace = 1;
vector WarpZone_camera_transform(vector org, vector ang)
{
	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	org = WarpZone_TransformOrigin(self, org);
	vf = WarpZone_TransformVelocity(self, vf);
	vr = WarpZone_TransformVelocity(self, vr);
	vu = WarpZone_TransformVelocity(self, vu);
	if(autocvar_cl_warpzone_usetrace)
		trace_line(self.warpzone_targetorigin, org, TRACE_MOVE_NOMONSTERS, world);
	else
		trace_endpos = self.warpzone_targetorigin;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
	return org;
}

void WarpZone_SetUp(entity e, vector my_org, vector my_ang, vector other_org, vector other_ang)
{
	e.warpzone_transform = AnglesTransform_RightDivide(other_ang, AnglesTransform_TurnDirectionFR(my_ang));
	e.warpzone_shift = AnglesTransform_PrePostShift_GetPostShift(my_org, e.warpzone_transform, other_org);
	e.warpzone_origin = my_org;
	e.warpzone_targetorigin = other_org;
	e.warpzone_angles = my_ang;
	e.warpzone_targetangles = other_ang;
	makevectors(my_ang); e.warpzone_forward = v_forward;
	makevectors(other_ang); e.warpzone_targetforward = v_forward;
	e.camera_transform = WarpZone_camera_transform;
}

.entity enemy;

vector WarpZone_BoxTouchesBrush_mins;
vector WarpZone_BoxTouchesBrush_maxs;
entity WarpZone_BoxTouchesBrush_ent;
entity WarpZone_BoxTouchesBrush_ignore;
float WarpZone_BoxTouchesBrush_Recurse()
{
	float s;
	entity se;
	float f;

	trace_box('0 0 0', WarpZone_BoxTouchesBrush_mins, WarpZone_BoxTouchesBrush_maxs, '0 0 0', TRACE_MOVE_NOMONSTERS, WarpZone_BoxTouchesBrush_ignore);
#ifdef CSQC
	if (trace_networkentity)
		// we cannot continue, as a player blocks us...
		// so, abort
		return 0;
#endif
	if not(trace_ent)
		return 0;
	if (trace_ent == WarpZone_BoxTouchesBrush_ent)
		return 1;

	se = trace_ent;
	s = se.solid;
	se.solid = SOLID_NOT;
	f = WarpZone_BoxTouchesBrush_Recurse();
	se.solid = s;

	return f;
}

float WarpZone_BoxTouchesBrush(vector mi, vector ma, entity e, entity ig)
{
    float f, s;

    if not(e.modelindex)
        return 1;

    s = e.solid;
    e.solid = SOLID_BSP;
    WarpZone_BoxTouchesBrush_mins = mi;
    WarpZone_BoxTouchesBrush_maxs = ma;
    WarpZone_BoxTouchesBrush_ent = e;
    WarpZone_BoxTouchesBrush_ignore = ig;
    f = WarpZone_BoxTouchesBrush_Recurse();
    e.solid = s;

    return f;
}

entity WarpZone_Find(vector mi, vector ma)
{
	// if we are near any warpzone planes - MOVE AWAY (work around nearclip)
	entity e;
	for(e = warpzone_chain_begin; e; e  = e.warpzone_chain)
		if(WarpZone_BoxTouchesBrush(mi, ma, e, world))
			return e;
	return world;
}

void WarpZone_MakeAllSolid()
{
	entity e;
	for(e = warpzone_chain_begin; e; e  = e.warpzone_chain)
		e.solid = SOLID_BSP;
}

void WarpZone_MakeAllOther()
{
	entity e;
	for(e = warpzone_chain_begin; e; e  = e.warpzone_chain)
		e.solid = SOLID_TRIGGER;
}

void WarpZone_Trace_InitTransform()
{
	if(!WarpZone_trace_transform)
	{
		WarpZone_trace_transform = spawn();
		WarpZone_trace_transform.classname = "warpzone_trace_transform";
	}
	WarpZone_Accumulator_Clear(WarpZone_trace_transform);
}
void WarpZone_Trace_AddTransform(entity wz)
{
	WarpZone_Accumulator_Add(WarpZone_trace_transform, wz);
}

void WarpZone_TraceBox_ThroughZone_real(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent, entity zone, WarpZone_trace_callback_t cb)
{
	float frac, sol;
	vector o0, e0;
	entity wz;
	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	o0 = org;
	e0 = end;
	WarpZone_trace_warpcount = 0;
	WarpZone_Trace_InitTransform();
	// if starting in warpzone, first transform
	wz = WarpZone_Find(org + mi, org + ma);
	if(wz)
	{
		if(zone && wz != zone)
		{
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.
			sol = 1;
			trace_fraction = 0;
			trace_endpos = org;
			goto fail;
		}
		WarpZone_Trace_AddTransform(wz);
		org = WarpZone_TransformOrigin(wz, org);
		end = WarpZone_TransformOrigin(wz, end);
	}
	WarpZone_MakeAllSolid();
	sol = -1;
	frac = 0;
	float i;
	for(i = 10; i; i--)
	{
		WarpZone_trace_dir = normalize(end - org);
        trace_box(org, mi, ma, end, nomonsters, forent);
		if(cb)
			cb(org, trace_endpos, end);
		if(sol < 0)
			sol = trace_startsolid;

		frac = trace_fraction = frac + (1 - frac) * trace_fraction;
		if(trace_fraction >= 1) {
            if(trace_ent.classname == "trigger_warpzone")
                trace_ent = world;
			break;
        }
		if(trace_ent.classname != "trigger_warpzone")
			break;
		if(trace_ent == wz)
		{
			//print("I transformed into the same zone again, wtf, aborting the trace\n");
			break;
		}
		wz = trace_ent;
		if(zone && wz != zone)
			break;
		WarpZone_Trace_AddTransform(wz);
		// we hit a warpzone... so, let's perform the trace after the warp again
		org = WarpZone_TransformOrigin(wz, trace_endpos);
		end = WarpZone_TransformOrigin(wz, end);
		++WarpZone_trace_warpcount;
	}
	if (i == 0) {
		//print("WarpZone_TraceBox_ThroughZone: escape from loop\n");
		trace_ent = world;
	}
	WarpZone_MakeAllOther();
:fail
	trace_startsolid = sol;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
}

void WarpZone_TraceBox_real(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent)
{
	WarpZone_TraceBox_ThroughZone(org, mi, ma, end, nomonsters, forent, world, NULL);
}

void WarpZone_TraceLine_real(vector org, vector end, float nomonsters, entity forent)
{
	WarpZone_TraceBox(org, '0 0 0', '0 0 0', end, nomonsters, forent);
}

entity WarpZone_TrailParticles_trace_callback_own;
float WarpZone_TrailParticles_trace_callback_eff;
void WarpZone_TrailParticles_trace_callback(vector from, vector endpos, vector to)
{
    trailparticles(WarpZone_TrailParticles_trace_callback_own, WarpZone_TrailParticles_trace_callback_eff, from, endpos);
}

void WarpZone_TrailParticles(entity own, float eff, vector org, vector org_visual, vector end)
{
    WarpZone_TrailParticles_trace_callback_own = own;
    WarpZone_TrailParticles_trace_callback_eff = eff;
    WarpZone_TraceTriangle(org, org_visual, end, TRACE_MOVE_NOMONSTERS, world, WarpZone_TrailParticles_trace_callback);
}

float WarpZone_PlaneDist(entity wz, vector v)
{
	return (v - wz.warpzone_origin) * wz.warpzone_forward;
}

float WarpZone_TargetPlaneDist(entity wz, vector v)
{
	return (v - wz.warpzone_targetorigin) * wz.warpzone_targetforward;
}

vector WarpZone_TransformOrigin_real(entity wz, vector v)
{
	return wz.warpzone_shift + AnglesTransform_Apply(wz.warpzone_transform, v);
}

vector WarpZone_TransformVelocity_real(entity wz, vector v)
{
	return AnglesTransform_Apply(wz.warpzone_transform, v);
}

vector WarpZone_TransformAngles(entity wz, vector v)
{
	return AnglesTransform_ApplyToAngles(wz.warpzone_transform, v);
}

vector WarpZone_TransformVAngles(entity wz, vector ang)
{
#ifdef KEEP_ROLL
	float roll;
	roll = ang_z;
	ang_z = 0;
#endif

	ang = AnglesTransform_ApplyToVAngles(wz.warpzone_transform, ang);

#ifdef KEEP_ROLL
	ang = AnglesTransform_Normalize(ang, TRUE);
	ang = AnglesTransform_CancelRoll(ang);
	ang_z = roll;
#else
	ang = AnglesTransform_Normalize(ang, FALSE);
#endif

	return ang;
}

vector WarpZone_UnTransformOrigin_real(entity wz, vector v)
{
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

vector WarpZone_UnTransformVelocity(entity wz, vector v)
{
	return AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), v);
}

vector WarpZone_UnTransformAngles(entity wz, vector v)
{
	return AnglesTransform_ApplyToAngles(AnglesTransform_Invert(wz.warpzone_transform), v);
}

vector WarpZone_UnTransformVAngles(entity wz, vector ang)
{
	float roll;

	roll = ang_z;
	ang_z = 0;

	ang = AnglesTransform_ApplyToVAngles(AnglesTransform_Invert(wz.warpzone_transform), ang);
	ang = AnglesTransform_Normalize(ang, TRUE);
	ang = AnglesTransform_CancelRoll(ang);

	ang_z = roll;
	return ang;
}

vector WarpZone_NearestPointOnBox(vector mi, vector ma, vector org)
{
	vector nearest;
	nearest_x = bound(mi_x, org_x, ma_x);
	nearest_y = bound(mi_y, org_y, ma_y);
	nearest_z = bound(mi_z, org_z, ma_z);
	return nearest;
}

.float WarpZone_findradius_hit;
.entity WarpZone_findradius_next;
void WarpZone_FindRadius_Recurse(vector org, float rad,        vector org0,               vector transform, vector shift, float needlineofsight)
//                               blast origin of current search   original blast origin   how to untransform (victim to blast system)
{
	vector org_new;
	vector org0_new;
	vector shift_new, transform_new;
	vector p;
	entity e, e0;
	entity wz;
	if(rad <= 0)
		return;
	e0 = findradius(org, rad);
	wz = world;

	for(e = e0; e; e = e.chain)
	{
		p = WarpZone_NearestPointOnBox(e.origin + e.mins, e.origin + e.maxs, org0);
		if(needlineofsight)
		{
			trace_line(org, p, TRACE_MOVE_NOMONSTERS, e);
			if(trace_fraction < 1)
				continue;
		}
		if(!e.WarpZone_findradius_hit || vlen(e.WarpZone_findradius_dist) > vlen(org0 - p))
		{
			e.WarpZone_findradius_nearest = p;
			e.WarpZone_findradius_dist = org0 - p;
			e.WarpZone_findradius_findorigin = org;
			e.WarpZone_findradius_findradius = rad;
			if(e.classname == "warpzone_refsys")
			{
				// ignore, especially: do not overwrite the refsys parameters
			}
			else if(e.classname == "trigger_warpzone")
			{
				e.WarpZone_findradius_next = wz;
				wz = e;
				e.WarpZone_findradius_hit = 1;
				e.enemy.WarpZone_findradius_dist = '0 0 0'; // we don't want to go through this zone ever again
				e.enemy.WarpZone_findradius_hit = 1;
			}
			else
			{
				e.warpzone_transform = transform;
				e.warpzone_shift = shift;
				e.WarpZone_findradius_hit = 1;
			}
		}
	}
	for(e = wz; e; e = e.WarpZone_findradius_next)
	{
		org0_new = WarpZone_TransformOrigin(e, org);
		trace_line(e.warpzone_targetorigin, org0_new, TRACE_MOVE_NOMONSTERS, e);
		org_new = trace_endpos;

		transform_new = AnglesTransform_Multiply(e.warpzone_transform, transform);
		shift_new = AnglesTransform_Multiply_GetPostShift(e.warpzone_transform, e.warpzone_shift, transform, shift);
		WarpZone_FindRadius_Recurse(
			org_new,
			bound(0, rad - vlen(org_new - org0_new), rad - 8),
			org0_new,
			transform_new, shift_new,
			needlineofsight);
		e.WarpZone_findradius_hit = 0;
		e.enemy.WarpZone_findradius_hit = 0;
	}
}
entity WarpZone_FindRadius_real(vector org, float rad, float needlineofsight)
{
	entity e0, e;
	WarpZone_FindRadius_Recurse(org, rad, org, '0 0 0', '0 0 0', needlineofsight);
	e0 = findchainfloat(WarpZone_findradius_hit, 1);
	for(e = e0; e; e = e.chain)
		e.WarpZone_findradius_hit = 0;
	return e0;
}

entity WarpZone_FindRadius_stub(vector org, float rad, float needlineofsight)
{
	entity e0 = findradius(org, rad);
	entity e;
	for(e = e0; e; e = e.chain) {
		e.WarpZone_findradius_nearest = WarpZone_NearestPointOnBox(e.origin + e.mins, e.origin + e.maxs, org);
		e.WarpZone_findradius_dist = e.WarpZone_findradius_nearest - org;
	}
	return e0;
}

.entity WarpZone_refsys;
void WarpZone_RefSys_GC()
{
	// garbage collect unused reference systems
	self.nextthink = time + 1;
	if(self.owner.WarpZone_refsys != self)
		remove(self);
}
void WarpZone_RefSys_Add(entity me, entity wz)
{
	if(me.WarpZone_refsys.owner != me)
	{
		me.WarpZone_refsys = spawn();
		me.WarpZone_refsys.classname = "warpzone_refsys";
		me.WarpZone_refsys.owner = me;
		me.WarpZone_refsys.think = WarpZone_RefSys_GC;
		me.WarpZone_refsys.nextthink = time + 1;
		WarpZone_Accumulator_Clear(me.WarpZone_refsys);
	}
	if(wz)
		WarpZone_Accumulator_Add(me.WarpZone_refsys, wz);
}
.vector WarpZone_refsys_incremental_shift;
.vector WarpZone_refsys_incremental_transform;
void WarpZone_RefSys_AddIncrementally_real(entity me, entity ref)
{
	vector t, s;
	if(me.WarpZone_refsys_incremental_transform == ref.WarpZone_refsys.warpzone_transform)
	if(me.WarpZone_refsys_incremental_shift == ref.WarpZone_refsys.warpzone_shift)
		return;
	if(me.WarpZone_refsys.owner != me)
	{
		me.WarpZone_refsys = spawn();
		me.WarpZone_refsys.classname = "warpzone_refsys";
		me.WarpZone_refsys.owner = me;
		me.WarpZone_refsys.think = WarpZone_RefSys_GC;
		me.WarpZone_refsys.nextthink = time + 1;
		WarpZone_Accumulator_Clear(me.WarpZone_refsys);
	}
	t = AnglesTransform_Invert(me.WarpZone_refsys_incremental_transform);
	s = AnglesTransform_PrePostShift_GetPostShift(me.WarpZone_refsys_incremental_shift, t, '0 0 0');
	WarpZone_Accumulator_AddTransform(me.WarpZone_refsys, t, s);
	WarpZone_Accumulator_Add(me.WarpZone_refsys, ref);
	me.WarpZone_refsys_incremental_shift = ref.WarpZone_refsys.warpzone_shift;
	me.WarpZone_refsys_incremental_transform = ref.WarpZone_refsys.warpzone_transform;
}
void WarpZone_RefSys_BeginAddingIncrementally_real(entity me, entity ref)
{
	me.WarpZone_refsys_incremental_shift = ref.WarpZone_refsys.warpzone_shift;
	me.WarpZone_refsys_incremental_transform = ref.WarpZone_refsys.warpzone_transform;
}
vector WarpZone_RefSys_TransformOrigin_real(entity from, entity to, vector org)
{
	if(from.WarpZone_refsys)
		org = WarpZone_UnTransformOrigin(from.WarpZone_refsys, org);
	if(to.WarpZone_refsys)
		org = WarpZone_TransformOrigin(to.WarpZone_refsys, org);
	return org;
}
vector WarpZone_RefSys_TransformVelocity_real(entity from, entity to, vector vel)
{
	if(from.WarpZone_refsys)
		vel = WarpZone_UnTransformVelocity(from.WarpZone_refsys, vel);
	if(to.WarpZone_refsys)
		vel = WarpZone_TransformVelocity(to.WarpZone_refsys, vel);
	return vel;
}
vector WarpZone_RefSys_TransformAngles_real(entity from, entity to, vector ang)
{
	if(from.WarpZone_refsys)
		ang = WarpZone_UnTransformAngles(from.WarpZone_refsys, ang);
	if(to.WarpZone_refsys)
		ang = WarpZone_TransformAngles(to.WarpZone_refsys, ang);
	return ang;
}
vector WarpZone_RefSys_TransformVAngles(entity from, entity to, vector ang)
{
	if(from.WarpZone_refsys)
		ang = WarpZone_UnTransformVAngles(from.WarpZone_refsys, ang);
	if(to.WarpZone_refsys)
		ang = WarpZone_TransformVAngles(to.WarpZone_refsys, ang);
	return ang;
}
entity WarpZone_RefSys_SpawnSameRefSys_real(entity me)
{
	entity e;
	e = spawn();
	if(me.WarpZone_refsys)
	{
		e.WarpZone_refsys = spawn();
		e.WarpZone_refsys.classname = "warpzone_refsys";
		e.WarpZone_refsys.owner = e;
		e.WarpZone_refsys.think = WarpZone_RefSys_GC;
		e.WarpZone_refsys.nextthink = time + 1;
		e.WarpZone_refsys.warpzone_shift = me.WarpZone_refsys.warpzone_shift;
		e.WarpZone_refsys.warpzone_transform = me.WarpZone_refsys.warpzone_transform;
	}
	return e;
}

vector WarpZone_PlaneAndLineCross(vector planep, vector planen, vector linep, vector linev) {
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

var WarpZone_trace_callback_t WarpZone_TraceTriangle_real_callback;
vector WarpZone_TraceTriangle_visual_from;
void WarpZone_TraceTriangle_callback(vector from, vector endpos, vector to) {
    vector o = WarpZone_TransformOrigin(WarpZone_trace_transform, WarpZone_TraceTriangle_visual_from);
	vector to_visual;
	if (trace_fraction < 1) {
		vector normal;
		if (trace_ent && trace_ent.classname == "trigger_warpzone")
			normal = trace_ent.warpzone_forward;
		else
			normal = WarpZone_trace_dir;
		to_visual = WarpZone_PlaneAndLineCross(endpos, normal, o, o - to);
	} else
		to_visual = endpos;
	if (WarpZone_TraceTriangle_real_callback)
		WarpZone_TraceTriangle_real_callback(o, to_visual, to);
	WarpZone_TraceTriangle_visual_from = WarpZone_UnTransformOrigin(WarpZone_trace_transform, to_visual);
}

void WarpZone_TraceTriangle(vector org, vector org_visual, vector end, float nomonsters, entity forent, WarpZone_trace_callback_t cb) {
	WarpZone_TraceTriangle_visual_from = org_visual;
	WarpZone_TraceTriangle_real_callback = cb;
	float antiloop;
	for (antiloop = 0; antiloop < 10; antiloop++) {
		WarpZone_TraceBox_ThroughZone(org, '0 0 0', '0 0 0', end, nomonsters, forent, world, WarpZone_TraceTriangle_callback);
		if (trace_fraction == 1) break;
		end = WarpZone_TransformOrigin(WarpZone_trace_transform, end);
		if (vlen(trace_endpos - end) < 1) break;
		org = trace_endpos + WarpZone_trace_dir;
		WarpZone_TraceTriangle_visual_from = WarpZone_TransformOrigin(WarpZone_trace_transform, WarpZone_TraceTriangle_visual_from);
	}
}

float WarpZone_FindNearestOrigin_length;
vector WarpZone_FindNearestOrigin_real(vector from, vector to, float trace_check)
{
	entity e;
	float length_warped;
    vector to_warped, to_nearest = to;

    if(trace_check > 1) {
        WarpZone_TraceLine(from, to, TRACE_MOVE_NOMONSTERS, world);

        if(vlen(trace_endpos - to) < 1) {
            WarpZone_FindNearestOrigin_length = vlen(to - from);
        } else {
            WarpZone_FindNearestOrigin_length = -1;
        }
    } else {
        WarpZone_FindNearestOrigin_length = vlen(to - from);
    }

	for(e = warpzone_chain_begin; e; e  = e.warpzone_chain) {
		to_warped = WarpZone_TransformOrigin(e, to);
		length_warped = vlen(to_warped - from);
		if (length_warped < WarpZone_FindNearestOrigin_length || WarpZone_FindNearestOrigin_length < 0) {
			if (trace_check) {
                WarpZone_TraceLine(from, to_warped, TRACE_MOVE_NOMONSTERS, world);
				if (vlen(trace_endpos - to) < 1) {
					WarpZone_FindNearestOrigin_length = length_warped;
					to_nearest = to_warped;
				}
			} else {
				WarpZone_FindNearestOrigin_length = length_warped;
				to_nearest = to_warped;
			}
		}
	}

	return to_nearest;
}

void WarpZone_ChainAdd(entity wz)
{
    for(var e = warpzone_chain_begin; e; e = e.warpzone_chain) {
        if(e == wz) {
            //backtrace("warpzone chain loop");
            return;
        }
    }

	wz.warpzone_chain = warpzone_chain_begin;
	warpzone_chain_begin = wz;
}

float warpzone_sound_transition;

void WarpZone_TraceLine_ThroughZone_real(vector org, vector end, float nomonsters, entity forent, entity zone, WarpZone_trace_callback_t cb) {
	WarpZone_TraceBox_ThroughZone_real(org, '0 0 0', '0 0 0', end, nomonsters, forent, zone, cb);
}

vector WarpZone_UnTransformOrigin_stub(entity wz, vector o) {
	return o;
}

vector WarpZone_TransformOrigin_stub(entity wz, vector o) {
	return o;
}

vector WarpZone_TransformVelocity_stub(entity wz, vector v) {
	return v;
}

void WarpZone_TraceBox_ThroughZone_stub(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent, entity zone, WarpZone_trace_callback_t cb) {
	trace_box(org, mi, ma, end, nomonsters, forent);
	if(cb)
		cb(org, trace_endpos, trace_endpos);
}

void WarpZone_TraceLine_ThroughZone_stub(vector org, vector end, float nomonsters, entity forent, entity zone, WarpZone_trace_callback_t cb) {
	trace_line(org, end, nomonsters, forent);
	if(cb)
		cb(org, trace_endpos, trace_endpos);
}

void WarpZone_DrawEffectTriangle_real(vector org, vector org_visual, vector end, WarpZone_trace_callback_t cb) {
	WarpZone_TraceTriangle(org, org_visual, end, TRACE_MOVE_NOMONSTERS, world, cb);
}

void WarpZone_DrawEffectTriangle_stub(vector org, vector org_visual, vector end, WarpZone_trace_callback_t cb) {
	cb(org_visual, end, end);
}

void WarpZone_RefSys_AddIncrementally_stub(entity me, entity ref) {}

vector WarpZone_RefSys_TransformOrigin_stub(entity from, entity to, vector org)
{
	return org;
}

vector WarpZone_RefSys_TransformVelocity_stub(entity from, entity to, vector vel)
{
	return vel;
}

entity WarpZone_RefSys_SpawnSameRefSys_stub(entity e) {
	return spawn();
}

vector WarpZone_RefSys_TransformAngles_stub(entity from, entity to, vector ang) {
	return ang;
}

void WarpZone_RefSys_BeginAddingIncrementally_stub(entity me, entity ref) {}

vector WarpZone_FindNearestOrigin_stub(vector from, vector to, float trace_check) {
    if(trace_check > 1) {
        trace_line(from, to, TRACE_MOVE_NOMONSTERS, world);
        if(vlen(trace_endpos - to) < 1) {
            WarpZone_FindNearestOrigin_length = vlen(to - from);
        } else {
            WarpZone_FindNearestOrigin_length = -1;
        }
    } else {
        WarpZone_FindNearestOrigin_length = vlen(to - from);
    }
	return to;
}

void WarpZone_Init()
{
	WarpZone_FindNearestOrigin = WarpZone_FindNearestOrigin_stub;
	WarpZone_RefSys_TransformAngles = WarpZone_RefSys_TransformAngles_stub;
	WarpZone_RefSys_BeginAddingIncrementally = WarpZone_RefSys_BeginAddingIncrementally_stub;
	WarpZone_RefSys_SpawnSameRefSys = WarpZone_RefSys_SpawnSameRefSys_stub;
	WarpZone_RefSys_AddIncrementally = WarpZone_RefSys_AddIncrementally_stub;
	WarpZone_RefSys_TransformOrigin = WarpZone_RefSys_TransformOrigin_stub;
	WarpZone_RefSys_TransformVelocity = WarpZone_RefSys_TransformVelocity_stub;
	WarpZone_FindRadius = WarpZone_FindRadius_stub;
	WarpZone_DrawEffectTriangle = WarpZone_DrawEffectTriangle_stub;
	WarpZone_TraceBox = trace_box;
	WarpZone_TraceLine = trace_line;
	WarpZone_TraceBox_ThroughZone = WarpZone_TraceBox_ThroughZone_stub;
	WarpZone_TraceLine_ThroughZone = WarpZone_TraceLine_ThroughZone_stub;
	WarpZone_UnTransformOrigin = WarpZone_UnTransformOrigin_stub;
	WarpZone_TransformOrigin = WarpZone_TransformOrigin_stub;
	WarpZone_TransformVelocity = WarpZone_TransformVelocity_stub;
	warpzone_chain_begin = world;
	WarpZone_InitHook();
}

void WarpZone_Enable()
{
	WarpZone_FindNearestOrigin = WarpZone_FindNearestOrigin_real;
	WarpZone_RefSys_TransformAngles = WarpZone_RefSys_TransformAngles_real;
	WarpZone_RefSys_BeginAddingIncrementally = WarpZone_RefSys_BeginAddingIncrementally_real;
	WarpZone_RefSys_SpawnSameRefSys = WarpZone_RefSys_SpawnSameRefSys_real;
	WarpZone_RefSys_AddIncrementally = WarpZone_RefSys_AddIncrementally_real;
	WarpZone_RefSys_TransformOrigin = WarpZone_RefSys_TransformOrigin_real;
	WarpZone_RefSys_TransformVelocity = WarpZone_RefSys_TransformVelocity_real;
	WarpZone_FindRadius = WarpZone_FindRadius_real;
	WarpZone_DrawEffectTriangle = WarpZone_DrawEffectTriangle_real;
	WarpZone_TraceBox = WarpZone_TraceBox_real;
	WarpZone_TraceLine = WarpZone_TraceLine_real;
	WarpZone_TraceBox_ThroughZone = WarpZone_TraceBox_ThroughZone_real;
	WarpZone_TraceLine_ThroughZone = WarpZone_TraceLine_ThroughZone_real;
	WarpZone_UnTransformOrigin = WarpZone_UnTransformOrigin_real;
	WarpZone_TransformOrigin = WarpZone_TransformOrigin_real;
	WarpZone_TransformVelocity = WarpZone_TransformVelocity_real;
	WarpZone_EnableHook();
}

void WarpZone_Shutdown()
{
	WarpZone_ShutdownHook();
}

void WarpZone_Sound(entity e, float chan, string sound_path, float vol, float attn) {
	sound(e, chan, sound_path, vol, attn);
	if (warpzone_sound_transition) {
		vector find_area = '1 1 1';
		find_area *= warpzone_sound_transition;
		entity wz = WarpZone_Find(e.origin - find_area, e.origin + find_area);
		if (wz) {
			entity e_transited = spawn();
			setorigin(e_transited, WarpZone_TransformOrigin(wz, e.origin));
			sound(e_transited, chan, sound_path, vol, attn);
			remove(e_transited);
		}
	}
}


#ifdef WZ_SLOW_FINDLOS

vector WarpZone_FindLineOfSight(vector fwd, vector viewer, vector viewee, float traceflag, entity traceent) {
    var wz = world;

    do {
        var viewee_warped = if(wz) WarpZone_UnTransformOrigin(wz, viewee) else viewee;
        var dir = normalize(viewee_warped - viewer);

        if(fwd != '0 0 0' && dir * fwd < 0)
            goto skip; // no eyes on our back

        WarpZone_TraceLine(viewer, viewee_warped, traceflag, traceent);

        if(vlen(trace_endpos - viewee) < 1) {
            // a line of sight exists
            return dir;
        }

    :skip
        if(wz) wz = wz.warpzone_chain;
        else   wz = warpzone_chain_begin;
    } while(wz);

    // can't see it at all
    return '0 0 0';
}

#else

vector WarpZone_FindLineOfSight(vector fwd, vector viewer, vector viewee, float traceflag, entity traceent) {
    var dir = normalize(viewee - viewer);
    var viewee_warped;

    // try a direct trace first

    if(fwd != '0 0 0' && dir * fwd < 0) {
        // no eyes on our back
    } else {
        WarpZone_TraceLine(viewer, viewee, traceflag, traceent);
        if(vlen(trace_endpos - viewee) < 1) {
            // a line of sight exists
            return dir;
        }
    }

    // failed, let's try the nearest warpzone

    var nearest_dst = 1250; // initialize with the maximum distance
    var nearest_wz;
    var nearest_wz_vw;
    var nearest_dir;

    for(var wz = warpzone_chain_begin; wz; wz = wz.warpzone_chain) {
        var org = wz.origin;
        if(org == '0 0 0')
            org = 0.5 * (wz.mins + wz.maxs);

        var dst = vlen(org - viewer);

        if(dst < nearest_dst) {
            viewee_warped = WarpZone_UnTransformOrigin(wz, viewee);
            dir = normalize(viewee_warped - viewer);

            if(fwd != '0 0 0' && dir * fwd < 0)
                continue; // no eyes on our back

            nearest_dst = dst;
            nearest_wz = wz;
            nearest_wz_vw = viewee_warped;
            nearest_dir = dir;
        }
    }

    if(nearest_wz) {
        WarpZone_TraceLine(viewer, nearest_wz_vw, traceflag, traceent);
        if(vlen(trace_endpos - viewee) < 1) {
            // a line of sight exists
            return nearest_dir;
        }
    }

    // nope, give up
    return '0 0 0';
}

#endif
