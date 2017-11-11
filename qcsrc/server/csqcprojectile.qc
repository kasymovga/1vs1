.float csqcprojectile_type;
.float csqcprojectile_sendangles;

float CSQCProjectile_SendEntity(entity to, float sf)
{
	// note: flag 32 = no trail please
	sf = sf & 63;

	if(self.csqcprojectile_clientanimate) {
        sf &~= 4;
		sf |= 128; // client animated, not interpolated
    } else if(!self.csqcprojectile_sendangles) {
        sf &~= 4;
    }

	if(self.flags & FL_ONGROUND) {
		sf |= 64;
	}

	if(self.team <= 0) {
		sf &~= 16;
	}

	WriteByte(MSG_ENTITY, ENT_CLIENT_PROJECTILE);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);

		if(sf & 128)
		{
			WriteCoord(MSG_ENTITY, self.velocity_x);
			WriteCoord(MSG_ENTITY, self.velocity_y);
			WriteCoord(MSG_ENTITY, self.velocity_z);
			WriteCoord(MSG_ENTITY, self.gravity);
		}
	}

	if(sf & 2) {
		WriteByte(MSG_ENTITY, self.csqcprojectile_type); // TODO maybe put this into sf?
		if(sf & 16)
			WriteChar(MSG_ENTITY, self.team);
	}

    if(sf & 4) {
        WriteCoord(MSG_ENTITY, self.angles_x);
        WriteCoord(MSG_ENTITY, self.angles_y);
        WriteCoord(MSG_ENTITY, self.angles_z);
    }

	return 1;
}

.vector csqcprojectile_oldorigin;
void CSQCProjectile_Check(entity e)
{
	if(e.csqcprojectile_clientanimate)
	if(e.flags & FL_ONGROUND)
	if(e.origin != e.csqcprojectile_oldorigin)
		UpdateCSQCProjectile(e);
	e.csqcprojectile_oldorigin = e.origin;
}

void CSQCProjectile_Init(float type) {
	vector sizes;
	sizes = '0 0 0';
	switch (type) {
	case PROJECTILE_FIREBALL:
		sizes = '12 -12 12';
		break;
	case PROJECTILE_FIREMINE:
		sizes = '4 -4 4';
		break;
	case PROJECTILE_ROCKET:
		sizes = stov(cvar_string("sv_projectile_rocket_size"));
		break;
	case PROJECTILE_ELECTRO:
	case PROJECTILE_GRENADE_BOUNCING:
	case PROJECTILE_HG_NAPALMSHARD:
		sizes = '0 -3 -3';
		break;
	}
	ProjInfo_RegisterAuto(type, sizes);
}

entity CSQCProjectile(float clientanimate, float type, float docull)
{
	entity e = spawn();
	ProjInfo_SetSize(e, type);
	Net_LinkEntity(e, docull, 0, CSQCProjectile_SendEntity);

	e.csqcprojectile_clientanimate = clientanimate;

	e.csqcprojectile_type = type;
	if(!sound_allowed(MSG_BROADCAST, e))
		type |= 0x80;

	e.flags = FL_PROJECTILE;
	return e;
}

void UpdateCSQCProjectile(entity e)
{
	if(e.SendEntity == CSQCProjectile_SendEntity)
	{
		// send new origin data
		e.SendFlags |= 1;
	}
}

void UpdateCSQCProjectileAngles(entity e)
{
    if(e.SendEntity == CSQCProjectile_SendEntity)
    {
        // send new angles data (does nothing in predictive mode)
        e.SendFlags |= 4;
        e.csqcprojectile_sendangles = TRUE;
    }
}

void UpdateCSQCProjectileAfterTeleport(entity e)
{
	if(e.SendEntity == CSQCProjectile_SendEntity)
	{
		// send new origin data and mark as teleported
		e.SendFlags |= 0x21;
	}
}

.void(void) csqcprojectile_oldthink;
.float csqcprojectile_oldnextthink;

void CSQCProjectile_Update_Think()
{
	UpdateCSQCProjectile(self);
	self.think = self.csqcprojectile_oldthink;
	self.nextthink = max(time, self.csqcprojectile_oldnextthink);
}

void UpdateCSQCProjectileNextFrame(entity e)
{
	if(e.SendEntity == CSQCProjectile_SendEntity)
	if(e.think != CSQCProjectile_Update_Think)
	{
		e.csqcprojectile_oldthink = e.think;
		e.csqcprojectile_oldnextthink = e.nextthink;
		e.think = CSQCProjectile_Update_Think;
		e.nextthink = time;
	}
}

void ProjInfo_Send(void) {
	float i;

	WriteByte(MSG_ENTITY, projinfo_highest_registered);

	for(i = 0; i < projinfo_highest_registered; ++i) {
		float type = projinfo_type[i];

		WriteByte(MSG_ENTITY, type);
		float sizes;
		switch(type) {
			case PROJINFO_TYPE_UNREGISTERED:
			case PROJINFO_TYPE_POINT_000:
			case PROJINFO_TYPE_POINT_00n3:
				break;

			case PROJINFO_TYPE_UNCENTERED:
			case PROJINFO_TYPE_POINT:
			case PROJINFO_TYPE_CENTERED:
				WriteCoord(MSG_ENTITY, projinfo_sizes[i]);
				break;

			default: {
				error(strcat("Invalid ProjInfo type ", ftos(type)));
			}
		}
	}
}
