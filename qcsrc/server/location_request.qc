float LocationRequest_CustomizeEntityForClient() {
	if not(other == self.owner)
		return FALSE;

	return TRUE;
}

float LocationRequest_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_LOCATION_REQUEST);
	WriteByte(MSG_ENTITY, sf & 255);
	if (sf & 1)
		WriteString(MSG_ENTITY, self.netname);

	return TRUE;
}

.entity location_request;
.void(float x, float y) location_request_callback;
void LocationRequest_Remove(entity plr) {
	if not(plr.location_request)
		return;

	remove(plr.location_request);
	plr.location_request = world;
}

void LocationRequest_Select(float x, float y) {
	if not(self.location_request)
		return;

	if (self.location_request.location_request_callback)
		self.location_request.location_request_callback(x, y);

	LocationRequest_Remove(self);
}

entity LocationRequest_Create(entity plr, string title, void(float x, float y)callback) {
	LocationRequest_Remove(plr);
	entity e = spawn();
	e.netname = title;
	e.owner = plr;
	e.location_request_callback = callback;
	e.customizeentityforclient = LocationRequest_CustomizeEntityForClient;
	plr.location_request = e;
	Net_LinkEntity(e, FALSE, 0, LocationRequest_SendEntity);
	return e;
}
