void spawnfunc_target_position() {};

// TODO add a way to do looped sounds with sound(); then complete this entity
.float volume, atten;
void(void) target_speaker_use {
	sound(self, CHAN_TRIGGER, self.noise, VOL_BASE * self.volume, self.atten);
}

void(void) spawnfunc_target_speaker {
	if(self.noise)
		precache_sound (self.noise);
	IFTARGETED
	{
		if(!self.atten)
			self.atten = ATTN_NORM;
		else if(self.atten < 0)
			self.atten = 0;
		if(!self.volume)
			self.volume = 1;
		self.use = target_speaker_use;
	}
	else
	{
		if(!self.atten)
			self.atten = ATTN_STATIC;
		else if(self.atten < 0)
			self.atten = 0;
		if(!self.volume)
			self.volume = 1;
		ambientsound (self.origin, self.noise, VOL_BASE * self.volume, self.atten);
	}
}

.entity voicescript_ctrl; // attached voice script

void(void) target_voicescript_ctrl_think {
	entity vs = self.enemy;
	entity pl = self.owner;
	float i, n, dt;

	if (pl.voicescript_ctrl != self || pl.classname != "player" || map_finished) {
		remove(self);
		return;
	}
	// get the next voice...
	n = tokenize_console(vs.message);
	if(self.cnt < vs.cnt)
		i = self.cnt * 2;
	else if(n > self.cnt * 2)
		i = math_mod(self.cnt - vs.cnt, (n - vs.cnt * 2 - 1) / 2) * 2 + vs.cnt * 2 + 1;
	else
		i = -1;

	if(i >= 0) {
		sound_play2(pl, strcat(vs.netname, "/", argv(i), ".wav"));
		dt = stof(argv(i + 1));
		if(dt >= 0)
			self.nextthink = time + dt + vs.wait * (0.5 * random());
		else
			self.nextthink = time - dt;

		self.cnt += 1;
	} else {
		pl.voicescript_ctrl = world; // stop trying then
		remove(self);
	}
}

void(void) target_voicescript_use {
	if(activator.voicescript_ctrl.enemy != self)
	{
		entity vsctrl = spawn();
		vsctrl.owner = activator;
		vsctrl.enemy = self;
		vsctrl.think = target_voicescript_ctrl_think;
		vsctrl.cnt = 0;
		vsctrl.nextthink = max(activator.voicescript_ctrl.nextthink, time + self.delay);
		activator.voicescript_ctrl = vsctrl;
	}
}

var void(entity spot) target_voicescript_player_spawn_next;
void(entity spot) target_voicescript_player_spawn {
	self.voicescript_ctrl = world;
	target_voicescript_player_spawn_next(spot);
}

float spawnfunc_target_voicescript_initialized;
void(void) spawnfunc_target_voicescript {
	// netname: directory of the sound files
	// message: list of "sound file" duration "sound file" duration, a *, and again a list
	//          foo1 4.1 foo2 4.0 foo3 -3.1 * fool1 1.1 fool2 7.1 fool3 9.1 fool4 3.7
	//          Here, a - in front of the duration means that no delay is to be
	//          added after this message
	// wait: average time between messages
	// delay: initial delay before the first message

	float i, n;
	if not(spawnfunc_target_voicescript_initialized) {
		target_voicescript_player_spawn_next = gamehook_chain_player_spawn;
		gamehook_chain_player_spawn = target_voicescript_player_spawn;
		spawnfunc_target_voicescript_initialized = TRUE;
	}
	if (self.message == "") {
		remove(self);
		return;
	}
	self.use = target_voicescript_use;

	n = tokenize_console(self.message);
	self.cnt = n / 2;
	for(i = 0; i+1 < n; i += 2)
	{
		if(argv(i) == "*")
		{
			self.cnt = i / 2;
			++i;
		}
		precache_sound(strcat(self.netname, "/", argv(i), ".wav"));
	}
}

void(void) target_delay_use {
	self.nextthink = time + self.wait;
	self.think = trigger_use_targets;
}

void(void) target_delay_init {
	IFTARGETED
		return;
	self.use();
}

void(void) spawnfunc_target_delay {
	self.use = target_delay_use;
	self.reset = target_delay_init;
	entity_initialize(self, target_delay_init, INITPRIO_SETLOCATION);
}

float NUM_NEAREST_ENTITIES = 4;
entity nearest_entity[NUM_NEAREST_ENTITIES];
float nearest_length[NUM_NEAREST_ENTITIES];
entity (vector point, .string field, string value, vector axismod) target_location_find_nearest {
    entity localhead;
    float i;
    float j;
    float len;
    vector dist;

    float num_nearest;
    num_nearest = 0;

    localhead = find(world, field, value);
    while (localhead)
    {
        if ((localhead.items == IT_KEY1 || localhead.items == IT_KEY2) && localhead.message2 == "###item###")
            dist = localhead.oldorigin;
        else
            dist = localhead.origin;
        dist = dist - point;
        dist = dist_x * axismod_x * '1 0 0' + dist_y * axismod_y * '0 1 0' + dist_z * axismod_z * '0 0 1';
        len = vlen(dist);

        for (i = 0; i < num_nearest; ++i)
        {
            if (len < nearest_length[i])
                break;
        }

        // now i tells us where to insert at
        //   INSERTION SORT! YOU'VE SEEN IT! RUN!
        if (i < NUM_NEAREST_ENTITIES)
        {
            for (j = NUM_NEAREST_ENTITIES - 1; j >= i; --j)
            {
                nearest_length[j + 1] = nearest_length[j];
                nearest_entity[j + 1] = nearest_entity[j];
            }
            nearest_length[i] = len;
            nearest_entity[i] = localhead;
            if (num_nearest < NUM_NEAREST_ENTITIES)
                num_nearest = num_nearest + 1;
        }

        localhead = find(localhead, field, value);
    }

    // now use the first one from our list that we can see
    for (i = 0; i < num_nearest; ++i)
    {
        trace_line(point, nearest_entity[i].origin, TRUE, world);
        if (trace_fraction == 1)
            return nearest_entity[i];
    }

    if (num_nearest == 0)
        return world;

    return nearest_entity[0];
}

string(vector p) target_location_nearest {
    entity loc;
    string ret;
    ret = "somewhere";
    loc = target_location_find_nearest(p, classname, "target_location", '1 1 1');
    if (loc)
    {
        ret = loc.message;
    }
    else
    {
        loc = target_location_find_nearest(p, message2, "###item###", '1 1 4');
        if (loc)
            ret = loc.netname;
    }
    return ret;
}

void(void) spawnfunc_target_location {
    self.classname = "target_location";
    // location name in netname
    // eventually support: count, teamgame selectors, line of sight?
}

void(void) target_kill_use {
	if (other.iscreature)
	if (other.takedamage)
		damage(other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
}

void(void) spawnfunc_target_kill {
	self.use = target_kill_use;
}

void(void) target_teleporter_use {
	entity oldother = other;
	other = activator;
	self.touch();
	other = oldother;
}

void(void) spawnfunc_target_teleporter {
	if (self.target != "") {
		teleport_setup();
		self.solid = SOLID_NOT;
		self.modelindex = 0;
		self.use = target_teleporter_use;
	}
	self.classname = "info_teleport_destination";
}

void(void) target_speed_use {
	if (activator.classname != "player")
		return;

	float s;
	if (self.spawnflags & 1)
		s = vlen(activator.velocity) * (self.speed / 100);
	else
		s = self.speed;

	if (self.spawnflags & 2)
	if not(self.spawnflags & 256)
		s = s + vlen(activator.velocity);

	if (self.spawnflags & 256) {
		vector v;
		v = '0 0 0';
		if (self.spawnflags & 4)
			v += '1 0 0';

		if (self.spawnflags & 8)
			v += '-1 0 0';

		if (self.spawnflags & 16)
			v += '0 1 0';

		if (self.spawnflags & 32)
			v += '0 -1 0';

		if (self.spawnflags & 64)
			v += '0 0 1';

		if (self.spawnflags & 128)
			v += '0 0 -1';

		activator.velocity = activator.velocity + normalize(v) * s;
	} else {
		if (activator.velocity == '0 0 0')
			return;

		activator.velocity = normalize(activator.velocity) * s;
	}
}

void(void) spawnfunc_target_speed {
	self.use = target_speed_use;
}

void(void) target_give_use {
	if (self.target == "")
		return;

	if (activator.classname != "player")
		return;

	entity e;
	for (e = find(world, targetname, self.target); e; e = find(e, targetname, self.target)) {
		if not(e.flags & (FL_ITEM | FL_WEAPON)) {
			print("Target ", self.target, " is not item\n");
			continue;
		}
		item_give_to(e, activator);
	}
}

void(void) spawnfunc_target_give {
	self.use = target_give_use;
}
