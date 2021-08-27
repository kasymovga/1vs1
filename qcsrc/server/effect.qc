void(vector from,vector to) effect_lightningarc {
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_LIGHTNINGARC);
	net_write_coord(MSG_BROADCAST, from_x);
	net_write_coord(MSG_BROADCAST, from_y);
	net_write_coord(MSG_BROADCAST, from_z);
	net_write_coord(MSG_BROADCAST, to_x);
	net_write_coord(MSG_BROADCAST, to_y);
	net_write_coord(MSG_BROADCAST, to_z);
}

void(vector loc) effect_blast {
    net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
    net_write_byte(MSG_BROADCAST, NET_TE_CSQC_BLAST);
    net_write_coord(MSG_BROADCAST, loc_x);
    net_write_coord(MSG_BROADCAST, loc_y);
    net_write_coord(MSG_BROADCAST, loc_z);
}

float effect_curveparticles_effectno;
vector effect_curveparticles_start;
float effect_curveparticles_spd;

void() effect_curveparticles_end {
	if (effect_curveparticles_effectno) // terminator
		net_write_short(MSG_BROADCAST, effect_curveparticles_spd | 0x8000);

	effect_curveparticles_effectno = 0;
}

void(float effectno, vector start, vector end, float end_dz, float spd) effect_curveparticles {
	spd = bound(0, floor(spd / 16), 32767);
	if (effectno != effect_curveparticles_effectno || start != effect_curveparticles_start) {
		effect_curveparticles_end();
		net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
		net_write_byte(MSG_BROADCAST, NET_TE_CSQC_ZCURVEPARTICLES);
		net_write_short(MSG_BROADCAST, effectno);
		net_write_coord(MSG_BROADCAST, start_x);
		net_write_coord(MSG_BROADCAST, start_y);
		net_write_coord(MSG_BROADCAST, start_z);
		effect_curveparticles_effectno = effectno;
		effect_curveparticles_start = start;
	} else
		net_write_short(MSG_BROADCAST, effect_curveparticles_spd);

	net_write_coord(MSG_BROADCAST, end_x);
	net_write_coord(MSG_BROADCAST, end_y);
	net_write_coord(MSG_BROADCAST, end_z);
	net_write_coord(MSG_BROADCAST, end_dz);
	effect_curveparticles_spd = spd;
}

void(float effectno, vector start, vector end, vector vel) effect_curveparticles_from_tracetoss {
	float end_dz;
	vector vecxy, velxy;
	vecxy = end - start;
	vecxy_z = 0;
	velxy = vel;
	velxy_z = 0;
	if (vlen(velxy) < 0.000001 * fabs(vel_z)) {
		end_dz = 0;
	} else
		end_dz = vlen(vecxy) / vlen(velxy) * vel_z - (end_z - start_z);

	effect_curveparticles(effectno, start, end, end_dz, vlen(vel));
}

float(entity to, float sf) effect_model_send {
	float f;
	net_write_byte(MSG_ENTITY, NET_CSQC_MODELEFFECT);
	f = 0;
	if (self.velocity != '0 0 0')
		f |= 1;

	if (self.angles != '0 0 0')
		f |= 2;

	if (self.avelocity != '0 0 0')
		f |= 4;

	net_write_byte(MSG_ENTITY, f);
	net_write_short(MSG_ENTITY, self.modelindex);
	net_write_byte(MSG_ENTITY, self.skin);
	net_write_byte(MSG_ENTITY, self.frame);
	net_write_coord(MSG_ENTITY, self.origin_x);
	net_write_coord(MSG_ENTITY, self.origin_y);
	net_write_coord(MSG_ENTITY, self.origin_z);
	if (f & 1) {
		net_write_coord(MSG_ENTITY, self.velocity_x);
		net_write_coord(MSG_ENTITY, self.velocity_y);
		net_write_coord(MSG_ENTITY, self.velocity_z);
	}
	if (f & 2) {
		net_write_coord(MSG_ENTITY, self.angles_x);
		net_write_coord(MSG_ENTITY, self.angles_y);
		net_write_coord(MSG_ENTITY, self.angles_z);
	}
	if (f & 4) {
		net_write_coord(MSG_ENTITY, self.avelocity_x);
		net_write_coord(MSG_ENTITY, self.avelocity_y);
		net_write_coord(MSG_ENTITY, self.avelocity_z);
	}
	net_write_short(MSG_ENTITY, self.scale * 256.0);
	net_write_short(MSG_ENTITY, self.dmg * 256.0);
	net_write_byte(MSG_ENTITY, self.teleport_time * 100.0);
	net_write_byte(MSG_ENTITY, self.fade_time * 100.0);
	net_write_byte(MSG_ENTITY, self.alpha * 255.0);
	return TRUE;
}

void(string m, float s, float f, vector o, vector v, vector ang, vector angv, float s0, float s2, float a, float t1, float t2) effect_model_spawn {
	entity e;
	float sz;
	e = spawn();
	e.classname = "modeleffect";
	setmodel(e, m);
	e.frame = f;
	setorigin(e, o);
	e.velocity = v;
	e.angles = ang;
	e.avelocity = angv;
	e.alpha = a;
	e.teleport_time = t1;
	e.fade_time = t2;
	e.skin = s;
	if (s0 >= 0)
		e.scale = s0 / max6(-e.mins_x, -e.mins_y, -e.mins_z, e.maxs_x, e.maxs_y, e.maxs_z);
	else
		e.scale = -s0;

	if (s2 >= 0)
		e.dmg = s2 / max6(-e.mins_x, -e.mins_y, -e.mins_z, e.maxs_x, e.maxs_y, e.maxs_z);
	else
		e.dmg = -s2;

	sz = max(e.scale, e.dmg);
	setsize(e, e.mins * sz, e.maxs * sz);
	net_link_entity(e, FALSE, 0.1, effect_model_send);
}

void(string m, vector org, float sz, float t1, float t2) effect_shockwave_spawn {
	return effect_model_spawn(m, 0, 0, org, '0 0 0', '0 0 0', '0 0 0', 0, sz, 1, t1, t2);
}
