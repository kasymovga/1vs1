.vector iorigin;
.entity teambubble;

#define SHOWNAMES_ALPHA 0.9
#define SHOWNAMES_ASPECT 8
#define SHOWNAMES_FONTSIZE 10
#define SHOWNAMES_HEIGHT 15

#define SHOWNAMES_MAXDISTANCE 2500
#define SHOWNAMES_MINDISTANCE 1000
#define SHOWNAMES_ORIGIN_OFFSET '0 0 16'

float Shownames_PreDrawPlayer_Disabled() { return FALSE; }

var float() Shownames_PreDrawPlayer;

float Shownames_PreDrawPlayer_Enabled() {
	float plr_entnum = self.shownames_entnum + 1;
	if(getentity(plr_entnum, E_ACTIVE)) {
		self.iorigin = getentityvec(plr_entnum, E_ORIGIN);
		if (self.teambubble)
			self.teambubble.cnt = 1;
	} else {
		if (self.cnt)
			return FALSE;

		self.iorigin = self.origin;
	}
    if(CVAR(cl_shownames) < 1)
        return FALSE;

	if (CVAR(cl_shownames < 2))
	if (team_mode)
	if (self.cnt)
		return FALSE;

	vector v = normalize(self.iorigin - view_origin);
	float a = normalize(view_forward) * v;
	if (a < CVAR(cl_shownames_cos))
		return FALSE;

	if (self.cnt) {
		traceline(self.iorigin + self.maxs, view_origin, TRACE_MOVE_NOMONSTERS, world);
		if (trace_fraction < 1)
			return FALSE;
	}
	return TRUE;
}

void Shownames_DrawPlayer() {
	if not(Shownames_PreDrawPlayer())
		return;

    float oldfont = drawfont;
    float dist = vlen(self.iorigin - view_origin);
    float a = SHOWNAMES_ALPHA;

    if(self.alpha)
        a *= self.alpha;

    if(dist >= SHOWNAMES_MAXDISTANCE)
        return;

    a *= ((SHOWNAMES_MAXDISTANCE - SHOWNAMES_MINDISTANCE) - max(0, dist - SHOWNAMES_MINDISTANCE)) / (SHOWNAMES_MAXDISTANCE - SHOWNAMES_MINDISTANCE);

    vector o;
    o = view_project_3d_to_2d(self.iorigin + self.maxs + SHOWNAMES_ORIGIN_OFFSET);

    if(o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
        return;

    o_z = 0;

    vector myPos, mySize;
	mySize = '0 0 0';
    mySize_x = SHOWNAMES_ASPECT;
	mySize_y = SHOWNAMES_HEIGHT;
    myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;

    vector namepos; // this is where the origin of the string
    float namesize; // total area where we can draw the string

    namepos = myPos + '0 1 0' * 0.5 * (SHOWNAMES_HEIGHT - SHOWNAMES_FONTSIZE);
    namesize = mySize_x;

    string s;
    s = player_name(self.sv_entnum);
    float textsz = SHOWNAMES_FONTSIZE;

	float _team;
    if (team_mode) {
		_team = player_color_force(self.sv_entnum);
        s = str_shorten_to_width(strdecolorize(s), namesize, str_width_nocolors);
        s = strcat(team_color_code(_team), s);
    } else
		s = str_shorten_to_width(s, namesize, str_width_colors);

	if (self.health)
		s = strcat(s, " ^7(^1", NET_UNBOUND_FROM_BYTE(self.health), (self.armorvalue ? strcat("^7/^2", NET_UNBOUND_FROM_BYTE(self.armorvalue)): ""), "^7)");

    float width = stringwidth(s, TRUE);

    if(width != namesize)
        namepos_x += (namesize - width) / 2;

	drawfont = sbar_font;

	float fade = 0.7;

	namepos_x = namepos_x - 0.5 * width * textsz;

	drawcolorcodedstring(namepos, s, textsz * '1 1 0', a, DRAWFLAG_NORMAL);
    
    drawfont = oldfont;
}

void Shownames_TeamBubbleRemove() {
	if (self.teambubble)
		remove(self.teambubble);
}

void Shownames_TeamBubbleDraw() {
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

void Shownames_UpdateTeamBubble(entity plr, float show) {
	if (show) {
		if not(plr.teambubble) {
			plr.entremove = Shownames_TeamBubbleRemove;
			plr.teambubble = spawn();
			precache_model("models/misc/teambubble.spr");
			setmodel(plr.teambubble, "models/misc/teambubble.spr");
			plr.teambubble.effects = EFFECT_NODEPTHTEST;
			plr.teambubble.owner = plr;
			plr.teambubble.draw = Shownames_TeamBubbleDraw;
		}
	} else {
		if (plr.teambubble) {
			remove(plr.teambubble);
			plr.teambubble = world;
		}
	}
}

void Shownames_Init(entity plr) {
    plr.draw2d = Shownames_DrawPlayer;
	plr.draw2dflag = 1;
	if (extension_DP_CSQC_QUERYRENDERENTITY)
		Shownames_PreDrawPlayer = Shownames_PreDrawPlayer_Enabled;
	else
		Shownames_PreDrawPlayer = Shownames_PreDrawPlayer_Disabled;
}
