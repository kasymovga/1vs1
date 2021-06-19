float NoteLine_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, NET_CSQC_NOTELINE);
	other = to;
	self.touch();
	WriteString(MSG_ENTITY, self.message);
	return TRUE;
}

entity NoteLine_New(void() msggen) {
	entity e = spawn();
	e.touch = msggen;
	net_link_entity(e, FALSE, 0, NoteLine_SendEntity);
	return e;
}
