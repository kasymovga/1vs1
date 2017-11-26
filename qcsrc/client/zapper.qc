
.vector zapper_start;
.vector zapper_end;
.vector zapper_shotorg;
.float zapper_akimbo;

vector Zapper_BeamRGB(float t) {
    switch(t) {
        case COLOR_TEAM1:            return '5.0   1.0   0.5';
        case COLOR_TEAM2: default:   return '0.5   1.0   5.0';
        case COLOR_TEAM3:            return '4.0   2.5   0.5';
        case COLOR_TEAM4:            return '5.0   0.7   3.0';
    }
}

float zapper_beam_width;
float zapper_particles_trace_callback_beamoffs;

void(vector dir) vectorvectors = #432;

void zapper_particles_trace_callback(vector from, vector to, vector ignore) {
    vector rgb = Zapper_BeamRGB(self.team);
    string tex = "particles/zapper";
    float t = self.cnt + time;

    float _alpha = self.alpha;
    rgb *= _alpha;

    Draw_CylindricLine(from, to, zapper_beam_width, tex, 0.03, zapper_particles_trace_callback_beamoffs, rgb, _alpha, DRAWFLAG_ADDITIVE, WarpZone_FindNearestOrigin((from + to) * 0.5, view_origin, FALSE));
    zapper_particles_trace_callback_beamoffs += 0.03 * vlen(from - to) / zapper_beam_width;

}

void Zapper_Draw(void) {
    vector start, real_start;
	vector end;

    float me = ((spectatee_status > 0) ? spectatee_status : player_localentnum);

    float first_person = FALSE;

	InterpolateOrigin_Do();
    self.zapper_end = self.origin;

    zapper_beam_width = 12;

	vector zapper_shotorigin = self.zapper_shotorg;
    if(self.sv_entnum == me) {
		if not(autocvar_chase_active) {
			camera_correction_needed = TRUE;
			start = view_origin + view_forward * zapper_shotorigin_x + view_right * zapper_shotorigin_y + view_up * zapper_shotorigin_z;
			self.zapper_start = start;
			zapper_beam_width = 8;
			first_person = TRUE;
			if (self.zapper_akimbo)
				end = (start + view_forward * (vlen(self.zapper_start - self.zapper_end)));
			else
				end = (view_origin + view_forward * (vlen(self.zapper_start - self.zapper_end)));

			real_start = view_origin;
		} else {
			end = self.zapper_end;
			real_start = start = self.zapper_start;
		}
    } else {
        end = self.zapper_end;
		real_start = start = self.zapper_start;
	}


    zapper_particles_trace_callback_beamoffs = -time * 5;

    vector dynlight_org = self.zapper_start;

    if(first_person) {
        dynlight_org = start + view_forward;
        zapper_particles_trace_callback(start - view_forward * zapper_shotorigin_x, start, start);
    }
    //R_AddDynamicLight(dynlight_org, 50 * self.alpha, Zapper_BeamRGB(self.team));
	WarpZone_DrawEffectTriangle(real_start, self.zapper_start, end, zapper_particles_trace_callback);
	//zapper_particles_trace_callback(self.zapper_start, end);
	vector v = WarpZone_TransformVelocity(WarpZone_trace_transform, normalize(end - start));
	end = WarpZone_TransformOrigin(WarpZone_trace_transform, end);
	end = end - v;
    pointparticles(rm_particleeffectnum_team("RM_ZAPPER", self.team, 2), end, v, frametime * 300);
	pointparticles(rm_particleeffectnum_team("RM_ZAPPER_MUZZLEFLASH", self.team, 2), start, '0 0 0', frametime * 300);
}

void Zapper_Draw_Shield(void) {
    InterpolateOrigin_Do();
    self.zapper_end = self.origin;

    float me = ((spectatee_status > 0) ? spectatee_status : player_localentnum);

	if not(autocvar_chase_active)
    if (self.sv_entnum == me) {
        vector zapper_shotorigin = self.zapper_shotorg;
        self.zapper_start = view_origin + view_forward * (zapper_shotorigin_x - 1) + view_right * zapper_shotorigin_y + view_up * zapper_shotorigin_z;
        self.zapper_end = self.zapper_start + view_forward * 30;
    }

    vector start = self.zapper_start;
    vector end = self.zapper_end;

    string tex = "particles/zapper";
    vector rgb = Zapper_BeamRGB(self.team) * 0.5;

    Draw_CylindricLine(end, start,  12, tex, 0.03, 5 * time, rgb, self.alpha, DRAWFLAG_ADDITIVE, view_origin);

    if(self.alpha < 1)
        return;

    float eff_zap = rm_particleeffectnum_team("RM_ZAPPER", self.team, 2);
    float eff_muz = rm_particleeffectnum_team("RM_ZAPPER_MUZZLEFLASH", self.team, 2);
    float pcount = frametime * 300;

    pointparticles(eff_zap, end, '0 0 0', pcount);
    pointparticles(eff_muz, start, end - start, pcount);
}

.float snd_looping;
void Zapper_Remove(void) {
    sound(self, CHAN_PROJECTILE, "misc/null.wav", VOL_BASE, ATTN_NORM);
}

void Zapper_Read(float t) {
    float sf = ReadByte();

    if(sf & 1) {
        float vol, attn;

		vol = VOL_BASE;
		attn = ATTN_NORM;

        if(t == ENT_CLIENT_ZAPPER_SHIELD) {
            self.draw = Zapper_Draw_Shield;
            sound(self, CHAN_PROJECTILE, "weapons/zapper_shield_loop.wav", 1, attn);
        } else {
            self.draw = Zapper_Draw;
            sound(self, CHAN_PROJECTILE, "weapons/zapper_fly.wav", vol, attn);
        }

        self.entremove = Zapper_Remove;

        if(sf & 16) {
            self.sv_entnum = 0;
            self.team = ReadByte();
        } else {
            self.sv_entnum = ReadByte();
            self.team = GetPlayerColor(self.sv_entnum - 1);
        }

        self.alpha = 1;
        self.cnt = random() * 1000;
    }

    if(sf & 2) {
        self.zapper_start_x = ReadCoord();
        self.zapper_start_y = ReadCoord();
        self.zapper_start_z = ReadCoord();
    }

    if(sf & 4) {
        self.zapper_end_x = ReadCoord();
        self.zapper_end_y = ReadCoord();
        self.zapper_end_z = ReadCoord();
        setorigin(self, self.zapper_end);
        InterpolateOrigin_Note();
    }

	if (sf & 8) {
		self.zapper_akimbo = 1;
	} else
		self.zapper_akimbo = 0;

	if (sf & 32) {
		self.zapper_shotorg_x = ReadCoord();
		self.zapper_shotorg_y = ReadCoord();
		self.zapper_shotorg_z = ReadCoord();
	}
}

void Zapper_Read_Beam(float ignore) {
	Zapper_Read(ENT_CLIENT_ZAPPER);
}

void Zapper_Read_Shield(float ignore) {
	Zapper_Read(ENT_CLIENT_ZAPPER_SHIELD);
}

void LightingArc_Draw(void) {
    string tex;
    switch(self.team) {
        case COLOR_TEAM1: tex = "particles/hook_red";       break;
        case COLOR_TEAM2: tex = "particles/hook_blue";      break;
        case COLOR_TEAM3: tex = "particles/hook_yellow";    break;
        case COLOR_TEAM4: tex = "particles/hook_pink";      break;
        default         : tex = "particles/hook_green";     break;
    }

    float i; for(i = 0; i < 5; ++i)
        Draw_CylindricLine(self.origin, self.velocity, 25 * self.alpha, tex, 0.02, random(), '1 1 1', self.alpha, DRAWFLAG_ADDITIVE, view_origin);

    self.alpha = self.alpha - frametime * 3;
    if(self.alpha < 0)
        remove(self);
}

void LightingArc_Segment(vector start, vector end, float ateam) {
    entity e = spawn();
    e.alpha = 1;
    e.origin = start;
    e.velocity = end;
    e.draw = LightingArc_Draw;
    e.team = ateam;

    trailparticles(world, rm_particleeffectnum_team("RM_LIGHTNING", ateam, 2), start, end);
}


void Zapper_ReadLightning(void) {
    vector from, to;

    float zapper_lightning_ateam  = ReadByte();
    from_x = ReadCoord(); from_y = ReadCoord(); from_z = ReadCoord();
    to_x   = ReadCoord(); to_y   = ReadCoord(); to_z   = ReadCoord();

    //if(!rm_teamlasers)
    //    zapper_lightning_ateam = COLOR_TEAM2;

    pointparticles(rm_particleeffectnum_team("RM_HG_PLASMA_SHARD_EXPLODE", zapper_lightning_ateam, 2), to, '0 0 0', 1);
    LightingArc_Segment(from, to, zapper_lightning_ateam);

    pointparticles(particleeffectnum("electro_muzzleflash"), from, normalize(to - from) * 1000, 1);

}
