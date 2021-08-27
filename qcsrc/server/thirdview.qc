float(entity to, float f) thirdview_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_3RDVIEW);
	net_write_short(MSG_ENTITY, self.view_ofs_x);
	net_write_short(MSG_ENTITY, self.view_ofs_y);
	net_write_coord(MSG_ENTITY, self.delay - (time - self.cnt));
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
