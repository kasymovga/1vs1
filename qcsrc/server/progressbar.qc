float ProgressBar_CustomizeEntityForClient() {
	if not(other == self.owner)
		return FALSE;

	return TRUE;
}

float ProgressBar_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_PROGRESSBAR);
	sf = sf & 127;
	WriteByte(MSG_ENTITY, sf);
	WriteByte(MSG_ENTITY, rint(self.cnt * 100));
	if (sf & 2) {
		WriteString(MSG_ENTITY, self.netname);
	}
	return TRUE;
}

entity ProgressBar_Create(string name, entity plr) {
	entity e = spawn();
	net_link_entity(e, FALSE, 0, ProgressBar_SendEntity);
	e.netname = name;
	if (plr)
		e.customizeentityforclient = ProgressBar_CustomizeEntityForClient;

	e.owner = plr;
	return e;
}

void ProgressBar_SetValue(entity pb, float value) {
	pb.cnt = bound(0, value, 1);
	pb.SendFlags = 1;
}
