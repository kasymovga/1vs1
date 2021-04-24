void(vector from,vector to) effect_lightningarc {
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_LIGHTNINGARC);
	WriteCoord(MSG_BROADCAST, from_x);
	WriteCoord(MSG_BROADCAST, from_y);
	WriteCoord(MSG_BROADCAST, from_z);
	WriteCoord(MSG_BROADCAST, to_x);
	WriteCoord(MSG_BROADCAST, to_y);
	WriteCoord(MSG_BROADCAST, to_z);
}

void(vector loc) effect_blast {
    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_CSQC_BLAST);
    WriteCoord(MSG_BROADCAST, loc_x);
    WriteCoord(MSG_BROADCAST, loc_y);
    WriteCoord(MSG_BROADCAST, loc_z);
}

float effect_curveparticles_effectno;
vector effect_curveparticles_start;
float effect_curveparticles_spd;

void() effect_curveparticles_end {
	if (effect_curveparticles_effectno) // terminator
		WriteShort(MSG_BROADCAST, effect_curveparticles_spd | 0x8000);

	effect_curveparticles_effectno = 0;
}

void(float effectno, vector start, vector end, float end_dz, float spd) effect_curveparticles {
	spd = bound(0, floor(spd / 16), 32767);
	if (effectno != effect_curveparticles_effectno || start != effect_curveparticles_start) {
		effect_curveparticles_end();
		WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte(MSG_BROADCAST, TE_CSQC_ZCURVEPARTICLES);
		WriteShort(MSG_BROADCAST, effectno);
		WriteCoord(MSG_BROADCAST, start_x);
		WriteCoord(MSG_BROADCAST, start_y);
		WriteCoord(MSG_BROADCAST, start_z);
		effect_curveparticles_effectno = effectno;
		effect_curveparticles_start = start;
	} else
		WriteShort(MSG_BROADCAST, effect_curveparticles_spd);

	WriteCoord(MSG_BROADCAST, end_x);
	WriteCoord(MSG_BROADCAST, end_y);
	WriteCoord(MSG_BROADCAST, end_z);
	WriteCoord(MSG_BROADCAST, end_dz);
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
	WriteByte(MSG_ENTITY, ENT_CLIENT_MODELEFFECT);
	f = 0;
	if (self.velocity != '0 0 0')
		f |= 1;

	if (self.angles != '0 0 0')
		f |= 2;

	if (self.avelocity != '0 0 0')
		f |= 4;

	WriteByte(MSG_ENTITY, f);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteByte(MSG_ENTITY, self.skin);
	WriteByte(MSG_ENTITY, self.frame);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	if (f & 1) {
		WriteCoord(MSG_ENTITY, self.velocity_x);
		WriteCoord(MSG_ENTITY, self.velocity_y);
		WriteCoord(MSG_ENTITY, self.velocity_z);
	}
	if (f & 2) {
		WriteCoord(MSG_ENTITY, self.angles_x);
		WriteCoord(MSG_ENTITY, self.angles_y);
		WriteCoord(MSG_ENTITY, self.angles_z);
	}
	if (f & 4) {
		WriteCoord(MSG_ENTITY, self.avelocity_x);
		WriteCoord(MSG_ENTITY, self.avelocity_y);
		WriteCoord(MSG_ENTITY, self.avelocity_z);
	}
	WriteShort(MSG_ENTITY, self.scale * 256.0);
	WriteShort(MSG_ENTITY, self.dmg * 256.0);
	WriteByte(MSG_ENTITY, self.teleport_time * 100.0);
	WriteByte(MSG_ENTITY, self.fade_time * 100.0);
	WriteByte(MSG_ENTITY, self.alpha * 255.0);
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
