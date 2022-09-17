float g_casings;

void(vector vel, float randomvel, vector ang, vector avel, float randomavel, float casingtype, entity casingowner) casing_spawn {
	if (casingtype > g_casings)
		return;

	vector org;
	org = self.origin + self.view_ofs + self.weaponentity.spawnorigin_x * v_forward - self.weaponentity.spawnorigin_y * v_right + self.weaponentity.spawnorigin_z * v_up;
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_CASING);
	net_write_byte(MSG_BROADCAST, casingtype); // actually type
	net_write_coord(MSG_BROADCAST, org_x);
	net_write_coord(MSG_BROADCAST, org_y);
	net_write_coord(MSG_BROADCAST, org_z);
	net_write_short(MSG_BROADCAST, net_compress_vec(vel)); // acrually compressed velocity
	net_write_byte(MSG_BROADCAST, ang_x * 256 / 360);
	net_write_byte(MSG_BROADCAST, ang_y * 256 / 360);
	net_write_byte(MSG_BROADCAST, ang_z * 256 / 360);
}

void(void) casing_init {
	CVAR_CACHE(g_casings);
}
