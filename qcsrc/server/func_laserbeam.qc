
void func_laserbeam_trace(vector o, vector aimpos) {
    float boxsize = 16;

    do {
        boxsize *= 0.5;

        if(boxsize < 1) {
            trace_line(o, aimpos, TRACE_MOVE_NORMAL, self);
            return;
        }

        trace_box(o, '-1 -1 -1' * boxsize, '1 1 1' * boxsize, aimpos, TRACE_MOVE_NORMAL, self);
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
    vector end = trace_endpos;
    entity targ = trace_ent;

    if(targ.takedamage && time > self.cnt) {
        damage(targ, self, world, self.dmg, DEATH_HURTTRIGGER, end, 10 * normalize(end - o));
        self.cnt = time + 0.1;
    }

    end -= normalize(end - self.pos1) * 5;

    if(o != self.pos1) {
        self.pos1 = o;
        self.SendFlags |= 2;
    }

    if(end != self.pos2) {
        self.pos2 = end;
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

    self.team = team_from_index(self.color_x);

    if(!self.team)
        self.team = COLOR_TEAM1;

    if(self.target != "") {
        self.enemy = find(world, targetname, self.target);

        if(!self.enemy)
            entity_abort("func_laser has an invalid target");
    } else if(!self.t_length)
        self.t_length = WORLD_MAX_SHOT_DISTANCE;

    if(self.t_length < 0)
        self.t_length = WORLD_MAX_SHOT_DISTANCE;

    self.reset();
    net_link_entity(self, FALSE, 0, weapon_zapper_beam_send);

    dlc_require("zapper_v2");
    dlc_require(DLC_RM_EFFECTS);
    dlc_precache_sound("weapons/zapper_fly.wav");
}

void spawnfunc_func_laserbeam(void) {
    setsize(self, '-4 -4 -4', '4 4 4');
    entity_move_out_of_solid(self);
    entity_initialize(self, func_laserbeam_init, INITPRIO_FINDTARGET);
}
