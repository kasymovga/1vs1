float(entity to, float sf) effect_impact_send {
	return TRUE;
}

void(vector org, float coredamage, float edgedamage, float rad, vector force, float impacttype, entity dmgowner) effect_impact {
	if not(impacttype) return;
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_EFFECT_IMPACT);
	net_write_short(MSG_BROADCAST, impacttype);
	net_write_coord(MSG_BROADCAST, floor(org_x));
	net_write_coord(MSG_BROADCAST, floor(org_y));
	net_write_coord(MSG_BROADCAST, floor(org_z));
	net_write_short(MSG_BROADCAST, net_compress_vec(force));
	net_write_byte(MSG_BROADCAST, (team_mode ? dmgowner.team : 0));
}

