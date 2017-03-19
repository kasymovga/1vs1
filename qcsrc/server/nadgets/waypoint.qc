
enum {
    WPCOLOR_NONE,
    WPCOLOR_RED,
    WPCOLOR_CYAN,
    WPCOLOR_ORANGE,
};

void HG_Waypoint_Update(string wpname) {
    string hgname = HG_TypeToName(self.hg_type);

#if 0
    if(fexists(pickfile("models/sprites/pointers/" + hgname + "_" + wpname, "tga", "jpg", "png", NULL)))
        wpname = hgname + "_" + wpname;
#endif

    wpname = strcat("pointers/", wpname);

    if(!self.hg_waypoint) {
        float ownerhack = (/* self.hg_type == HG_BAIT || */ self.hg_type == HG_SENTRY);
        float teamwp = (teams_matter && GRENVAR(self.hg_type, /*if(self.hg_adept) "adept_detect_enemies_teamwide" else */ "detect_enemies_teamwide"));
        entity o = (ownerhack ? self.realowner : self.owner);
        float t = (teamwp ? o.team : 0);
        o = (teamwp ? world : o);

        WaypointSprite_Spawn(wpname, 0, 0, self, '0 0 32' * (1 + 1 * ownerhack + 1.5 * (self.hg_type == HG_SENTRY)),
            o, t, self, hg_waypoint, 1);

        if(self.hg_type == HG_SENTRY) {
            WaypointSprite_UpdateMaxHealth(self.hg_waypoint, (self.hg_wp_state == WPCOLOR_RED));
            WaypointSprite_UpdateTeamRadar(self.hg_waypoint, 0, '1 0.5 0');
        } else if(self.hg_detonable && self.hg_detonateready > time) {
            WaypointSprite_UpdateTeamRadar(self.hg_waypoint, 0, '0 1 1');
            WaypointSprite_UpdateBuildFinished(self.hg_waypoint, self.hg_detonateready);
        } else {
            WaypointSprite_UpdateTeamRadar(self.hg_waypoint, 0, '0 1 1');
            WaypointSprite_UpdateBuildFinished(self.hg_waypoint, self.hg_deathtime);
        }
    } else {
        WaypointSprite_UpdateSprites(self.hg_waypoint, wpname, "", "");

        if(self.hg_type == HG_SENTRY) {
            if(self.hg_wp_state == WPCOLOR_RED) {
                WaypointSprite_UpdateMaxHealth(self.hg_waypoint, 1);
                WaypointSprite_UpdateHealth(self.hg_waypoint, self.hg_sentry_energy);
            } else
                WaypointSprite_UpdateMaxHealth(self.hg_waypoint, 0);
        }
    }
}

void HG_Waypoint_SetColor(float wpcolor) {
    if(self.hg_wp_state != wpcolor) {
        self.hg_wp_state = wpcolor;
		string wpcolor_string;
		switch(wpcolor) {
			case WPCOLOR_RED:    wpcolor_string = "red"; break;
			case WPCOLOR_ORANGE: wpcolor_string = "orange"; break;
			case WPCOLOR_CYAN:   wpcolor_string = "cyan"; break;
			default:             wpcolor_string = "";
        }
        HG_Waypoint_Update(wpcolor_string);
    }
}

void HG_Waypoint(void) {
    entity plr;
    float detected;
    float rng;
    float warn;

    if(time < self.hg_wp_nextthink)
        return;

    if(self.hg_type == HG_SENTRY) {
        if(self.hg_waypoint)
            WaypointSprite_UpdateHealth(self.hg_waypoint, self.hg_sentry_energy);

        detected = (self.hg_sentry_energy < 1);
        warn = (self.health < cvar("g_nadgets_sentry_health"));
    }
#if 0
	else if(self.hg_type == HG_BAIT)
        detected = self.revprogress;
#endif
    else {
        if(self.hg_adept && GRENVAR(self.hg_type, "adept_detect_enemies"))
            rng = GRENVAR(self.hg_type, "adept_detect_enemies");
        else
            rng = GRENVAR(self.hg_type, "detect_enemies");

        if(!rng) {
            if(self.hg_waypoint)
                WaypointSprite_Disown(self.hg_waypoint, 0.5);
            return;
        }

        if(rng > 0) {
            FOR_EACH_PLAYER(plr) {
                if(plr.team != self.team || !teams_matter)
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

    HG_Waypoint_SetColor(
        (detected ?  WPCOLOR_RED : (warn ?  WPCOLOR_ORANGE : WPCOLOR_CYAN)));

    self.hg_wp_nextthink = time + 0.1;
}

void HG_Waypoint_Remove(entity wp) {
    if(wp)
        WaypointSprite_Disown(wp, 0.5);
}
