#define WS_MAXOPTIONS 8
#define WS_SCALE NS_SCALE
#define WS_MARGIN NS_MARGIN

float ws_selalpha[WS_MAXOPTIONS];
float ws_numoptions;
float ws_active;
float ws_alpha;
float ws_width;
float ws_height;
float ws_selected;
float selectable_weapons;

void WS_UpdateSelection(vector o, vector s) {
	vector v = mouse_position();
    ws_selected = floor(ws_numoptions * ((bound(o_y, v_y, o_y + s_y) - o_y) / s_y));
    ws_selected = min(ws_numoptions - 1, ws_selected);
}

float WS_SelectedWeapon(void) {
    for(var n = 0, var w = 0; w <= WEP_LAST; ++w) {
        if(pow(2, w) & selectable_weapons) {
            if(n == ws_selected)
                return w;
            ++n;
        }
    }

    return -1;
}

float WS_InputEvent(float bInputType, float nPrimary, float nSecondary);
void WS_Draw(void) {
    if(ws_active) {
        ws_alpha = approach(ws_alpha, 1, frametime * 5);
		input_event_callback = WS_InputEvent;
    } else
        ws_alpha = approach(ws_alpha, 0, frametime * 7);

    if(!ws_alpha) {
		remove(self);
        return;
	}
	Mouse_Enable();
	sbar_hidescores = TRUE;
    var a = ws_alpha;

    drawfont = sbar_bigfont;
    drawfill('0 0', [CVAR(vid_conwidth), CVAR(vid_conheight)], '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);

    vector o = [CVAR(vid_conwidth) - ws_width, CVAR(vid_conheight) - ws_height] * 0.5;
    vector s = [ws_width, ws_height];

    if(ws_active)
        WS_UpdateSelection(o, s);

    vector sz = [WS_SCALE, WS_SCALE];
    draw_string_center([0, o_y - sz_y * 1.25], "Weapon Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);
    o_x = (CVAR(vid_conwidth) * 0.5) - 0.5 * (ws_width + WS_MARGIN);

    drawfill(o, s, '0 0 0', 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, o, s, '0 0 0', a, DRAWFLAG_NORMAL);

    string txt;
    float txtw;

    //txt = strcat("Key: ^2", strtoupper(firstkeyfor("+attack2")));

    //txtw = stringwidth(txt, TRUE, sz);
    //drawcolorcodedstring([o_x + (s_x - txtw) * 0.5, o_y + s_y + WS_MARGIN * 0.5], txt, sz, a, DRAWFLAG_NORMAL);

    for(var i = 0, var w = 0; w <= WEP_LAST; ++w) {
        if(!(pow(2, w) & selectable_weapons))
            continue;

        var sidx = i;
        entity winfo = weapon_info(w + 1);

        vector p;
        float a2 = ws_selalpha[sidx];
        float isSelected = i == ws_selected;

        vector clr = winfo.colormod * (0.5 + 0.5 * a2);

        if(isSelected) {
            ws_selalpha[sidx] = approach(ws_selalpha[sidx], 1, frametime * 3);
            p = [o_x, o_y + i * sz_y + WS_MARGIN * 0.5];
            drawfill(p, [s_x, sz_y], clr, 0.2 * a, DRAWFLAG_NORMAL);
        } else
            ws_selalpha[sidx] = approach(ws_selalpha[sidx], 0, frametime * 3);

        p = [o_x + WS_MARGIN * 0.5, o_y + i * sz_y + WS_MARGIN * 0.5];
        drawpic(p, strcat("gfx/hud/inv_weapon", ftos(w)), '2 1 0' * WS_SCALE, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);

        p_x = WS_MARGIN * 0.5 + o_x + sz_x * 2;
        drawstring(p, winfo.message, sz, clr, a, DRAWFLAG_NORMAL);

        if(i < 10) {
            txt = if(i == 9) "0" else ftos(i + 1);
            txtw = stringwidth(txt, FALSE) * sz_x * 0.5;
            drawstring([o_x + s_x - txtw, p_y], txt, sz * 0.5, '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);     
        }

        if(++i == WS_MAXOPTIONS)
            break;
    }

    drawfont = sbar_font;
}

void WS_ConfirmSelection(void) {
    var w = weapon_info(WS_SelectedWeapon() + 1);
    localcmd("cmd pickweapon ", w.netname, "; cmd join\n");
    ws_active = FALSE;
}

float WS_InputEvent(float bInputType, float nPrimary, float nSecondary) {
    if(!ws_active)
        return FALSE;

    if(bInputType == 2)
        return TRUE;

    if(bInputType == 0) {
        if(nPrimary == K_ESCAPE) {
            ws_active = FALSE;
            return TRUE;
        }

        if(nPrimary == K_MOUSE1) {
			vector o = [CVAR(vid_conwidth) - ws_width, CVAR(vid_conheight) - ws_height] * 0.5;
			vector s = [ws_width, ws_height];
			WS_UpdateSelection(o, s);
            WS_ConfirmSelection();
            return TRUE;
        }

        if(nPrimary >= '0' && nPrimary <= '9') {
            ws_selected = nPrimary - '0';

            if(!ws_selected)
                ws_selected = 10;
            else
                --ws_selected;

            ws_selected = bound(0, ws_selected, ws_numoptions - 1);
            WS_ConfirmSelection();
        }
    }

    return FALSE;
}

void Net_ReadWeaponSelect(void) {
    selectable_weapons = net_read_int24();
	if (ws_active)
		return;

    if(isdemo_flag)
        return;

    ws_width = 0;
    ws_numoptions = 0;

    using(drawfont = sbar_bigfont) for(var w = 0; w <= WEP_LAST; ++w) {
        if(pow(2, w) & selectable_weapons) {
            ++ws_numoptions;
            ws_width = max(ws_width, WS_SCALE * 2 + stringwidth(weapon_info(w+1).message, FALSE) * WS_SCALE);
        }
    }

    ws_height = WS_SCALE * ws_numoptions + WS_MARGIN;
    ws_width += WS_MARGIN;
    ws_active = TRUE;
	entity e = spawn();
	e.draw2d = WS_Draw;
	e.draw2dflag = 1;
}
