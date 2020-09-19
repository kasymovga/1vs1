#ifdef CSQC
#define conwidth CVAR(vid_conwidth)
#define conheight CVAR(vid_conheight)
#endif
void m_focus_item_chain(entity outermost, entity innermost)
{
	if(innermost.parent != outermost)
		m_focus_item_chain(outermost, innermost.parent);
	innermost.parent.setFocus(innermost.parent, innermost);
}

void m_activate_window(entity wnd)
{
	entity par;
	par = wnd.parent;
	if(par)
		m_activate_window(par);

	if(par.instanceOfModalController)
	{
		if(wnd.tabSelectingButton)
			// tabs
			TabButton_Click(wnd.tabSelectingButton, wnd);
		else
			// root
			par.initializeDialog(par, wnd);
	}
	else if(par.instanceOfNexposee)
	{
		// nexposee (sorry for violating abstraction here)
		par.selectedChild = wnd;
		par.animationState = 1;
		setFocusContainer(par, NULL);
	}
	else if(par.instanceOfContainer)
	{
		// other containers
		if(par.focused)
			par.setFocus(par, wnd);
	}
}

void m_setpointerfocus(entity wnd)
{
	if(wnd.instanceOfContainer)
	{
		entity focus = wnd.preferredFocusedGrandChild(wnd);
		if(focus)
		{
#ifndef CSQC
			menuMousePos = focus.origin + 0.5 * focus.size;
			menuMousePos_x *= 1 / conwidth;
			menuMousePos_y *= 1 / conheight;
#endif
			if(wnd.focused) // why does this never happen?
				m_focus_item_chain(wnd, focus);
		}
	}
}

void drawBackground(string img, float a, float algn, float force1)
{
	vector sz;
	vector isz;
	vector tl, ce, br;
	vector v;
	string s;
	float i, f;
	sz = draw_PictureSize(img);
	// keep aspect of image
	if(sz_x * draw_scale_y >= sz_y * draw_scale_x)
	{
		// that is, sz_x/sz_y >= draw_scale_x/draw_scale_y
		// match up the height
		isz_y = 1;
		isz_x = isz_y * (sz_x / sz_y) * (draw_scale_y / draw_scale_x);
	}
	else
	{
		// that is, sz_x/sz_y <= draw_scale_x/draw_scale_y
		// match up the width
		isz_x = 1;
		isz_y = isz_x * (sz_y / sz_x) * (draw_scale_x / draw_scale_y);
	}
	tl = '0 0 0';
	ce = '0.5 0.5 0' - 0.5 * isz;
	br = '1 1 0' - isz;

	s = ftos(algn);
	v_z = 0;
	for(i = 0; i < strlen(s); ++i)
	{
		f = stof(substring(s, i, 1));
		switch(f)
		{
			case 1: case 4: case 7: v_x = tl_x; break;
			case 2: case 5: case 8: v_x = ce_x; break;
			case 3: case 6: case 9: v_x = br_x; break;
			default: v_x = tl_x + (br_x - tl_x) * random(); break;
		}
		switch(f)
		{
			case 7: case 8: case 9: v_y = tl_y; break;
			case 4: case 5: case 6: v_y = ce_y; break;
			case 1: case 2: case 3: v_y = br_y; break;
			default: v_y = tl_y + (br_y - tl_y) * random(); break;
		}
		if(i == 0)
			draw_Picture(v, img, isz, '1 1 1', a);
		else if(force1)
			// force all secondary layers to use alpha 1. Prevents ugly issues
			// with overlap. It's a flag because it cannot be used for the
			// ingame background
			draw_Picture(v, strcat(img, "_l", ftos(i+1)), isz, '1 1 1', 1);
		else
			draw_Picture(v, strcat(img, "_l", ftos(i+1)), isz, '1 1 1', a);
	}
}

#ifdef CSQC
#undef conwidth
#undef conheight
#endif

float almost_in_bounds(float a, float b, float c)
{
	float eps;
	eps = (max(a, -a) + max(c, -c)) * 0.001;
	return b == median(a - eps, b, c + eps);
}

float median(float a, float b, float c)
{
	if(a < c)
		return bound(a, b, c);
	return bound(c, b, a);
}
