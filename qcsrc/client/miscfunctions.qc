var float(string text, float handleColors) stringwidth;

entity players;
entity teams;

vector decompressShortVector(float data)
{
	vector out;
	float pitch, yaw, len;
	if(data == 0)
		return '0 0 0';
	pitch = (data & 0xF000) / 0x1000;
	yaw =   (data & 0x0F80) / 0x80;
	len =   (data & 0x007F);

	//print("\ndecompress: pitch ", ftos(pitch)); print("yaw ", ftos(yaw)); print("len ", ftos(len), "\n");

	if(pitch == 0)
	{
		out_x = 0;
		out_y = 0;
		if(yaw == 31)
			out_z = -1;
		else
			out_z = +1;
	}
	else
	{
		yaw   = .19634954084936207740 * yaw;
		pitch = .19634954084936207740 * pitch - 1.57079632679489661922;
		out_x = cos(yaw) *  cos(pitch);
		out_y = sin(yaw) *  cos(pitch);
		out_z =            -sin(pitch);
	}

	//print("decompressed: ", vtos(out), "\n");

	return out * lengthLogTable[len];
}

float ReadInt24_t()
{
	float v;
	v = ReadShort() * 256; // note: this is signed
	v += ReadByte(); // note: this is unsigned
	return v;
}

string textShortenToWidth(string theText, float maxWidth, textLengthUpToWidth_widthFunction_t tw)
{
	if(tw(theText) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, textLengthUpToWidth(theText, maxWidth - tw("..."), tw)), "...");
}

void RegisterPlayer(entity player)
{
	entity pl;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
		if(pl == player) {
			print("Player already registered!\n");
			return;
		}
	player.sort_next = players.sort_next;
	player.sort_prev = players;
	if(players.sort_next)
		players.sort_next.sort_prev = player;
	players.sort_next = player;
}

void RemovePlayer(entity player)
{
	entity pl, parent;
	parent = players;
	for(pl = players.sort_next; pl && pl != player; pl = pl.sort_next)
		parent = pl;

	if(!pl)
	{
		print("Trying to remove a player which is not in the playerlist!\n");
		return;
	}
	parent.sort_next = player.sort_next;
	if(player.sort_next)
		player.sort_next.sort_prev = parent;

	player.sort_prev = world;
}

void MoveToLast(entity e)
{
	other = e.sort_next;
	while(other)
	{
		SORT_SWAP(other, e);
		other = e.sort_next;
	}
}

float RegisterTeam(entity Team)
{
	entity tm;
	for(tm = teams.sort_next; tm; tm = tm.sort_next)
		if(tm == Team)
			error("Team already registered!");
	Team.sort_next = teams.sort_next;
	Team.sort_prev = teams;
	if(teams.sort_next)
		teams.sort_next.sort_prev = Team;
	teams.sort_next = Team;
	return true;
}

void RemoveTeam(entity Team)
{
	entity tm, parent;
	parent = teams;
	for(tm = teams.sort_next; tm && tm != Team; tm = tm.sort_next)
		parent = tm;

	if(!tm)
	{
		print("Trying to remove a team which is not in the teamlist!");
		return;
	}
	parent.sort_next = Team.sort_next;
	if(Team.sort_next)
		Team.sort_next.sort_prev = parent;
}

entity GetTeam(float Team, float add)
{
	float num;
	entity tm;
	num = (Team == COLOR_SPECTATOR) ? 16 : Team;
	if(teamslots[num])
		return teamslots[num];
	if not(add)
		return NULL;
	tm = spawn();
	tm.team = Team;
	teamslots[num] = tm;
	RegisterTeam(tm);
	return tm;
}

void CSQC_CheckEngine()
{
	sbar_font = FONT_USER+1;
	sbar_bigfont = FONT_USER+2;
}

vector Sbar_GetFontsize(vector v)
{
	//vector v;
	//v = stov(cvar_string(cvarname));
	if(v_x == 0)
		v = '8 8 0';
	if(v_y == 0)
		v_y = v_x;
	v_z = 0;
	return v;
}

float Sbar_GetWidth(float teamcolumnwidth)
{
	float f;
	f = CVAR(sbar_width);
	if(f == 0)
		f = 640;
	if(f < 320)
		f = 320;
	if(f > CVAR(vid_conwidth) - 2 * teamcolumnwidth)
		f = CVAR(vid_conwidth) - 2 * teamcolumnwidth;
	return f;
}

float PreviewExists(string name)
{
	float f;
	string file;

	if (CVAR(cl_readpicture_force))
		return false;

	file = strcat(name, ".tga");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	file = strcat(name, ".png");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	file = strcat(name, ".jpg");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	file = strcat(name, ".pcx");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	return false;
}

vector rotate(vector v, float a)
{
	vector w;
	// FTEQCC SUCKS AGAIN
	w_x =      v_x * cos(a) + v_y * sin(a);
	w_y = -1 * v_x * sin(a) + v_y * cos(a);
	return w;
}

float ColorTranslateMode;

string ColorTranslateRGB(string s)
{
	if(ColorTranslateMode & 1)
		return strdecolorize(s);
	else
		return s;
}

vector project_3d_to_2d(vector vec)
{
	vec = cs_project(vec);
	if(cs_project_is_b0rked > 0)
	{
		vec_x *= CVAR(vid_conwidth) / vid_width;
		vec_y *= CVAR(vid_conheight) / vid_height;
	}
	return vec;
}

void dummyfunction(float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8)
{
}

float expandingbox_sizefactor_from_fadelerp(float fadelerp)
{
	return 1.2 / (1.2 - fadelerp);
}

vector expandingbox_resize_centered_box_offset(float sz, vector boxsize, float boxxsizefactor)
{
	boxsize_x *= boxxsizefactor; // easier interface for text
	return boxsize * (0.5 * (1 - sz));
}

void drawborderlines(float thickness, vector pos, vector dim, vector color, float alpha, float drawflag)
{
	vector line_dim;

	// left and right lines
	pos_x -= thickness;
	line_dim_x = thickness;
	line_dim_y = dim_y;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_x + thickness) * '1 0 0', line_dim, color, alpha, drawflag);

	// upper and lower lines
	pos_y -= thickness;
	line_dim_x = dim_x + thickness * 2; // make upper and lower lines longer
	line_dim_y = thickness;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_y + thickness) * '0 1 0', line_dim, color, alpha, drawflag);
}

void drawpic_tiled(vector pos, string pic, vector sz, vector area, vector color, float alpha, float drawflag)
{
	vector current_pos, end_pos, new_size, ratio;
	end_pos = pos + area;

	current_pos_y = pos_y;
	while (current_pos_y < end_pos_y)
	{
		current_pos_x = pos_x;
		while (current_pos_x < end_pos_x)
		{
			new_size_x = min(sz_x, end_pos_x - current_pos_x);
			new_size_y = min(sz_y, end_pos_y - current_pos_y);
			ratio_x = new_size_x / sz_x;
			ratio_y = new_size_y / sz_y;
			drawsubpic(current_pos, new_size, pic, '0 0 0', ratio, color, alpha, drawflag);
			current_pos_x += sz_x;
		}
		current_pos_y += sz_y;
	}
}

void drawpic_expanding(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	drawpic(position + expandingbox_resize_centered_box_offset(sz, scale, 1), pic, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void drawpic_expanding_two(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	drawpic_expanding(position, pic, scale, rgb, alpha, flag, fadelerp);
	drawpic(position, pic, scale, rgb, alpha * fadelerp, flag);
}

void drawstring_expanding(vector position, string text, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawstring(position + expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, FALSE)), text, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void drawcolorcodedstring_expanding(vector position, string text, vector scale, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawcolorcodedstring(position + expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, TRUE)), text, scale * sz, alpha * (1 - fadelerp), flag);
}

float TeamNumber(float t, float d) {
    switch(t) {
        case COLOR_TEAM1:
            return 1;
        case COLOR_TEAM2:
            return 2;
        case COLOR_TEAM3:
            return 3;
        case COLOR_TEAM4:
            return 4;
        default:
            return d;
    }
}

#define UnboundFromByte(x) ((x < 251) ? ftos(x) : ((x == 251) ? "250+" : ((x == 252) ? "500+" : ((x == 253) ? "1K+" : ((x == 254) ? "2K+" : "5K+")))))

#define rm_particleeffectnum_team(p,t,d) particleeffectnum(strcat(p "_TEAM", ftos(TeamNumber(t, d))))

void SUB_Null() { }
