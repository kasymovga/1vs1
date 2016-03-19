.vector lightning_beam_shotorg;

void LightningThink()
{
	vector end, start;
	start = self.HookStart;
	end = self.HookEnd;
	float num = self.owner.sv_entnum + 1;
	if(self.owner && (num == player_localentnum || num == spectatee_status) && !cvar("chase_active"))
	{
		end = view_origin + view_forward * vlen(start - end);
		start = view_origin + view_forward * self.lightning_beam_shotorg_x + view_right * self.lightning_beam_shotorg_y + view_up * self.lightning_beam_shotorg_z;
	}

	Draw_CylindricLine(start, end, 32, "particles/hook_blue", 0.25, random(), '1 1 1', 1, DRAWFLAG_NORMAL);
	self.nextthink = time;
}

void Ent_Lightning(float usetime)
{
	float i;
	entity p;
	i = ReadShort();
	if(i > 0 || i < 256)
		p = playerslots[i - 1];

	if (p)
		self.owner = p;

	self.HookStart_x = ReadCoord();
	self.HookStart_y = ReadCoord();
	self.HookStart_z = ReadCoord();
	self.HookEnd_x = ReadCoord();
	self.HookEnd_y = ReadCoord();
	self.HookEnd_z = ReadCoord();
	self.lightning_beam_shotorg_x = ReadCoord();
	self.lightning_beam_shotorg_y = ReadCoord();
	self.lightning_beam_shotorg_z = ReadCoord();
	self.nextthink = usetime;
	self.think = LightningThink;
}
