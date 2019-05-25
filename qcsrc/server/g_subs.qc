void SUB_Null() {};
float SUB_True() { return 1; }
float SUB_False() { return 0; }

vector NearestPointOnBox(entity box, vector org)
{
	vector m1, m2, nearest;

	m1 = box.mins + box.origin;
	m2 = box.maxs + box.origin;

	nearest_x = bound(m1_x, org_x, m2_x);
	nearest_y = bound(m1_y, org_y, m2_y);
	nearest_z = bound(m1_z, org_z, m2_z);

	return nearest;
}

/*
==================
SUB_VanishOrRemove

Makes client invisible or removes non-client
==================
*/
void SUB_VanishOrRemove (entity ent)
{
	if (ent.flags & FL_CLIENT)
	{
		// vanish
		ent.model = "";
		ent.effects = 0;
		ent.glow_size = 0;
		ent.pflags = 0;
	}
	else
	{
		// remove
		remove (ent);
	}
}

void SUB_SetFade_Think (void)
{
	self.think = SUB_SetFade_Think;
	self.nextthink = self.fade_time;
	self.alpha = 1 - (time - self.fade_time) * self.fade_rate;
	if (self.alpha < 0.01)
		SUB_VanishOrRemove(self);
	self.alpha = bound(0.01, self.alpha, 1);
}

/*
==================
SUB_SetFade

Fade 'ent' out when time >= 'when'
==================
*/
void SUB_SetFade (entity ent, float when, float fadetime)
{
	//if (ent.flags & FL_CLIENT) // && ent.deadflag != DEAD_NO)
	//	return;
	//ent.alpha = 1;
	ent.fade_rate = 1/fadetime;
	ent.fade_time = when;
	ent.think = SUB_SetFade_Think;
	ent.nextthink = when;
}

void tracetoss_wrapper(entity ent, entity ignore, float toss_frametime, float toss_count) {
	vector v0;
	float g0;
	v0 = ent.velocity;
	g0 = ent.gravity;
	ent.velocity = ent.velocity * toss_frametime * 20;
	ent.gravity *= (toss_frametime * toss_frametime * 400);
	tracetoss_dp(ent, ignore);
	ent.velocity= v0;
	ent.gravity = g0;
	return;
}

.string lodtarget1;
.string lodtarget2;
.string lodmodel1;
.string lodmodel2;
.float lodmodelindex0;
.float lodmodelindex1;
.float lodmodelindex2;
.float loddistance1;
.float loddistance2;

float LOD_customize()
{
	float d;

	if(cvar("loddebug"))
	{
		d = cvar("loddebug");
		if(d == 1)
			self.modelindex = self.lodmodelindex0;
		else if(d == 2)
			self.modelindex = self.lodmodelindex1;
		else // if(d == 3)
			self.modelindex = self.lodmodelindex2;
		return TRUE;
	}

	// TODO csqc network this so it only gets sent once
	d = vlen(NearestPointOnBox(self, other.origin) - other.origin);
	if(d < self.loddistance1)
		self.modelindex = self.lodmodelindex0;
	else if(!self.lodmodelindex2 || d < self.loddistance2)
		self.modelindex = self.lodmodelindex1;
	else
		self.modelindex = self.lodmodelindex2;

	return TRUE;
}

void LOD_uncustomize()
{
	self.modelindex = self.lodmodelindex0;
}

void LODmodel_attach()
{
	entity e;

	if(!self.loddistance1)
		self.loddistance1 = 1000;
	if(!self.loddistance2)
		self.loddistance2 = 2000;
	self.lodmodelindex0 = self.modelindex;

	if(self.lodtarget1 != "")
	{
		e = find(world, targetname, self.lodtarget1);
		if(e)
		{
			self.lodmodel1 = e.model;
			remove(e);
		}
	}
	if(self.lodtarget2 != "")
	{
		e = find(world, targetname, self.lodtarget2);
		if(e)
		{
			self.lodmodel2 = e.model;
			remove(e);
		}
	}

	if(cvar("loddebug") < 0)
	{
		self.lodmodel1 = self.lodmodel2 = ""; // don't even initialize
	}

	if(self.lodmodel1 != "")
	{
		vector mi, ma;
		mi = self.mins;
		ma = self.maxs;

		precache_model(self.lodmodel1);
		setmodel(self, self.lodmodel1);
		self.lodmodelindex1 = self.modelindex;

		if(self.lodmodel2 != "")
		{
			precache_model(self.lodmodel2);
			setmodel(self, self.lodmodel2);
			self.lodmodelindex2 = self.modelindex;
		}

		self.modelindex = self.lodmodelindex0;
		setsize(self, mi, ma);
	}

	if(self.lodmodelindex1)
		self.customizeentityforclient = LOD_customize;
}

void SetBrushEntityModel()
{
 	if(self.model != "")
 	{
 		precache_model(self.model);
 		setmodel(self, self.model); // no precision needed
		InitializeEntity(self, LODmodel_attach, INITPRIO_FINDTARGET);
 	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
}

void SetBrushEntityModelNoLOD()
{
 	if(self.model != "")
 	{
 		precache_model(self.model);
 		setmodel(self, self.model); // no precision needed
 	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
}

/*
================
InitTrigger
================
*/

void SetMovedir()
{
	if (self.movedir != '0 0 0')
		self.movedir = normalize(self.movedir);
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}

	self.angles = '0 0 0';
};

void InitTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

void InitSolidBSPTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_BSP;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_NONE; // why was this PUSH? -div0
//	self.modelindex = 0;
	self.model = "";
};

float InitMovingBrushTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	self.solid = SOLID_BSP;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_PUSH;
	if(self.modelindex == 0)
	{
		objerror("InitMovingBrushTrigger: no brushes found!");
		return 0;
	}
	return 1;
};

vector solve_quadratic(float a, float b, float c) // ax^2 + bx + c = 0
{
	vector v;
	float D;
	v = '0 0 0';
	if(a == 0)
	{
		if(b != 0)
		{
			v_x = v_y = -c / b;
			v_z = 1;
		}
		else
		{
			if(c == 0)
			{
				// actually, every number solves the equation!
				v_z = 1;
			}
		}
	}
	else
	{
		D = b*b - 4*a*c;
		if(D >= 0)
		{
			D = sqrt(D);
			if(a > 0) // put the smaller solution first
			{
				v_x = ((-b)-D) / (2*a);
				v_y = ((-b)+D) / (2*a);
			}
			else
			{
				v_x = (-b+D) / (2*a);
				v_y = (-b-D) / (2*a);
			}
			v_z = 1;
		}
		else
		{
			// complex solutions!
			D = sqrt(-D);
			v_x = -b / (2*a);
			if(a > 0)
				v_y =  D / (2*a);
			else
				v_y = -D / (2*a);
			v_z = 0;
		}
	}
	return v;
}
