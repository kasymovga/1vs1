vector(vector org, vector torg, float ht) trigger_push_calculate_velocity {
	float sdist, zdist, vs, vz;
	vector sdir;
	ht = max(ht, org_z - torg_z + sv_gravity * 0.05);
	zdist = torg_z - org_z + ht;
	sdist = vlen(torg - org - fabs(zdist) * '0 0 1');
	sdir = normalize(torg - org - zdist * '0 0 1');
	float t1 = sqrt(zdist / (0.5 * sv_gravity));
	float t2 = sqrt(ht / (0.5 * sv_gravity));
	if (torg_z > org_z)
		vz = t1 * sv_gravity;
	else
		vz = t2 * sv_gravity;

	trigger_push_calculate_velocity_flighttime = t1 + t2;
	vs = sdist / trigger_push_calculate_velocity_flighttime;
	return sdir * vs + '0 0 1' * vz;
}

#define TRIGGER_PUSH_VELOCITY_PLAYERDIR_XY 1
#define TRIGGER_PUSH_VELOCITY_ADD_XY 2
#define TRIGGER_PUSH_VELOCITY_PLAYERDIR_Z 4
#define TRIGGER_PUSH_VELOCITY_ADD_Z 8

vector(vector ov, vector org, vector torg, float ht, float _speed, float _spawnflags, float _count) trigger_push_velocity_calculate_velocity {
	vector v1, v2;
	if (_spawnflags & TRIGGER_PUSH_VELOCITY_PLAYERDIR_XY) {
		v1 = ov;
		v1_z = 0;
		v1 = _speed * normalize(v1);
	} else {
		v1 = trigger_push_calculate_velocity(org, torg, ht);
	}
	v2_x = v1_x;
	v2_y = v1_y;
	if (_spawnflags & TRIGGER_PUSH_VELOCITY_PLAYERDIR_Z) {
		v1 = _count * '0 0 1';
	} else {
		v1 = trigger_push_calculate_velocity(org, torg, ht);
	}
	v2_z = v1_z;
	if (_spawnflags & TRIGGER_PUSH_VELOCITY_ADD_XY) {
		ov_x = ov_x + v2_x * frametime;
		ov_y = ov_y + v2_y * frametime;
	} else {
		ov_x = v2_x;
		ov_y = v2_y;
	}
	if (_spawnflags & TRIGGER_PUSH_VELOCITY_ADD_Z) {
		ov_z = other.velocity_z + v2_z * frametime;
	} else {
		ov_z = v2_z;
	}
	return ov;
}
