string gui_draw_mousepointer;
vector gui_draw_mousepointer_offset;
vector gui_draw_mousepointer_size;

string(string pic) gui_image_path {
	if(substring(pic, 0, 1) == "/")
		return substring(pic, 1, strlen(pic)-1);
	else
		return strcat(skin_current, "/", pic);
}

void(string pic, vector theSize, vector theOffset) gui_set_mouse_pointer {
	gui_draw_mousepointer = strzone(gui_image_path(pic));
	gui_draw_mousepointer_size = theSize;
	gui_draw_mousepointer_offset = eX * (theOffset_x * theSize_x) + eY * (theOffset_y * theSize_y);
}

void(vector where) gui_draw_mouse_pointer {
	drawpic(gui_box_to_global(where, gui_draw_shift, gui_draw_scale) - gui_draw_mousepointer_offset, gui_draw_mousepointer, gui_draw_mousepointer_size, '1 1 1', gui_draw_alpha, 0);
}

void(void) gui_draw_reset {
	if (cvar("utf8_oldfont_for_oldchars") && cvar("font3_is_unicode_compat"))
		drawfont = FONT_USER + 3;
	else
		drawfont = FONT_USER + 0;

	gui_draw_shift = '0 0 0';
	gui_draw_scale = '1 0 0' * cvar("vid_conwidth") + '0 1 0' * cvar("vid_conheight");
	gui_draw_alpha = 1;
}

vector(vector v, vector theOrigin, vector theScale) gui_global_to_box {
	v -= theOrigin;
	v_x /= theScale_x;
	v_y /= theScale_y;
	return v;
}

vector(vector v, vector theScale) gui_global_to_box_size {
	v_x /= theScale_x;
	v_y /= theScale_y;
	return v;
}

vector(vector v, vector theOrigin, vector theScale) gui_box_to_global {
	v_x *= theScale_x;
	v_y *= theScale_y;
	v += theOrigin;
	return v;
}

vector(vector v, vector theScale) gui_box_to_global_size {
	v_x *= theScale_x;
	v_y *= theScale_y;
	return v;
}

void(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha) gui_draw_picture {
	pic = gui_image_path(pic);
	drawpic(gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale), pic, gui_box_to_global_size(theSize, gui_draw_scale), theColor, theAlpha * gui_draw_alpha, 0);
}

vector(string pic) gui_picture_size {
	pic = gui_image_path(pic);
	return drawgetimagesize(pic);
}

void(vector theOrigin, vector theSize, vector theColor, float theAlpha) gui_draw_fill {
	drawfill(gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale), gui_box_to_global_size(theSize, gui_draw_scale), theColor, theAlpha * gui_draw_alpha, 0);
}

// a button picture is a texture containing three parts:
//   1/4 width: left part
//   1/2 width: middle part (stretched)
//   1/4 width: right part
// it is assumed to be 4x as wide as high for aspect ratio purposes, which
// means, the parts are a square, two squares and a square.
void(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha) gui_draw_button_picture {
	vector square;
	vector width, height;
	vector bW;
	pic = gui_image_path(pic);
	theOrigin = gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale);
	theSize = gui_box_to_global_size(theSize, gui_draw_scale);
	theAlpha *= gui_draw_alpha;
	width = eX * theSize_x;
	height = eY * theSize_y;
	if (theSize_x <= theSize_y * 2) {
		// button not wide enough
		// draw just left and right part then
		square = eX * theSize_x * 0.5;
		bW = eX * (0.25 * theSize_x / (theSize_y * 2));
		drawsubpic(theOrigin,          square + height, pic, '0 0 0', eY + bW, theColor, theAlpha, 0);
		drawsubpic(theOrigin + square, square + height, pic, eX - bW, eY + bW, theColor, theAlpha, 0);
	} else {
		square = eX * theSize_y;
		drawsubpic(theOrigin,                  height  +     square, pic, '0    0 0', '0.25 1 0', theColor, theAlpha, 0);
		drawsubpic(theOrigin +         square, theSize - 2 * square, pic, '0.25 0 0', '0.5  1 0', theColor, theAlpha, 0);
		drawsubpic(theOrigin + width - square, height  +     square, pic, '0.75 0 0', '0.25 1 0', theColor, theAlpha, 0);
	}
}

// a vertical button picture is a texture containing three parts:
//   1/4 height: left part
//   1/2 height: middle part (stretched)
//   1/4 height: right part
// it is assumed to be 4x as high as wide for aspect ratio purposes, which
// means, the parts are a square, two squares and a square.
void(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha) gui_draw_button_picture_vertical {
	vector square;
	vector width, height;
	vector bH;
	pic = gui_image_path(pic);
	theOrigin = gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale);
	theSize = gui_box_to_global_size(theSize, gui_draw_scale);
	theAlpha *= gui_draw_alpha;
	width = eX * theSize_x;
	height = eY * theSize_y;
	if (theSize_y <= theSize_x * 2) {
		// button not high enough
		// draw just upper and lower part then
		square = eY * theSize_y * 0.5;
		bH = eY * (0.25 * theSize_y / (theSize_x * 2));
		drawsubpic(theOrigin,          square + width, pic, '0 0 0', eX + bH, theColor, theAlpha, 0);
		drawsubpic(theOrigin + square, square + width, pic, eY - bH, eX + bH, theColor, theAlpha, 0);
	} else {
		square = eY * theSize_x;
		drawsubpic(theOrigin,                   width   +     square, pic, '0 0    0', '1 0.25 0', theColor, theAlpha, 0);
		drawsubpic(theOrigin +          square, theSize - 2 * square, pic, '0 0.25 0', '1 0.5  0', theColor, theAlpha, 0);
		drawsubpic(theOrigin + height - square, width   +     square, pic, '0 0.75 0', '1 0.25 0', theColor, theAlpha, 0);
	}
}

// a border picture is a texture containing nine parts:
//   1/4 width: left part
//   1/2 width: middle part (stretched)
//   1/4 width: right part
// divided into
//   1/4 height: top part
//   1/2 height: middle part (stretched)
//   1/4 height: bottom part
void(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha, vector theBorderSize) gui_draw_picture_border {
	vector dX, dY;
	vector width, height;
	vector bW, bH;
	pic = gui_image_path(pic);
	theOrigin = gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale);
	theSize = gui_box_to_global_size(theSize, gui_draw_scale);
	theBorderSize = gui_box_to_global_size(theBorderSize, gui_draw_scale);
	theAlpha *= gui_draw_alpha;
	width = eX * theSize_x;
	height = eY * theSize_y;
	if (theSize_x <= theBorderSize_x * 2) {
		// not wide enough... draw just left and right then
		bW = eX * (0.25 * theSize_x / (theBorderSize_x * 2));
		if (theSize_y <= theBorderSize_y * 2) {
			// not high enough... draw just corners
			bH = eY * (0.25 * theSize_y / (theBorderSize_y * 2));
			drawsubpic(theOrigin,                 width * 0.5 + height * 0.5, pic, '0 0 0',           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width   * 0.5, width * 0.5 + height * 0.5, pic, eX - bW,           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + height  * 0.5, width * 0.5 + height * 0.5, pic, eY - bH,           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + theSize * 0.5, width * 0.5 + height * 0.5, pic, eX + eY - bW - bH, bW + bH, theColor, theAlpha, 0);
		} else {
			dY = theBorderSize_x * eY;
			drawsubpic(theOrigin,                             width * 0.5          +     dY, pic, '0 0    0',           '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5,               width * 0.5          +     dY, pic, '0 0    0' + eX - bW, '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin                        + dY, width * 0.5 + height - 2 * dY, pic, '0 0.25 0',           '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5          + dY, width * 0.5 + height - 2 * dY, pic, '0 0.25 0' + eX - bW, '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin               + height - dY, width * 0.5          +     dY, pic, '0 0.75 0',           '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5 + height - dY, width * 0.5          +     dY, pic, '0 0.75 0' + eX - bW, '0 0.25 0' + bW, theColor, theAlpha, 0);
		}
	} else {
		if (theSize_y <= theBorderSize_y * 2) {
			// not high enough... draw just top and bottom then
			bH = eY * (0.25 * theSize_y / (theBorderSize_y * 2));
			dX = theBorderSize_x * eX;
			drawsubpic(theOrigin,                                         dX + height * 0.5, pic, '0    0 0',           '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + dX,                        width - 2 * dX + height * 0.5, pic, '0.25 0 0',           '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width - dX,                            dX + height * 0.5, pic, '0.75 0 0',           '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin              + height * 0.5,             dX + height * 0.5, pic, '0    0 0' + eY - bH, '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + dX         + height * 0.5, width - 2 * dX + height * 0.5, pic, '0.25 0 0' + eY - bH, '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width - dX + height * 0.5,             dX + height * 0.5, pic, '0.75 0 0' + eY - bH, '0.25 0 0' + bH, theColor, theAlpha, 0);
		} else {
			dX = theBorderSize_x * eX;
			dY = theBorderSize_x * eY;
			drawsubpic(theOrigin,                                        dX          +     dY, pic, '0    0    0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin                  + dX,      width - 2 * dX          +     dY, pic, '0.25 0    0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + width - dX,                  dX          +     dY, pic, '0.75 0    0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY,                          dX + height - 2 * dY, pic, '0    0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY         + dX, width - 2 * dX + height - 2 * dY, pic, '0.25 0.25 0', '0.5  0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY + width - dX,             dX + height - 2 * dY, pic, '0.75 0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY,                          dX          +     dY, pic, '0    0.75 0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY         + dX, width - 2 * dX          +     dY, pic, '0.25 0.75 0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY + width - dX,             dX          +     dY, pic, '0.75 0.75 0', '0.25 0.25 0', theColor, theAlpha, 0);
		}
	}
}
void(vector theOrigin, string theText, vector theSize, vector theColor, float theAlpha, float ICanHasKallerz) gui_draw_text {
	if (theSize_x <= 0 || theSize_y <= 0) {
		print("theSize=", vtos(theSize), "\n");
		print("gui_conwidth=", ftos(gui_conwidth), "\n");
		print("gui_conheight=", ftos(gui_conheight), "\n");
		error("Drawing zero size text?\n");
	}
	if (ICanHasKallerz)
		drawcolorcodedstring(gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale), theText, gui_box_to_global_size(theSize, gui_draw_scale), theAlpha * gui_draw_alpha, 0);
	else
		drawstring(gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale), theText, gui_box_to_global_size(theSize, gui_draw_scale), theColor, theAlpha * gui_draw_alpha, 0);
}

void(vector theOrigin, string theText, vector theSize, vector theColor, float theAlpha, float ICanHasKallerz) gui_draw_text_center {
	gui_draw_text(theOrigin - eX * theSize_x * 0.5 * gui_text_width(theText, ICanHasKallerz), theText, theSize, theColor, theAlpha, ICanHasKallerz);
}

float gui_text_width(string theText, float ICanHasKallerz) {
	//return strlen(theText);
	//print("gui_text_width \"", theText, "\"\n");
	return stringwidth(theText, ICanHasKallerz);
}

float gui_draw_clip_setted;
void(void) gui_draw_set_clip {
	if (gui_draw_clip_setted)
		error("Already clipping, no stack implemented here, sorry");

	drawsetcliparea(gui_draw_shift_x, gui_draw_shift_y, gui_draw_scale_x, gui_draw_scale_y);
	gui_draw_clip_setted = 1;
}

void(vector theOrigin, vector theScale) gui_draw_set_clip_rect {
	vector o, s;
	if (gui_draw_clip_setted)
		error("Already clipping, no stack implemented here, sorry");

	o = gui_box_to_global(theOrigin, gui_draw_shift, gui_draw_scale);
	s = gui_box_to_global_size(theScale, gui_draw_scale);
	drawsetcliparea(o_x, o_y, s_x, s_y);
	gui_draw_clip_setted = 1;
}

void(void) gui_draw_clip_clear {
	if (!gui_draw_clip_setted)
		error("Not clipping, can't clear it then");

	drawresetcliparea();
	gui_draw_clip_setted = 0;
}

string(string theText, float maxWidth, float ICanHasKallerz) gui_draw_text_shorten_to_width {
	if(gui_text_width(theText, ICanHasKallerz) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, gui_draw_text_length_up_to_width(theText, maxWidth - gui_text_width("...", ICanHasKallerz), ICanHasKallerz)), "...");
}

float(string s) gui_text_width_with_colors {
	return gui_text_width(s, TRUE);
}

float(string s) gui_text_width_without_colors {
	return gui_text_width(s, FALSE);
}

float(string theText, float maxWidth, float allowColorCodes) gui_draw_text_length_up_to_width {
	if(allowColorCodes)
		return str_length_up_to_width(theText, maxWidth, gui_text_width_with_colors);
	else
		return str_length_up_to_width(theText, maxWidth, gui_text_width_without_colors);
}

void(string img, float a, float algn, float force1) gui_draw_background {
	vector sz;
	vector isz = '0 0 0';
	vector tl, ce, br;
	vector v;
	string s;
	float i, f;
	sz = gui_picture_size(img);
	// keep aspect of image
	if (sz_x * gui_draw_scale_y >= sz_y * gui_draw_scale_x) {
		// that is, sz_x/sz_y >= draw_scale_x/draw_scale_y
		// match up the height
		isz_y = 1;
		isz_x = isz_y * (sz_x / sz_y) * (gui_draw_scale_y / gui_draw_scale_x);
	} else {
		// that is, sz_x/sz_y <= draw_scale_x/draw_scale_y
		// match up the width
		isz_x = 1;
		isz_y = isz_x * (sz_y / sz_x) * (gui_draw_scale_x / gui_draw_scale_y);
	}
	tl = '0 0 0';
	ce = '0.5 0.5 0' - 0.5 * isz;
	br = '1 1 0' - isz;
	s = ftos(algn);
	v_z = 0;
	for (i = 0; i < strlen(s); ++i) {
		f = stof(substring(s, i, 1));
		switch(f) {
		case 1: case 4: case 7: v_x = tl_x; break;
		default:
		case 2: case 5: case 8: v_x = ce_x; break;
		case 3: case 6: case 9: v_x = br_x; break;
		}
		switch(f) {
		case 7: case 8: case 9: v_y = tl_y; break;
		default:
		case 4: case 5: case 6: v_y = ce_y; break;
		case 1: case 2: case 3: v_y = br_y; break;
		}
		if (i == 0)
			gui_draw_picture(v, img, isz, '1 1 1', a);
		else if (force1)
			// force all secondary layers to use alpha 1. Prevents ugly issues
			// with overlap. It's a flag because it cannot be used for the
			// ingame background
			gui_draw_picture(v, strcat(img, "_l", ftos(i+1)), isz, '1 1 1', 1);
		else
			gui_draw_picture(v, strcat(img, "_l", ftos(i+1)), isz, '1 1 1', a);
	}
}

void(entity outermost, entity innermost) gui_focus_item_chain {
	if (innermost.parent != outermost)
		gui_focus_item_chain(outermost, innermost.parent);

	innermost.parent.setFocus(innermost.parent, innermost);
}

void(entity wnd) gui_activate_window {
	entity par;
	par = wnd.parent;
	if (par)
		gui_activate_window(par);

	if(par.instanceOfModalController) {
		if (wnd.tabSelectingButton)
			// tabs
			TabButton_Click(wnd.tabSelectingButton, wnd);
		else
			// root
			par.initializeDialog(par, wnd);
	} else if(par.instanceOfNexposee) {
		// nexposee (sorry for violating abstraction here)
		par.selectedChild = wnd;
		par.animationState = 1;
		setFocusContainer(par, NULL);
	} else if(par.instanceOfContainer) {
		// other containers
		if(par.focused)
			par.setFocus(par, wnd);
	}
}

void(entity wnd) gui_setpointerfocus {
	if (wnd.instanceOfContainer) {
		entity focus = wnd.preferredFocusedGrandChild(wnd);
		if (focus) {
#ifndef CSQC
			menu_mouse_pos = focus.origin + 0.5 * focus.size;
			menu_mouse_pos_x *= 1 / gui_conwidth;
			menu_mouse_pos_y *= 1 / gui_conheight;
#endif
			if(wnd.focused) // why does this never happen?
				gui_focus_item_chain(wnd, focus);
		}
	}
}
