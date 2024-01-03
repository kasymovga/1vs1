void(entity to, vector o, float _damage, float admg) rm_damage_indicator {
	if (clienttype(to) != CLIENTTYPE_REAL) return;
	if not(checkpvs(o, to)) {
		return;
	}
	float otf = trace_fraction;
	entity ote = trace_ent;
	vector otep = trace_endpos;
	vector otpn = trace_plane_normal;
	float otss = trace_startsolid;
	trace_line(to.origin + to.view_ofs, o, TRACE_MOVE_NOMONSTERS, to);
	float cansee = (trace_fraction == 1);
	trace_fraction = otf;
	trace_ent = ote;
	trace_endpos = otep;
	trace_plane_normal = otpn;
	trace_startsolid = otss;
	if not(cansee) {
		return;
	}
	msg_entity = to;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_DAMAGE_INDICATOR);
	net_write_short(MSG_ONE, o_x);
	net_write_short(MSG_ONE, o_y);
	net_write_short(MSG_ONE, o_z);
	net_write_short(MSG_ONE, _damage * 10 + 0.5);
	net_write_short(MSG_ONE, admg * 10 + 0.5);
}
