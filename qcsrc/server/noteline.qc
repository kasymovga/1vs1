float NoteLine_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_NOTELINE);
	other = to;
	self.touch();
	WriteString(MSG_ENTITY, self.message);
	return TRUE;
}

entity NoteLine_New(void() msggen) {
	entity e = spawn();
	e.touch = msggen;
	Net_LinkEntity(e, FALSE, 0, NoteLine_SendEntity);
	return e;
}
