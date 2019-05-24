
void func_laserbeam_trace(vector o, vector aimpos) {
    var boxsize = 16;

    do {
        boxsize *= 0.5;

        if(boxsize < 1) {
            traceline(o, aimpos, MOVE_NORMAL, self);
            return;
        }

        tracebox(o, '-1 -1 -1' * boxsize, '1 1 1' * boxsize, aimpos, MOVE_NORMAL, self);
        o = trace_endpos;
    } while(trace_fraction < 1 && !trace_ent.takedamage);
}

void func_laserbeam_think(void) {
    vector o = self.origin;
    vector aimpos;

    if(!self.state)
        return;

    if(self.enemy) {
        aimpos = self.enemy.origin;
    } else {
        makevectors(self.angles);
        aimpos = o + v_forward * self.t_length;
    }

    if(self.t_length)
        aimpos = o + normalize(aimpos - o) * self.t_length;

    func_laserbeam_trace(o, aimpos);
    var end = trace_endpos;
    var targ = trace_ent;

    if(targ.takedamage && time > self.cnt) {
        damage(targ, self, world, self.dmg, DEATH_HURTTRIGGER, end, 10 * normalize(end - o));
        self.cnt = time + 0.1;
    }

    end -= normalize(end - self.zapper_beam_start) * 5;

    if(o != self.zapper_beam_start) {
        self.zapper_beam_start = o;
        self.SendFlags |= 2;
    }

    if(end != self.zapper_beam_end) {
        self.zapper_beam_end = end;
        self.SendFlags |= 4;
    }

    self.nextthink = time;
}

void func_laserbeam_reset(void) {
    self.state = !(self.spawnflags & 1);
    self.think();
}

float func_laserbeam_customize(void) {
    return self.state;
}

void func_laserbeam_use(void) {
    self.state = !self.state;
    if(self.state)
        self.nextthink = time;
}

void func_laserbeam_init(void) {
    self.enemy = world;
    self.team = COLOR_TEAM1;
    self.think = func_laserbeam_think;
    self.reset = func_laserbeam_reset;
    self.use = func_laserbeam_use;
    self.customizeentityforclient = func_laserbeam_customize;

    if(!self.sounds)
        self.sounds = -1;

    if(self.dmg <= 0)
        self.dmg = 20;

    self.team = Team_FromIndex(self.color_x);

    if(!self.team)
        self.team = COLOR_TEAM1;

    if(self.target != "") {
        self.enemy = find(world, targetname, self.target);

        if(!self.enemy)
            objerror("func_laser has an invalid target");
    } else if(!self.t_length)
        self.t_length = MAX_SHOT_DISTANCE;

    if(self.t_length < 0)
        self.t_length = MAX_SHOT_DISTANCE;

    self.reset();
    net_link_entity(self, FALSE, 0, W_Zapper_Beam_Send);

    dlc_require("zapper_v1");
    dlc_require("rm_effects_v2");
    dlc_precache_sound("weapons/zapper_fly.wav");
}

void spawnfunc_func_laserbeam(void) {
    setsize(self, '-4 -4 -4', '4 4 4');
    move_out_of_solid(self, MOVE_WORLDONLY);
    InitializeEntity(self, func_laserbeam_init, INITPRIO_FINDTARGET);
}
