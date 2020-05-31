var void() footsteps_ServerFrame_NextLink;
void() footsteps_ServerFrame {
	entity oldself = self;
	FOR_EACH_PLAYER(self)
		if (!map_finished)
		if (self.flags & FL_ONGROUND)
		if (vlen(self.velocity) > sv_maxspeed * 0.6)
		if (!self.deadflag)
		if (time < self.lastground + 0.2)
		{
			if((time > self.nextstep))
			{
				self.nextstep = time + 0.3 + random() * 0.1;
				if not(self.waterlevel) {
					trace_dphitq3surfaceflags = 0;
					trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
					if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS)
					{
						if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
							sound(self, CHAN_PLAYER, sound_random("misc/metalfootstep0", 6), VOL_BASE, ATTN_NORM);
						else
							sound(self, CHAN_PLAYER, sound_random("misc/footstep0", 6), VOL_BASE, ATTN_NORM);
					}
				}
			}
		}
	self = oldself;
	footsteps_ServerFrame_NextLink();
}

void() footsteps_init {
	if not(cvar("g_footsteps"))
		return;

	sound_random_precache("misc/footstep0", 6);
	sound_random_precache("misc/metalfootstep0", 6);
	footsteps_ServerFrame_NextLink = gamehook_chain_world_frame_start;
	gamehook_chain_world_frame_start = footsteps_ServerFrame;
}
