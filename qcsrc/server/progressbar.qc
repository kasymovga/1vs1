float(void) progressbar_customize {
	if not(other == self.owner)
		return FALSE;

	return TRUE;
}

float(entity to, float sf) progressbar_send {
	WriteByte(MSG_ENTITY, NET_CSQC_PROGRESSBAR);
	sf = sf & 127;
	WriteByte(MSG_ENTITY, sf);
	WriteByte(MSG_ENTITY, rint(self.cnt * 100));
	if (sf & 2) {
		WriteString(MSG_ENTITY, self.netname);
	}
	return TRUE;
}

entity(string name, entity plr) progressbar_create {
	entity e = spawn();
	net_link_entity(e, FALSE, 0, progressbar_send);
	e.netname = name;
	if (plr)
		e.customizeentityforclient = progressbar_customize;

	e.owner = plr;
	return e;
}

void(entity pb, float value) progressbar_set {
	pb.cnt = bound(0, value, 1);
	pb.SendFlags = 1;
}
