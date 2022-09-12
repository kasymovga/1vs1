float(entity to, float sf) effect_impact_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_EFFECT_IMPACT);
	net_write_short(MSG_ENTITY, self.projectiledeathtype);
	net_write_coord(MSG_ENTITY, floor(self.origin_x));
	net_write_coord(MSG_ENTITY, floor(self.origin_y));
	net_write_coord(MSG_ENTITY, floor(self.origin_z));
	net_write_short(MSG_ENTITY, self.oldorigin_x);
	net_write_byte(MSG_ENTITY, self.team);
	return TRUE;
}

void(vector org, float coredamage, float edgedamage, float rad, vector force, float impacttype, entity dmgowner) effect_impact {
	if not(impacttype) return;
	entity e;
	e = spawn();
	setorigin(e, org);
	e.projectiledeathtype = impacttype;
	e.oldorigin_x = net_compress_vec(force);
	if (team_mode) {
		e.team = dmgowner.team;
	}
	net_link_entity(e, FALSE, 0.2, effect_impact_send);
}

