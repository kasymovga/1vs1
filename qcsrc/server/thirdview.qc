float(entity to, float f) thirdview_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_3RDVIEW);
	WriteShort(MSG_ENTITY, self.view_ofs_x);
	WriteShort(MSG_ENTITY, self.view_ofs_y);
	WriteCoord(MSG_ENTITY, self.delay - (time - self.cnt));
	return TRUE;
}

void(entity pl, float t, float back, float up) thirdview_set {
	entity e = spawn();
	e.cnt = time;
	e.owner = pl;
	e.delay = t;
	e.customizeentityforclient = weapon_model_customize;
	e.view_ofs_x = back;
	e.view_ofs_y = up;
	net_link_entity(e, 0, t, thirdview_send);
}
