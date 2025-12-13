.vector iorigin;
.entity teambubble;

#define PLAYER_LABEL_ALPHA 0.9
#define PLAYER_LABEL_ASPECT 8
#define PLAYER_LABEL_FONTSIZE 10
#define PLAYER_LABEL_HEIGHT 15

#define PLAYER_LABEL_MAXDISTANCE 2500
#define PLAYER_LABEL_MINDISTANCE 1000
#define PLAYER_LABEL_ORIGIN_OFFSET '0 0 16'

float(void) player_label_draw_pre {
	float plr_entnum = self.shownames_entnum + 1;
	if (getentity(plr_entnum, E_ACTIVE)) {
		self.iorigin = getentityvec(plr_entnum, E_ORIGIN);
		if (self.teambubble)
			self.teambubble.cnt = 1;
	} else {
		if (self.cnt)
			return FALSE;

		self.iorigin = self.origin;
	}
	if (CVAR(cl_shownames) < 1)
		return FALSE;

	if (CVAR(cl_shownames < 2))
	if (team_teams)
	if (self.cnt)
		return FALSE;

	vector v = normalize(self.iorigin - view_origin);
	float a = normalize(view_forward) * v;
	if (a < CVAR(cl_shownames_cos))
		return FALSE;

	if (self.cnt) {
		traceline(self.iorigin + self.maxs, view_origin, TRACE_MOVE_NOMONSTERS, NULL);
		if (trace_fraction < 1)
			return FALSE;
	}
	return TRUE;
}

void(void) player_label_draw {
	if not(player_label_draw_pre())
		return;

	float oldfont = drawfont;
	float dist = vlen(self.iorigin - view_origin);
	float a = PLAYER_LABEL_ALPHA * CVAR(sbar_alpha_fg);
	if (dist >= PLAYER_LABEL_MAXDISTANCE)
		return;
	
	a *= ((PLAYER_LABEL_MAXDISTANCE - PLAYER_LABEL_MINDISTANCE) - max(0, dist - PLAYER_LABEL_MINDISTANCE)) / (PLAYER_LABEL_MAXDISTANCE - PLAYER_LABEL_MINDISTANCE);
	vector o;
	o = view_project_3d_to_2d(self.iorigin + self.maxs + PLAYER_LABEL_ORIGIN_OFFSET);
	if (o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
		return;

	o_z = 0;
	vector myPos, mySize;
	mySize = '0 0 0';
	mySize_x = PLAYER_LABEL_ASPECT;
	mySize_y = PLAYER_LABEL_HEIGHT;
	myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;
	vector namepos; // this is where the origin of the string
	float namesize; // total area where we can draw the string
	namepos = myPos + '0 1 0' * 0.5 * (PLAYER_LABEL_HEIGHT - PLAYER_LABEL_FONTSIZE);
	namesize = mySize_x;
	string s;
	s = player_name(self.sv_entnum);
	float textsz = PLAYER_LABEL_FONTSIZE;
	float _team;
	if (team_teams) {
		_team = player_color_force(self.sv_entnum);
		s = str_shorten_to_width(strdecolorize(s), namesize, str_width_nocolors);
		s = strcat(team_color_code(_team), s);
	} else
		s = str_shorten_to_width(s, namesize, str_width_colors);

	if (self.health)
		s = strcat(s, " ^7(^1", NET_UNBOUND_FROM_BYTE(self.health), (self.armorvalue ? strcat("^7/^2", NET_UNBOUND_FROM_BYTE(self.armorvalue)): ""), "^7)");

	float width = stringwidth(s, TRUE);
	if (width != namesize)
		namepos_x += (namesize - width) / 2;

	drawfont = sbar_font;
	float fade = 0.7;
	namepos_x = namepos_x - 0.5 * width * textsz;
	drawcolorcodedstring(namepos, s, textsz * '1 1 0', a, DRAWFLAG_NORMAL);
	drawfont = oldfont;
}

void(void) player_label_team_bubble_remove {
	if (self.teambubble)
		remove(self.teambubble);
}

void(void) player_label_team_bubble_draw {
	entity o = self.owner;
	self.scale = (1 + (vlen(view_origin - self.origin)) / 400) * (view_fov_zoomed / 120);
	setorigin(self, o.iorigin + o.maxs + '0 0 16');
	float h = o.health;
	if (h < 100) {
		float redfactor = 1 - h / 100;
		redfactor *= redfactor;
		self.colormod_x = 1 + redfactor;
		self.colormod_y = self.colormod_z = 1 - redfactor;
	} else {
		float greenfactor = (h - 100) / 155;
		greenfactor *= greenfactor;
		self.colormod_y = 1 + greenfactor;
		self.colormod_x = self.colormod_z = 1 - greenfactor;
	}
	R_AddEntity(self);
}

void(entity plr, float show) player_label_team_bubble_update {
	if (show) {
		if not(plr.teambubble) {
			plr.entremove = player_label_team_bubble_remove;
			plr.teambubble = spawn();
			precache_model("models/misc/teambubble.spr");
			setmodel(plr.teambubble, "models/misc/teambubble.spr");
			plr.teambubble.effects = EFFECT_NODEPTHTEST;
			plr.teambubble.owner = plr;
			plr.teambubble.draw = player_label_team_bubble_draw;
		}
	} else {
		if (plr.teambubble) {
			remove(plr.teambubble);
			plr.teambubble = NULL;
		}
	}
}

void(entity plr) player_label_enable {
	if (extension_DP_CSQC_QUERYRENDERENTITY) {
		plr.draw2d = player_label_draw;
		plr.draw2dflag = 1;
	}
}
