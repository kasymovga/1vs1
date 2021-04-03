.float radio_starttime;

void(void) radio_stopper_think {
	if (self.cnt < -2) {
		remove(self);
		return;
	}
	float t = gettime(GETTIME_CDTRACK);
	if (self.cnt > t) {
		localcmd("cd reset;");
		remove(self);
		return;
	}
	self.cnt = t;
	self.nextthink = time;
}

void(void) radio_think {
	if (self.cnt < 0 || time - self.cnt > 300) {
		strunzone(self.netname);
		remove(self);
		return;
	}
	if (!file_exists(self.netname)) {
		self.nextthink = time + 1;
		return;
	}
	float start = (self.flags ? 0 : (server_time - self.radio_starttime));
	localcmd("cd reset; cd remap ", self.netname, "; cd loop 1 ", ftos(start), ";");
	strunzone(self.netname);
	if (self.flags) {
		// loop
		remove(self);
	} else {
		// play once - we can't just use "cd play" here becase it's apparently broken
		// instead, detect when the track starts to loop and stop it
		self.cnt = -2;
		self.think = radio_stopper_think;
		self.nextthink = time + 1;
	}
}

void(void) radio_read {
	float preload = ReadByte();
	string url = ReadString();
	if (autocvar_bgmvolume < 0.1)
		cvar_clientsettemp("bgmvolume", "0.1");

	if (preload) {
		if (autocvar__radio)
			localcmd("curl --pak ", url, "\n");
		return;
	}
	string fname = ReadString();
	float f = ReadByte();
	float loop = f & 1;
	float force = f & 2;
	float start;
	if (!loop)
		start = ReadCoord();

	if (!autocvar__radio) {
		if (!force)
			return;

		autocvar__radio = 1;
		cvar_set("_radio", "1");
	}
	localcmd("curl --pak ", url, "\n");
	entity e;
	for(e = world; (e = find(e, classname, "radio"));)
		e.cnt = -3;

	e = spawn();
	e.classname = "radio";
	e.netname = strzone(fname);
	e.think = radio_think;
	e.nextthink = time;
	e.cnt = time;
	e.flags = loop;
	e.radio_starttime = start;
}
