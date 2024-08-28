entity selected_location;

void(void) locationrequest_remove {
	str_unzone_ifneeded(self.netname);
	if (self == selected_location)
		selected_location = world;

	self.radar_icon = 0;
}

float locationrequest_input_event(float input_type, float primary, float secondary) {
	if (input_type != 0 || main_isdemo)
		return FALSE;

	if (primary == K_MOUSE1) {
		vector loc;
		loc = radar_2dcoord_to_texcoord(mouse_position());
		loc = radar_texcoord_to_3dcoord(loc);
		if (selected_location) {
			selected_location.radar_icon = 1;
			selected_location.origin = loc;
			selected_location.alpha = 1;
			selected_location.radar_color = '0 1 1';
			selected_location.radar_times[0] = time;
		}
		localcmd(strcat("\ncmd location_select ", ftos(loc_x), " ", ftos(loc_y), "\n"));
		return TRUE;
	}
	return FALSE;
}

void(void) locationrequest_draw {
	selected_location = self;
	radar_show = FALSE;
	mouse_enable("");
	input_event_callback = locationrequest_input_event;
	radar_view(1.8, self.netname);
	self.chain = world;
}

void(float bNew) locationrequest_read {
	self.entremove = locationrequest_remove;
	float f = net_read_byte();
	if (f & 1) {
		str_unzone_ifneeded(self.netname);
		self.netname = str_zone_ifneeded(net_read_string());
	}
	self.draw2d = locationrequest_draw;
	self.draw2dflag = 3;
}
