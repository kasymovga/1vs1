.float silent;
float casing_count;
entity casing_latest;
entity casing_oldest;

void Casing_Delete()
{
	if (self == casing_oldest)
		casing_oldest = self.entchain;

	if (self == casing_latest)
		casing_latest = self.entchain_back;

	if (self.entchain)
		self.entchain.entchain_back = self.entchain_back;

	if (self.entchain_back)
		self.entchain_back.entchain = self.entchain;

    remove(self);
	casing_count--;
}

void Casing_Draw()
{
	if(self.move_flags & FL_ONGROUND)
	{
		self.move_angles_x = 0;
		self.move_angles_z = 0;
		self.flags &~= FL_ONGROUND;
	}

	Movetype_Physics_NoMatchServer();

	self.renderflags = 0;
	self.alpha = bound(0, self.cnt - time, 1);

	if(self.alpha < ALPHA_MIN_VISIBLE)
		Casing_Delete();
	else
		R_AddEntity(self);
}

void Casing_Touch()
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		Casing_Delete();
		return;
	}

	if(!self.silent)
	if(!trace_ent || trace_ent.solid == SOLID_BSP)
	{
		if(vlen(self.velocity) > 50)
		{
			if(time >= self.nextthink)
			{
				string s;
				float f;

				f = floor(prandom() * 3) + 1;
				switch(self.state)
				{
					case 1:
						s = strcat("weapons/casings", ftos(f), ".wav");
						break;
					default:
						s = strcat("weapons/brass", ftos(f), ".wav");
						break;
				}

				sound (self, CHAN_PROJECTILE, s, VOL_BASE, ATTN_NORM);
			}
		}
	}

	self.nextthink = time + 0.2;
}

void Ent_Casing(float isNew)
{
	entity casing = spawn();
	casing.classname= "casing";
	casing.state = ReadByte();
	casing.silent = (casing.state & 0x80);
	casing.state = (casing.state & 0x7F);
	casing.origin_x = ReadCoord();
	casing.origin_y = ReadCoord();
	casing.origin_z = ReadCoord();
	casing.velocity = decompressShortVector(ReadShort());
	casing.angles_x = ReadByte() * 360 / 256;
	casing.angles_y = ReadByte() * 360 / 256;
	casing.angles_z = ReadByte() * 360 / 256;

	if(CVAR(cl_casings) && isNew) {
		if not(casing_oldest)
			casing_oldest = casing;

		if (casing_latest)
			casing_latest.entchain = casing;

		casing.entchain_back = casing_latest;
		casing_latest = casing;
		casing_count++;

		casing.draw = Casing_Draw;
		casing.move_origin = casing.origin;
		casing.move_velocity = casing.velocity + 2 * prandomvec();
		casing.move_angles = casing.angles;
		casing.move_avelocity = '0 250 0' + 100 * prandomvec();
		casing.move_movetype = MOVETYPE_BOUNCE;
		casing.move_touch = Casing_Touch;
		casing.move_time = time;
		casing.solid = SOLID_TRIGGER;

		switch(casing.state)
		{
			case 1:
				setmodel(casing, "models/casing_shell.mdl");
				casing.cnt = time + CVAR(cl_casings_shell_time);
				break;
			default:
				setmodel(casing, "models/casing_bronze.mdl");
				casing.cnt = time + CVAR(cl_casings_bronze_time);
				break;
		}

		setsize(casing, '0 0 -1', '0 0 -1');
	}
    else
        remove(casing);

	if (casing_count > CVAR_OR(cl_casings_maxcount, 100)) {
		entity oldself = self;
		self = casing_oldest;
		Casing_Delete();
		self = oldself;
	}
	//RubbleLimit("casing", CVAR_OR(cl_casings_maxcount, 100), Casing_Delete);
}

void Casings_Precache()
{
	precache_model("models/casing_shell.mdl");
	precache_model("models/casing_bronze.mdl");
	precache_sound("weapons/brass1.wav");
	precache_sound("weapons/brass2.wav");
	precache_sound("weapons/brass3.wav");
	precache_sound("weapons/casings1.wav");
	precache_sound("weapons/casings2.wav");
	precache_sound("weapons/casings3.wav");
}
