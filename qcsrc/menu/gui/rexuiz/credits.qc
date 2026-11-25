void(entity me) gui_rexuiz_credits_configure;
void(entity me) gui_rexuiz_credits_destroy;
void(entity me) gui_rexuiz_credits_draw;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_credits_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_credits_item_draw;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_credits_key_down;

entity(void) gui_rexuiz_credits_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.configureNexuizCreditsList = gui_rexuiz_credits_configure;
	me.rowsPerItem = 1;
	me.draw = gui_rexuiz_credits_draw;
	me.drawListBoxItem = gui_rexuiz_credits_item_draw;
	me.resizeNotify = gui_rexuiz_credits_resize;
	me.keyDown = gui_rexuiz_credits_key_down;
	me.destroy = gui_rexuiz_credits_destroy;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.bufferIndex = 0;
	me.scrolling = 0;
	me.classname = "NexuizCreditsList";
	return me;
}

entity(void) gui_rexuiz_credits_make {
	entity me;
	me = gui_rexuiz_credits_spawn();
	me.configureNexuizCreditsList(me);
	return me;
}

void(entity me) gui_rexuiz_credits_configure {
	float i, fh;
	string l;
	me.configureNexuizListBox(me);
	// load the file
	me.bufferIndex = str_array_create();
	fh = fopen("rexuiz-credits.txt", FILE_READ);
	if (fh >= 0) {
		i = 0;
		while ((l = fgets(fh))) {
			str_array_set(me.bufferIndex, i, l);
			++i;
		}
		fclose(fh);
	}
	me.nItems = str_array_size(me.bufferIndex);
}

void(entity me) gui_rexuiz_credits_destroy {
	str_array_delete(me.bufferIndex);
}

void(entity me) gui_rexuiz_credits_draw {
	float i;
	if (me.scrolling) {
		me.scrollPos = bound(0, (time - me.scrolling) * me.itemHeight, me.nItems * me.itemHeight - 1);
		i = min(me.selectedItem, floor((me.scrollPos + 1) / me.itemHeight - 1));
		i = max(i, ceil(me.scrollPos / me.itemHeight));
		me.setSelected(me, i);
	}
	drawListBox(me);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_credits_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_credits_item_draw {
	// layout: Ping, Credits name, Map name, NP, TP, MP
	string s;
	float theAlpha;
	vector theColor;
	s = str_array_get(me.bufferIndex, i);
	if (str_sub(s, 0, 2) == "**") {
		s = str_sub(s, 2, strlen(s) - 2);
		theColor = SKINCOLOR_CREDITS_TITLE;
		theAlpha = SKINALPHA_CREDITS_TITLE;
	} else if (str_sub(s, 0, 1) == "*") {
		s = str_sub(s, 1, strlen(s) - 1);
		theColor = SKINCOLOR_CREDITS_FUNCTION;
		theAlpha = SKINALPHA_CREDITS_FUNCTION;
	} else {
		theColor = SKINCOLOR_CREDITS_PERSON;
		theAlpha = SKINALPHA_CREDITS_PERSON;
	}
	gui_draw_text_center(me.realUpperMargin * eY + 0.5 * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_credits_key_down {
	float i;
	me.dragScrollTimer = time;
	me.scrolling = 0;
	if (scan == VM_K_PGUP)
		me.scrollPos = max(me.scrollPos - 0.5, 0);
	else if (scan == VM_K_PGDN)
		me.scrollPos = min(me.scrollPos + 0.5, me.nItems * me.itemHeight - 1);
	else if (scan == VM_K_UPARROW)
		me.scrollPos = max(me.scrollPos - me.itemHeight, 0);
	else if (scan == VM_K_DOWNARROW)
		me.scrollPos = min(me.scrollPos + me.itemHeight, me.nItems * me.itemHeight - 1);
	else
		return keyDownListBox(me, scan, ascii, shift);

	i = min(me.selectedItem, floor((me.scrollPos + 1) / me.itemHeight - 1));
	i = max(i, ceil(me.scrollPos / me.itemHeight));
	me.setSelected(me, i);
	return 1;
}
