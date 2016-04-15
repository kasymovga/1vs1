void InfoMessages_Think()
{
	string msg = cvar_string(strcat("sv_infomessage", ftos(self.cnt)));
	if (msg == "")
	{
		if (self.cnt == 1) //sv_infomessage1 was setted to empty string
		{
			self.nextthink = time + self.dmg;
			return;
		}

		self.cnt = 1;
		InfoMessages_Think();
		return;
	}
	entity e;
	FOR_EACH_REALCLIENT(e)
		sprint(e, strcat("\{1}^5 * ^7", msg, "\n"));

	self.cnt++;
	cvar_set("_sv_infomessage_current", ftos(self.cnt));
	self.nextthink = time + self.dmg;
}

void InfoMessages_Init()
{
	entity e;
	float sv_infomessages_interval = cvar("sv_infomessages_interval");
	if (sv_infomessages_interval <= 0)
		return;

	e = spawn();
	e.cnt = cvar("_sv_infomessage_current");
	if (e.cnt <= 0)
	{
		registercvar("_sv_infomessage_current", "1");
		e.cnt = 1;
	}
	e.think = InfoMessages_Think;
	e.dmg = sv_infomessages_interval * 60;

	e.nextthink = time + e.dmg;
}
