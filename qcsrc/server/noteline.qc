#define noteline_send NoteLine_SendEntity //compatibility with save files
float noteline_send(entity to, float sf) {
	WriteByte(MSG_ENTITY, NET_CSQC_NOTELINE);
	other = to;
	self.touch();
	WriteString(MSG_ENTITY, self.message);
	return TRUE;
}

entity(void() msggen) noteline_new {
	entity e = spawn();
	e.touch = msggen;
	net_link_entity(e, FALSE, 0, NoteLine_SendEntity);
	return e;
}
