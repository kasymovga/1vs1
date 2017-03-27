
#define NS_MAX_OPTIONS 16
#define NS_SCALE 24
#define NS_MARGIN 10

float ns_options[NS_MAX_OPTIONS*2];
float ns_selalpha[NS_MAX_OPTIONS*2];
float ns_numoptions;
float ns_active;
float ns_alpha;
float ns_width;
float ns_height;
float ns_selected;
float ns_selected_in;
float ns_confirmed1;
float ns_confirmed2;

float g_nadgets_double;

void NS_UpdateSelection(vector o, vector s) {
    if(g_nadgets_double)
        ns_selected_in = (mouse_pos_x > CVAR(vid_conwidth) * 0.5);
    else
        ns_selected_in = 0;

    ns_selected = floor(ns_numoptions * ((bound(o_y, mouse_pos_y, o_y + s_y) - o_y) / s_y));
    ns_selected = min(ns_numoptions - 1, ns_selected);
}

string firstkeyfor(string cmds) {
    float i, k;
    float ncmds = tokenize(cmds), nkeys;

    for(i = 0; i < ncmds; ++i) {
        nkeys = tokenize(findkeysforcommand(argv(0)));
        for(k = 0; k < nkeys; ++k)
            if(stof(argv(k)) >= 0)
                return keynumtostring(stof(argv(k)));

        ncmds = tokenize(cmds);
    }

    return argv(0);
}

float NS_InputEvent(float bInputType, float nPrimary, float nSecondary);
void NS_Draw(void) {
    if(ns_active)
        ns_alpha = approach(ns_alpha, 1, frametime * 5);
    else
        ns_alpha = approach(ns_alpha, 0, frametime * 7);

    if(!ns_alpha) {
		remove(self);
        return;
	}
	Mouse_Enable();
	CSQC_InputEvent_Callback = NS_InputEvent;

    float a = ns_alpha;

    drawfont = sbar_bigfont;
    drawfill('0 0', '1 0' * CVAR(vid_conwidth) + '0 1' * CVAR(vid_conheight), '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);

    vector o;
	o_x = (CVAR(vid_conwidth) - ns_width) * 0.5;
	o_y = (CVAR(vid_conheight) - ns_height) * 0.5;
	o_z = 0;
    vector s;
	s_x = ns_width;
	s_y = ns_height;
	s_z = 0;

    if(ns_active)
        NS_UpdateSelection(o, s);

    vector sz;
	sz_x = NS_SCALE;
	sz_y = NS_SCALE;

    drawstringcenter(o_x * '1 0' + (o_y - sz_y * (1.25 + 2 * g_nadgets_double)) * '0 1', "Nadget Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);

	float table, tables;
    for(table = 0; table < (tables = g_nadgets_double + 1); ++table) {
        o_x = (CVAR(vid_conwidth) * 0.5) - (1 * tables * 0.5 - 1 * table) * (ns_width + NS_MARGIN);

        drawfill(o, s, '0 0 0', 0.3, DRAWFLAG_NORMAL);
        drawborderlines(2, o, s, '0 0 0', a, DRAWFLAG_NORMAL);

        string txt;
        float txtw;

        if(g_nadgets_double) {
            txt = (table ? "Secondary" : "Primary");
            txtw = stringwidth(txt, FALSE) * sz_x;
            drawstring((o_x + (s_x - txtw) * 0.5) * '1 0' + (o_y - sz_y * 1.25) * '0 1', txt, sz, '1 1 1', a, DRAWFLAG_NORMAL);
        }

        txt = strcat("Key: ^2", strtoupper(firstkeyfor((table ? "'+nadget2' '+button9'" : "'+nadget' '+hook' '+button6'"))));

        txtw = stringwidth(txt, TRUE) * sz_x;
        drawcolorcodedstring((o_x + (s_x - txtw) * 0.5) * '1 0' + (o_y + s_y + NS_MARGIN * 0.5) * '0 1', txt, sz, a, DRAWFLAG_NORMAL);

        float confirmed = (table ? ns_confirmed2 : ns_confirmed1);
        float confirmedOther = (table ? ns_confirmed1 : ns_confirmed2);

		float i;
        for(i = 0; i < ns_numoptions; ++i) {
            float sidx = i + NS_MAX_OPTIONS * table;
            float t = ns_options[sidx];

            if(t < 0)
                break;

            vector p;
            float a2 = ns_selalpha[sidx];
            float isConfirmed = t == confirmed;
            float isSelected = i == ns_selected && ns_selected_in == table;

            vector clr = (((confirmed < 0 || isConfirmed || isSelected) && (t != confirmedOther || t == HG_RANDOM)) ?
					HG_TypeToColor(t) * (0.5 + 0.5 * a2) :
					'0.1 0.1 0.1');

            if(isConfirmed || isSelected) {
                ns_selalpha[sidx] = approach(ns_selalpha[sidx], 1, frametime * 3);
                p_x = o_x;
				p_y = o_y + i * sz_y + NS_MARGIN * 0.5;
                drawfill(p, (s_x * '1 0' + sz_y * '0 1'), clr, 0.2 * a, DRAWFLAG_NORMAL);
            } else
                ns_selalpha[sidx] = approach(ns_selalpha[sidx], 0, frametime * 3);

            p_x = o_x + NS_MARGIN * 0.5;
			p_y = o_y + i * sz_y + NS_MARGIN * 0.5;

            if(t == HG_RANDOM) {
                p_x = p_x + (sz_x - stringwidth("?", FALSE) * sz_x) * 0.5;
                drawstring(p, "?", sz, clr, a, DRAWFLAG_NORMAL);
            } else {
                drawpic(p, HG_TypeToIcon(t, TRUE, FALSE), sz, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);
            }

            p_x = NS_MARGIN * 0.5 + o_x + sz_x;
            drawstring(p, HG_TypeToExpandedName(t), sz, clr, a, DRAWFLAG_NORMAL);

            if(i < 10) {
                txt = ((i == 9) ? "0" : ftos(i + 1));
                txtw = stringwidth(txt, FALSE) * sz_x * 0.5;
                drawstring((o_x + s_x - txtw) * '1 0' + p_y * '0 1', txt, sz * 0.5, '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);     
            }
        }
    }

    drawfont = sbar_font;
}

void NS_ConfirmSelection(void) {
    if(ns_selected_in) {
        ns_confirmed2 = ns_options[NS_MAX_OPTIONS + ns_selected];
        if(ns_confirmed2 == ns_confirmed1 && ns_confirmed2 != HG_RANDOM)
            ns_confirmed1 = -1;
    } else {
        ns_confirmed1 = ns_options[ns_selected];
        if(ns_confirmed1 == ns_confirmed2 && ns_confirmed1 != HG_RANDOM)
            ns_confirmed2 = -1;
    }

    if(!g_nadgets_double || (ns_confirmed1 >= 0 && ns_confirmed2 >= 0)) {
        string cmd = strcat("cmd picknade ", HG_TypeToName(ns_confirmed1));
        if(ns_confirmed2 >= 0)
            cmd = strcat(cmd, " ", HG_TypeToName(ns_confirmed2));
        cmd = strcat(cmd, "; cmd join\n");
        localcmd(cmd);
        ns_active = FALSE;
    }
}

float NS_InputEvent(float bInputType, float nPrimary, float nSecondary) {
    if(!ns_active)
        return FALSE;

    if(bInputType == 2)
        return TRUE;

    if(bInputType == 0) {
        if(nPrimary == K_ESCAPE) {
            if(ns_confirmed2 >= 0)
                ns_confirmed2 = -1;
            else if(ns_confirmed1 >= 0)
                ns_confirmed1 = -1;
            else {
                ns_active = FALSE;
            }

            return TRUE;
        }

        if(nPrimary == K_MOUSE1) {
            NS_ConfirmSelection();
            return TRUE;
        }

        if(nPrimary >= '0' && nPrimary <= '9') {
            ns_selected = nPrimary - '0';

            if(!ns_selected)
                ns_selected = 10;
            else
                --ns_selected;

            ns_selected = bound(0, ns_selected, ns_numoptions - 1);
            ns_selected_in = 0;

            if(ns_confirmed1 >= 0)
                ++ns_selected_in;

            NS_ConfirmSelection();
        }
    }

    return FALSE;
}

void Net_ReadNadgetSelect(void) {
    string opts_pri, opts_sec;

	if (ReadByte())
		g_nadgets_double = 1;

    opts_pri = ReadString();
    if(g_nadgets_double)
        opts_sec = ReadString();

    if(isdemo())
        return;

    if(!ns_active) {
        ns_confirmed1 = ns_confirmed2 = -1;
    }

    ns_width = 0;
    ns_numoptions = 0;

	float oldfont = drawfont;
    drawfont = sbar_bigfont;
	float table;
	for(table = 0; table < 2; ++table) {
        ns_numoptions = max(ns_numoptions, tokenizebyseparator((table ? opts_sec : opts_pri), " "));

		float i;
        for(i = 0; i < NS_MAX_OPTIONS; ++i) {
            string typename = argv(i);
            float idx = i + table * NS_MAX_OPTIONS;
            float valid = (typename != "");

            if(valid)
                ns_options[idx] = HG_NameToType(typename);
            else
                ns_options[idx] = -1;

            if(!ns_active)
                ns_selalpha[idx] = 0;

            if(!valid)
                continue;

            ns_width = max(ns_width, NS_SCALE + stringwidth(HG_TypeToExpandedName(ns_options[idx]), FALSE) * NS_SCALE);
        }
    }
	drawfont = oldfont;

    ns_height = NS_SCALE * ns_numoptions + NS_MARGIN;
    ns_width += NS_MARGIN;
    ns_active = TRUE;
	entity e = spawn();
	e.draw2d = NS_Draw;
}
