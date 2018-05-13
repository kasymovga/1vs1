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

vector menuTooltipAveragedMousePos;
entity menuTooltipItem;
vector menuTooltipOrigin;
vector menuTooltipSize;
float menuTooltipAlpha;
float menuTooltipState; // 0: no tooltip, 1: fading in, 2: displaying, 3: fading out
float m_testmousetooltipbox(vector pos)
{
	if(pos_x >= menuTooltipOrigin_x && pos_x < menuTooltipOrigin_x + menuTooltipSize_x)
	if(pos_y >= menuTooltipOrigin_y && pos_y < menuTooltipOrigin_y + menuTooltipSize_y)
		return FALSE;
	return TRUE;
}
float m_testtooltipbox(vector tooltippos)
{
	if(tooltippos_x < 0)
		return FALSE;
	if(tooltippos_y < 0)
		return FALSE;
	if(tooltippos_x + menuTooltipSize_x > 1)
		return FALSE;
	if(tooltippos_y + menuTooltipSize_y > 1)
		return FALSE;
	/*
	menuTooltipOrigin_x = rint(tooltippos_x * cvar("vid_width")) / cvar("vid_width");
	menuTooltipOrigin_y = rint(tooltippos_y * cvar("vid_height")) / cvar("vid_height");
	menuTooltipOrigin_z = 0;
	*/
	menuTooltipOrigin = tooltippos;
	return TRUE;
}
float m_allocatetooltipbox(vector pos)
{
	vector avoidplus, avoidminus;
	vector v;

	avoidplus_x = (SKINAVOID_TOOLTIP_x + SKINSIZE_CURSOR_x - SKINOFFSET_CURSOR_x) / conwidth;
	avoidplus_y = (SKINAVOID_TOOLTIP_y + SKINSIZE_CURSOR_y - SKINOFFSET_CURSOR_y) / conheight;
	avoidplus_z = 0;

	avoidminus_x = (SKINAVOID_TOOLTIP_x + SKINOFFSET_CURSOR_x) / conwidth + menuTooltipSize_x;
	avoidminus_y = (SKINAVOID_TOOLTIP_y + SKINOFFSET_CURSOR_y) / conheight + menuTooltipSize_y;
	avoidminus_z = 0;

	// bottom right
	v = pos + avoidplus;
	if(m_testtooltipbox(v))
		return TRUE;
	
	// bottom center
	v_x = pos_x - menuTooltipSize_x * 0.5;
	if(m_testtooltipbox(v))
		return TRUE;

	// bottom left
	v_x = pos_x - avoidminus_x;
	if(m_testtooltipbox(v))
		return TRUE;

	// top left
	v_y = pos_y - avoidminus_y;
	if(m_testtooltipbox(v))
		return TRUE;

	// top center
	v_x = pos_x - menuTooltipSize_x * 0.5;
	if(m_testtooltipbox(v))
		return TRUE;
	
	// top right
	v_x = pos_x + avoidplus_x;
	if(m_testtooltipbox(v))
		return TRUE;
	
	return FALSE;
}
entity m_findtooltipitem(entity root, vector pos)
{
	entity it;
	entity best;

	best = world;
	it = root;

	while(it.instanceOfContainer)
	{
		while(it.instanceOfNexposee && it.focusedChild)
		{
			it = it.focusedChild;
			pos = globalToBox(pos, it.Container_origin, it.Container_size);
		}
		if(it.instanceOfNexposee)
		{
			it = it.itemFromPoint(it, pos);
			if(it.tooltip)
				best = it;
			it = world;
		}
		else if(it.instanceOfModalController)
			it = it.focusedChild;
		else
			it = it.itemFromPoint(it, pos);
		if(!it)
			break;
		if(it.tooltip)
			best = it;
		pos = globalToBox(pos, it.Container_origin, it.Container_size);
	}

	return best;
}
void m_tooltip(entity wnd, vector pos)
{
	float f, i, w;
	entity it;
	vector fontsize, p;
	string s;

	fontsize = '1 0 0' * (SKINFONTSIZE_TOOLTIP / conwidth) + '0 1 0' * (SKINFONTSIZE_TOOLTIP / conheight);

	f = bound(0, frametime * 2, 1);
	menuTooltipAveragedMousePos = menuTooltipAveragedMousePos * (1 - f) + pos * f;
	f = vlen(pos - menuTooltipAveragedMousePos);

	if(f < 0.01)
		it = m_findtooltipitem(wnd, pos);
	else	
		it = world;

	// float menuTooltipState; // 0: static, 1: fading in, 2: fading out
	if(it != menuTooltipItem)
	{
		switch(menuTooltipState)
		{
			case 0:
				if(menuTooltipItem)
				{
					// another item: fade out first
					menuTooltipState = 2;
				}
				else
				{
					// new item: fade in
					menuTooltipState = 1;
					menuTooltipItem = it;

					menuTooltipOrigin_x = -1; // unallocated
					i = 0;
					w =  0;
					getWrappedLine_remaining = it.tooltip;
					while(getWrappedLine_remaining)
					{
						s = getWrappedLine(SKINWIDTH_TOOLTIP / fontsize_x, draw_TextWidth_WithoutColors);
						++i;
						f = draw_TextWidth(s, FALSE);
						if(f > w)
							w = f;
					}
					menuTooltipSize_x = w * fontsize_x + 2 * (SKINMARGIN_TOOLTIP_x / conwidth);
					menuTooltipSize_y = i * fontsize_y + 2 * (SKINMARGIN_TOOLTIP_y / conheight);
					menuTooltipSize_z = 0;
				}
				break;
			case 1:
				// changing item while fading in: fade out first
				menuTooltipState = 2;
				break;
			case 2:
				// changing item while fading out: can't
				break;
		}
	}
	else if(menuTooltipState == 2) // re-fade in?
		menuTooltipState = 1;

	if(menuTooltipItem)
		if(!m_testmousetooltipbox(pos))
			menuTooltipState = 2; // fade out if mouse touches it

	switch(menuTooltipState)
	{
		case 1:
			menuTooltipAlpha = bound(0, menuTooltipAlpha + 5 * frametime, 1);
			if(menuTooltipAlpha == 1)
				menuTooltipState = 0;
			break;
		case 2:
			menuTooltipAlpha = bound(0, menuTooltipAlpha - 2 * frametime, 1);
			if(menuTooltipAlpha == 0)
			{
				menuTooltipState = 0;
				menuTooltipItem = world;
			}
			break;
	}

	if(menuTooltipItem)
	{
		if(menuTooltipOrigin_x < 0) // unallocated?
			m_allocatetooltipbox(pos);

		if(menuTooltipOrigin_x >= 0)
		{
			// draw the tooltip!
			p = SKINBORDER_TOOLTIP;
			p_x *= 1 / conwidth;
			p_y *= 1 / conheight;
			draw_BorderPicture(menuTooltipOrigin, SKINGFX_TOOLTIP, menuTooltipSize, '1 1 1', menuTooltipAlpha, p);
			p = menuTooltipOrigin;
			p_x += SKINMARGIN_TOOLTIP_x / conwidth;
			p_y += SKINMARGIN_TOOLTIP_y / conheight;
			getWrappedLine_remaining = menuTooltipItem.tooltip;
			while(getWrappedLine_remaining)
			{
				s = getWrappedLine(SKINWIDTH_TOOLTIP / fontsize_x, draw_TextWidth_WithoutColors);
				draw_Text(p, s, fontsize, '1 1 1', SKINALPHA_TOOLTIP * menuTooltipAlpha, FALSE);
				p_y += fontsize_y;
			}
		}
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
