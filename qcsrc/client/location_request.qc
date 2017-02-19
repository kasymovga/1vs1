void LocationRequest_Remove() {
	location_request = world;
	strunzone(self.netname);
}

float LocationRequest_InputEvent(float bInputType, float nPrimary, float nSecondary) {
	if (bInputType != 0)
		return FALSE;

	if (nPrimary == K_MOUSE1) {
		vector loc;
		loc = teamradar_2dcoord_to_texcoord(mouse_pos);
		loc = teamradar_texcoord_to_3dcoord(loc);
		localcmd(strcat("\ncmd location_select ", ftos(loc_x), " ", ftos(loc_y), "\n"));
		return TRUE;
	}
	return FALSE;
}

void LocationRequest_Draw() {
	draw_crosshair = FALSE;
	sb_hidescores = TRUE;
	ons_showmap = FALSE;
	Mouse_Enable();
	CSQC_InputEvent_Callback = LocationRequest_InputEvent;
	teamradar_view(2, location_request.netname);
}

void Ent_LocationRequest(float ignore) {
	self.entremove = LocationRequest_Remove;
	float f = ReadByte();
	string title;
	if (f & 1)
		title = ReadString();

	self.netname = strzone(title);
	self.draw2d = LocationRequest_Draw;

	if (location_request) //already have one
		self.draw2d = draw2d_null;

	location_request = self;
}
