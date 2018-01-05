// plr.isactive = player is in range and coordinates/status (health and armor) are up to date
// plr.origin = player origin TODO: should maybe move this so it's the origin of the shownames tag already in SSQC for culling?
// plr.healthvalue
// plr.armorvalue
// plr.sameteam = player is on same team as local client
//

.float the_entnum;

.float sn_lastdraw;
//.float sn_forcefrozen;
.vector iorigin;
.entity teambubble;

float(float entitynum, float fldnum) getentity = #504;
vector(float entitynum, float fldnum) getentityvec = #504;
float E_ACTIVE      = 0; // float 0/1
float E_ORIGIN      = 1; // vector

#define SHOWNAMES_ALPHA 0.9
#define SHOWNAMES_ASPECT 8
#define SHOWNAMES_FONTSIZE 10
#define SHOWNAMES_HEIGHT 15

#define SHOWNAMES_MAXDISTANCE 2500
#define SHOWNAMES_MINDISTANCE 1000
#define SHOWNAMES_ORIGIN_OFFSET '0 0 64'

float Shownames_PreDrawPlayer_Disabled() { return FALSE; }

var float() Shownames_PreDrawPlayer;

float Shownames_PreDrawPlayer_Enabled() {
	float plr_entnum = self.sv_entnum + 1;
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
	if (teamplay)
	if (self.cnt)
		return FALSE;

	vector v = normalize(self.iorigin - view_origin);
	float a = normalize(view_forward) * v;
	if (a < CVAR(cl_shownames_cos))
		return FALSE;

	if (self.cnt) {
		traceline(self.iorigin, view_origin, 0, world);
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
    o = project_3d_to_2d(self.iorigin + SHOWNAMES_ORIGIN_OFFSET);

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
    s = GetPlayerName(self.sv_entnum);
    float textsz = SHOWNAMES_FONTSIZE;

	float _team;
    if(teamplay) {
		_team = GetPlayerColorForce(self.sv_entnum);
        s = textShortenToWidth(strdecolorize(s), namesize, stringwidth_nocolors);
        s = strcat(Team_ColorCode(_team), s);
    } else
		s = textShortenToWidth(s, namesize, stringwidth_colors);

	if (self.health)
		s = strcat(s, " ^7(^1", UnboundFromByte(self.health), (self.armorvalue ? strcat("^7/^2", UnboundFromByte(self.armorvalue)): ""), "^7)");

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
	self.scale = (1 + (vlen(view_origin - self.origin)) / 400) * (fov_zoomed / 120);
	setorigin(self, o.iorigin + '0 0 64');
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
			plr.teambubble.effects = EF_NODEPTHTEST;
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
	if (ext_DP_CSQC_QUERYRENDERENTITY)
		Shownames_PreDrawPlayer = Shownames_PreDrawPlayer_Enabled;
	else
		Shownames_PreDrawPlayer = Shownames_PreDrawPlayer_Disabled;
}
