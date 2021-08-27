float g_casings;

float(entity to, float sf) casing_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_CASING);
	net_write_byte(MSG_ENTITY, self.state); // actually type
	net_write_coord(MSG_ENTITY, self.origin_x);
	net_write_coord(MSG_ENTITY, self.origin_y);
	net_write_coord(MSG_ENTITY, self.origin_z);
	net_write_short(MSG_ENTITY, self.oldorigin_x); // acrually compressed velocity
	net_write_byte(MSG_ENTITY, self.angles_x * 256 / 360);
	net_write_byte(MSG_ENTITY, self.angles_y * 256 / 360);
	net_write_byte(MSG_ENTITY, self.angles_z * 256 / 360);
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
