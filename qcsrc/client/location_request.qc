entity selected_location;

void LocationRequest_Remove() {
	strunzone(self.netname);
	if (self == selected_location)
		selected_location = world;

	self.teamradar_icon = 0;
}

float LocationRequest_InputEvent(float bInputType, float nPrimary, float nSecondary) {
	if (bInputType != 0)
		return FALSE;

	if (nPrimary == K_MOUSE1) {
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

void LocationRequest_Draw() {
	selected_location = self;
	sb_hidescores = TRUE;
	ons_showmap = FALSE;
	Mouse_Enable();
	CSQC_InputEvent_Callback = LocationRequest_InputEvent;
	teamradar_view(1.8, self.netname);
	self.chain = world;
}

void Ent_LocationRequest(float bNew) {
	self.entremove = LocationRequest_Remove;
	float f = ReadByte();
	string title;
	if (f & 1)
		title = ReadString();

	self.netname = strzone(title);
	self.draw2d = LocationRequest_Draw;
	self.draw2dflag = 1;
}
