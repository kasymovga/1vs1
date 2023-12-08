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
