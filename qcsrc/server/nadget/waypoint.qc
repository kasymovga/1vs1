
enum {
    WPCOLOR_NONE,
    WPCOLOR_RED,
    WPCOLOR_CYAN,
    WPCOLOR_ORANGE,
};

void nadget_Waypoint_Update(void) {
	string wpname = "";
#define POINTER_PICK(X, Y) \
	case NADGET_##X: \
		switch (self.hg_wp_state) { \
		case WPCOLOR_RED: \
			wpname = "pointers/" Y "_red";\
			break; \
		case WPCOLOR_ORANGE: \
			wpname = "pointers/" Y "_orange";\
			break; \
		case WPCOLOR_CYAN: \
			wpname = "pointers/" Y "_cyan";\
			break; \
		default: \
			wpname = "pointers/" Y;\
			break; \
		} \
		break;
	switch (self.hg_type) {
	POINTER_PICK(LASER, "laser");
	POINTER_PICK(LINKER, "linker");
	POINTER_PICK(NAPALM, "napalm");
	POINTER_PICK(PLASMA, "plasma");
	POINTER_PICK(RAZE, "raze");
	POINTER_PICK(REMOTE, "remote");
	POINTER_PICK(SENTRY, "sentry");
	POINTER_PICK(TRANSLOC, "transloc");
	default:
		switch (self.hg_wp_state) {
		case WPCOLOR_RED: wpname = "pointers/red"; break;
		case WPCOLOR_ORANGE: wpname = "pointers/orange"; break;
		case WPCOLOR_CYAN: wpname = "pointers/cyan"; break;
        }
	}
#undef POINTER_PICK
    if(!self.hg_waypoint) {
        float ownerhack = (self.hg_type == NADGET_SENTRY);
        float teamwp = (team_mode && GRENVAR(self.hg_type, "detect_enemies_teamwide"));
        entity o = (ownerhack ? self.realowner : self.owner);
        float t = (teamwp ? o.team : 0);
        o = (teamwp ? world : o);

        marker_Spawn(wpname, 0, 0, self, '0 0 16',
            o, t, self, hg_waypoint, 1);

        if(self.hg_type == NADGET_SENTRY) {
            marker_UpdateMaxHealth(self.hg_waypoint, (self.hg_wp_state == WPCOLOR_RED));
            marker_UpdateTeamRadar(self.hg_waypoint, 0, '1 0.5 0');
        } else if(self.hg_detonable && self.hg_detonateready > time) {
            marker_UpdateTeamRadar(self.hg_waypoint, 0, '0 1 1');
            marker_UpdateBuildFinished(self.hg_waypoint, self.hg_detonateready);
        } else {
            marker_UpdateTeamRadar(self.hg_waypoint, 0, '0 1 1');
            marker_UpdateBuildFinished(self.hg_waypoint, self.hg_deathtime);
        }
    } else {
        marker_UpdateSprites(self.hg_waypoint, wpname, "", "");

        if(self.hg_type == NADGET_SENTRY) {
            if(self.hg_wp_state == WPCOLOR_RED) {
                marker_UpdateMaxHealth(self.hg_waypoint, 1);
                marker_UpdateHealth(self.hg_waypoint, self.hg_sentry_energy);
            } else
                marker_UpdateMaxHealth(self.hg_waypoint, 0);
        }
    }
}

void nadget_Waypoint_SetColor(float wpcolor) {
    if(self.hg_wp_state != wpcolor) {
        self.hg_wp_state = wpcolor;
        nadget_Waypoint_Update();
    }
}

void nadget_Waypoint(void) {
    entity plr;
    float detected = 0;
    float rng;
    float warn = 0;

    if(time < self.hg_wp_nextthink)
        return;

    if(self.hg_type == NADGET_SENTRY) {
        if(self.hg_waypoint)
            marker_UpdateHealth(self.hg_waypoint, self.hg_sentry_energy);

        detected = (self.hg_sentry_energy < 1);
        warn = (self.health < cvar("g_nadgets_sentry_health"));
    } else {
		rng = GRENVAR(self.hg_type, "detect_enemies");
        if(!rng) {
            if(self.hg_waypoint)
                marker_Disown(self.hg_waypoint, 0.5);
            return;
        }

        if(rng > 0) {
            PLAYER_FOR_EACH(plr) {
                if(plr.team != self.team || !team_mode)
                if(plr != self.owner)
                if not(PLAYER_DEAD(plr))
                if(vlen(self.origin - plr.origin) < rng)
                if(checkpvs(self.origin, plr)) {
                    detected = TRUE;
                    break;
                }
            }
        } else {
            warn = (time > self.hg_deathtime - 1);
            detected = (time > self.hg_deathtime - 0.5);
        }

        if(self.hg_detonatetime)
            warn = TRUE;
    }

    if(!self.hg_waypoint)
        self.hg_wp_state = WPCOLOR_NONE;

    nadget_Waypoint_SetColor(
        (detected ?  WPCOLOR_RED : (warn ?  WPCOLOR_ORANGE : WPCOLOR_CYAN)));

    self.hg_wp_nextthink = time + 0.1;
}

void nadget_Waypoint_Remove(entity wp) {
    if(wp)
        marker_Disown(wp, 0.5);
}
