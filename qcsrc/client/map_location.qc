entity map_location_selected;

void(void) map_location_request_remove {
	str_unzone_ifneeded(self.netname);
	if (self == map_location_selected)
		map_location_selected = NULL;

	self.radar_icon = 0;
}

float map_location_request_input_event(float input_type, float primary, float secondary) {
	if (input_type != 0 || main_isdemo)
		return FALSE;

	if (primary == K_MOUSE1) {
		vector loc;
		loc = radar_2dcoord_to_texcoord(mouse_position());
		loc = radar_texcoord_to_3dcoord(loc);
		if (map_location_selected) {
			map_location_selected.radar_icon = 1;
			map_location_selected.origin = loc;
			map_location_selected.alpha = 1;
			map_location_selected.radar_color = '0 1 1';
			radar_ping(loc);
		}
		localcmd(strcat("\ncmd location_select ", ftos(loc_x), " ", ftos(loc_y), "\n"));
		return TRUE;
	}
	return FALSE;
}

void(void) map_location_request_draw {
	map_location_selected = self;
	radar_show = FALSE;
	mouse_enable("");
	input_event_callback = map_location_request_input_event;
	radar_view(1.8, self.netname);
	self.chain = NULL;
}

void(float bNew) map_location_request_read {
	self.entremove = map_location_request_remove;
	float f = net_read_byte();
	if (f & 1) {
		str_unzone_ifneeded(self.netname);
		self.netname = str_zone_ifneeded(net_read_string());
	}
	self.draw2d = map_location_request_draw;
	self.draw2dflag = 3;
}
