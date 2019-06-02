entity infomessage;

void(void) infomessages_think {
	string msg = cvar_string(strcat("sv_infomessage", ftos(self.cnt)));
	if (msg == "")
	{
		if (self.cnt == 1) //sv_infomessage1 was setted to empty string
		{
			self.nextthink = time + self.dmg;
			return;
		}

		self.cnt = 1;
		infomessages_think();
		return;
	}
	entity e;
	FOR_EACH_REALCLIENT(e)
		sprint(e, strcat("\{1}^5 * ^7", msg, "\n"));

	self.cnt++;
	cvar_set("_sv_infomessage_current", ftos(self.cnt));
	self.nextthink = time + self.dmg;
}

void(void) infomessages_init {
	float sv_infomessages_interval = cvar("sv_infomessages_interval") * 60;
	float firstinterval;
	float firstinterval_factor;
	if (sv_infomessages_interval <= 0)
		return;

	firstinterval_factor = cvar("_sv_infomessages_firstintervalfactor");
	if (firstinterval_factor <= 0)
		firstinterval_factor = 1;

	firstinterval = sv_infomessages_interval * firstinterval_factor;

	infomessage = spawn();
	infomessage.cnt = cvar("_sv_infomessage_current");
	if (infomessage.cnt <= 0)
	{
		registercvar("_sv_infomessage_current", "1");
		infomessage.cnt = 1;
	}
	infomessage.think = infomessages_think;
	infomessage.dmg = sv_infomessages_interval;
	infomessage.nextthink = time + firstinterval;
}

void(void) infomessages_shutdown {
	cvar_set("_sv_infomessages_firstintervalfactor", ftos((infomessage.nextthink - time) / infomessage.dmg));
}
