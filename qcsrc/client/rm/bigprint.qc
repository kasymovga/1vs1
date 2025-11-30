float rm_bigprint_noold;
float rm_bigprint_draw_flag;
float rm_bigprint_old_draw;
float rm_bigprint_comment_draw;
float rm_bigprint_oldfadetime;
string rm_bigprint_oldstring;
float rm_bigprint_oldappeartime;
string rm_bigprint_string;
float rm_bigprint_fadetime;
float rm_bigprint_appeartime;
string rm_bigprint_comment;
float rm_bigprint_commentfadetime;
float rm_bigprint_commentappeartime;

void(string bigstr, string comment, float fadeTime) rm_bigprint_old {
	//if(is_tmpmadoka) return;
	rm_bigprint_old_draw = 1;
	str_unzone_ifneeded(rm_bigprint_oldstring);
	rm_bigprint_oldstring = str_zone_ifneeded(bigstr);
	rm_bigprint_oldfadetime = fadeTime - 0.1;
	rm_bigprint_oldappeartime = time;
}

void(string bigstr, string comment, float staytime) rm_bigprint {
	float no = FALSE;
	if (staytime < 0) {
		staytime = -staytime;
		no = TRUE;
	}
	if (CVAR(rm_nobigtext)) {
		string s;
		s = bigstr;
		if(comment != "") {
			if(s == "")
				s = comment;
			else
				s = strcat(s, "\n", comment);
		}
		centerprint(s);
		return;
	}
	if (bigstr != "") {
		rm_bigprint_draw_flag = 1;
		if (!rm_bigprint_noold)
			rm_bigprint_old(rm_bigprint_string, rm_bigprint_comment, rm_bigprint_fadetime);
		
		str_unzone_ifneeded(rm_bigprint_string);
		rm_bigprint_string = str_zone_ifneeded(bigstr);
		rm_bigprint_fadetime = time + staytime;
		rm_bigprint_appeartime = time;
	}
	rm_bigprint_noold = no;
	if (comment != "") {
		rm_bigprint_comment_draw = 1;
		str_unzone_ifneeded(rm_bigprint_comment);
		rm_bigprint_comment = str_zone_ifneeded(comment);
		rm_bigprint_commentfadetime = time + staytime;
		rm_bigprint_commentappeartime = time;
	}
}

void(void) rm_bigprint_draw {
	float i;
	float bp_alpha, bp_ypos;
	vector bp_pos;
	bp_ypos = (CVAR(vid_conheight) / 5) * (1 - sbar_scoreboard_fade_alpha)
			+ (SBAR_SCOREBOARD_OFFSET) * (sbar_scoreboard_fade_alpha);
	if (rm_bigprint_old_draw)
	if (rm_bigprint_oldstring) {
		bp_alpha = bound(0, 1 - 4 * (time - rm_bigprint_oldfadetime), 1);

		if (bp_alpha > 0) {
			bp_pos = '0 1 0' * bp_ypos;
			bp_pos_y -= 24 * (CVAR(rm_simpleeffects) ? 1 : (1 - bound(0, 1 - 4 * (time - rm_bigprint_oldappeartime), 1)));
			drawfont = sbar_bigfont;

			if (CVAR(rm_simpleeffects))
				draw_string_colorcoded_center(bp_pos, rm_bigprint_oldstring, '24 24 0', bp_alpha, DRAWFLAG_NORMAL);
			else
				draw_string_colorcoded_center(bp_pos, rm_bigprint_oldstring, '24 24 0' * (1.0 + (1.0 - bp_alpha)), bp_alpha, DRAWFLAG_NORMAL);

			drawfont = sbar_font;
			//comment for oldbigprint is not displayed
		} else
			rm_bigprint_old_draw = 0;
	}
	bp_pos = '0 1 0' * bp_ypos;
	if (rm_bigprint_draw_flag)
	if (rm_bigprint_string) {
		for (i = 0; i < 2; ++i) {
			if (CVAR(rm_simpleeffects)) if(i)
				break;

			bp_alpha = bound(0, 1 - 4 * (time - (i ? rm_bigprint_appeartime : rm_bigprint_fadetime)), 1);
			if (bp_alpha > 0) {
				drawfont = sbar_bigfont;
				if (CVAR(rm_simpleeffects))
					draw_string_colorcoded_center(bp_pos, rm_bigprint_string, '24 24 0', bp_alpha, DRAWFLAG_NORMAL);
				else {
					vector sz;
					#if 0 //FIXME
					if (tmpmadoka_fadetime >= time) {
						string mycolor;
						string mychar;
						vector offset;
						float j;
						bp_pos_x = 0.5 * (vid_conwidth - 0.6025 * strlennocol(rm_bigprint_string) * 24);
						for(j = 0; j < strlen(rm_bigprint_string); ++j) {
							mychar = substring(rm_bigprint_string, j, 1);
							if(mychar == "^") {
								if(substring(rm_bigprint_string, j+1, 1) == "x") {
									mycolor = substring(rm_bigprint_string, j, 5);
									j += 5;
								} else {
									mycolor = substring(rm_bigprint_string, j, 2);
									++j;
								}
								continue;
							}
							offset_y = 3 * cos(bp_pos_x + 5 * time) * (if(mod(j, 2)) 1 else -1);
							offset_x = offset_y * (if(mod(j, 2)) -1 else 1);
							string resultstr = strcat(mycolor, mychar);
							sz = '24 24 0' * (1.0 + (1.0 - bp_alpha));
							bp_pos_x += stringwidth(resultstr, TRUE, sz);
							drawcolorcodedstring(bp_pos + offset, resultstr, sz, bp_alpha, DRAWFLAG_NORMAL);
						}
					} else {
					#endif
						//sz = '24 24 0' * (1.0 + ipol_powIn(3, 1.0 - bp_alpha)); //FIXME
						sz = '24 24 0' * (2 - bp_alpha);
						draw_string_colorcoded_center(bp_pos - sz * 0.25 * (1 - bp_alpha), rm_bigprint_string, sz, bp_alpha, DRAWFLAG_NORMAL);
					#if 0
					}
					#endif
				}
				drawfont = sbar_font;
			} else if(!i)
				rm_bigprint_draw_flag = 0;
		}
	}
	if (rm_bigprint_comment_draw)
	if (rm_bigprint_comment != "")
	if (!CVAR(rm_hidebigcomments)) {
		bp_pos_y += 24;
		for (i = 0; i < (CVAR(rm_simpleeffects) ? 1 : 2); ++i) {
			if(CVAR(rm_simpleeffects)) if(i)
				break;

			bp_alpha = bound(0, 1 - 4 * (time - (i ? rm_bigprint_commentappeartime : rm_bigprint_commentfadetime)), 1);
			if (bp_alpha) {
				if(CVAR(rm_simpleeffects))
					draw_string_colorcoded_center(bp_pos, rm_bigprint_comment, sbar_fontsize, bp_alpha, DRAWFLAG_NORMAL);
				else
					draw_string_colorcoded_center(bp_pos, rm_bigprint_comment, sbar_fontsize * (1.0 + (1.0 - bp_alpha)), bp_alpha, DRAWFLAG_NORMAL);
			} else if(!i)
				rm_bigprint_comment_draw = 0;
		}
	}
}

void(void) rm_bigprint_read {
	rm_bigprint(net_read_string(), net_read_string(), net_read_short());
}

entity rm_bigprint_controller;
void(void) rm_bigprint_enable {
	if (rm_bigprint_controller) return;
	rm_bigprint_controller = spawn();
	rm_bigprint_controller.draw2d = rm_bigprint_draw;
	rm_bigprint_controller.draw2dflag = 2;
}
