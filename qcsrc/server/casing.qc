float g_casings;

float(entity to, float sf) casing_send {
	WriteByte(MSG_ENTITY, NET_CSQC_CASING);
	WriteByte(MSG_ENTITY, self.state); // actually type
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	WriteShort(MSG_ENTITY, self.oldorigin_x); // acrually compressed velocity
	WriteByte(MSG_ENTITY, self.angles_x * 256 / 360);
	WriteByte(MSG_ENTITY, self.angles_y * 256 / 360);
	WriteByte(MSG_ENTITY, self.angles_z * 256 / 360);
	return TRUE;
}

void(vector vel, float randomvel, vector ang, vector avel, float randomavel, float casingtype, entity casingowner) casing_spawn {
	if (casingtype > g_casings)
		return;

	entity e;
	vector org;
	org = self.origin + self.view_ofs + self.weaponentity.spawnorigin_x * v_forward - self.weaponentity.spawnorigin_y * v_right + self.weaponentity.spawnorigin_z * v_up;
	e = spawn();
	e.state = casingtype;
	setorigin(e, org);
	e.velocity = vel;
	e.angles = ang;
	e.oldorigin_x = net_compress_vec(e.velocity);
	net_link_entity(e, TRUE, 0.2, casing_send); // 0.2s should be enough time for all clients to receive this ent once, do the gibbage and be done with it
}

void(void) casing_init {
	CVAR_CACHE(g_casings);
}
