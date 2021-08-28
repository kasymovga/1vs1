entity selected_location;

void(void) locationrequest_remove {
	str_unzone_ifneeded(self.netname);
	if (self == selected_location)
		selected_location = world;

	self.teamradar_icon = 0;
}

float locationrequest_input_event(float input_type, float primary, float secondary) {
	if (input_type != 0)
		return FALSE;

	if (primary == K_MOUSE1) {
		vector loc;
		loc = teamradar_2dcoord_to_texcoord(mouse_position());
		loc = teamradar_texcoord_to_3dcoord(loc);
		if (selected_location) {
			selected_location.teamradar_icon = 1;
			selected_location.origin = loc;
			selected_location.alpha = 1;
			selected_location.teamradar_color = '0 1 1';
			selected_location.teamradar_times[0] = time;
		}
		localcmd(strcat("\ncmd location_select ", ftos(loc_x), " ", ftos(loc_y), "\n"));
		return TRUE;
	}
	return FALSE;
}

void(void) locationrequest_draw {
	view_crosshair = FALSE;
	selected_location = self;
	sbar_hidescores = TRUE;
	teamradar_show = FALSE;
	mouse_enable("");
	input_event_callback = locationrequest_input_event;
	teamradar_view(1.8, self.netname);
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
	self.draw2dflag = 1;
}
