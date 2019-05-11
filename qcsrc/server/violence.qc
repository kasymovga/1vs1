#define violence_gib_splash_send Violence_GibSplash_SendEntity
float(entity to, float sf) violence_gib_splash_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_GIBSPLASH);
	WriteByte(MSG_ENTITY, self.state); // actually type
	WriteByte(MSG_ENTITY, bound(1, self.cnt * 16, 255)); // gibbage amount multiplier
	WriteShort(MSG_ENTITY, floor(self.origin_x / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(MSG_ENTITY, floor(self.origin_y / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(MSG_ENTITY, floor(self.origin_z / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(MSG_ENTITY, self.oldorigin_x); // acrually compressed velocity
	return TRUE;
}

// TODO maybe convert this to a TE?
void(vector org, vector dir, float type, float amount, entity gibowner, entity attacker) violence_gib_splash_at {
	entity e;
	e = spawn();
	e.classname = "gibsplash";
	e.cnt = amount;
	e.state = type; // should stay smaller than 15
	e.state |= 8 * self.species; // gib type, ranges from 0 to 15
	setorigin(e, org);
	e.velocity = dir;
	e.oldorigin_x = compressShortVector(e.velocity);
	Net_LinkEntity(e, FALSE, 0.2, violence_gib_splash_send);
}

void(entity source, float type, float amount, entity attacker) violence_gib_splash {
	violence_gib_splash_at(source.origin + source.view_ofs, source.velocity, type, amount, source, attacker);
}
