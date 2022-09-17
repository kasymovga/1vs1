void(vector org, vector dir, float type, float amount, entity gibowner, entity attacker) violence_gib_splash_at {
	type |= 8 * self.species; // gib type, ranges from 0 to 15
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_GIBSPLASH);
	net_write_byte(MSG_BROADCAST, type); // actually type
	net_write_byte(MSG_BROADCAST, bound(1, amount * 16, 255)); // gibbage amount multiplier
	net_write_short(MSG_BROADCAST, floor(org_x / 4)); // not using a coord here, as gibs don't need this accuracy
	net_write_short(MSG_BROADCAST, floor(org_y / 4)); // not using a coord here, as gibs don't need this accuracy
	net_write_short(MSG_BROADCAST, floor(org_z / 4)); // not using a coord here, as gibs don't need this accuracy
	net_write_short(MSG_BROADCAST, net_compress_vec(dir)); // acrually compressed velocity
}

void(entity source, float type, float amount, entity attacker) violence_gib_splash {
	violence_gib_splash_at(source.origin + source.view_ofs, source.velocity, type, amount, source, attacker);
}
