void(entity me) gui_rexuiz_cvarlist_configure;
void(entity me, float i) gui_rexuiz_cvarlist_select;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_cvarlist_item_draw;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_cvarlist_resize;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_cvarlist_key_down;

entity(void) gui_rexuiz_cvarlist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.configureNexuizCvarList = gui_rexuiz_cvarlist_configure;
	me.rowsPerItem = 1;
	me.drawListBoxItem = gui_rexuiz_cvarlist_item_draw;
	me.resizeNotify = gui_rexuiz_cvarlist_resize;
	me.keyDown = gui_rexuiz_cvarlist_key_down;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.columnValueOrigin = 0;
	me.columnValueSize = 0;
	me.setSelected = gui_rexuiz_cvarlist_select;
	me.controlledTextbox = NULL;
	me.cvarNameBox = NULL;
	me.cvarDescriptionBox = NULL;
	me.cvarTypeBox = NULL;
	me.cvarValueBox = NULL;
	me.cvarDefaultBox = NULL;
	me.handle = -1;
	me.cvarName = NULL;
	me.cvarDescription = NULL;
	me.cvarType = NULL;
	me.cvarDefault = NULL;
	me.classname = "NexuizCvarList";
	return me;
}

entity(void) gui_rexuiz_cvarlist_make {
	entity me = gui_rexuiz_cvarlist_spawn();
	me.configureNexuizCvarList(me);
	return me;
}

void(entity me) gui_rexuiz_cvarlist_configure {
	me.configureNexuizListBox(me);
	me.handle = str_array_create();
	str_array_cvar_list(me.handle, "", "_");
	me.nItems = str_array_size(me.handle);
}

void(entity me, float i) gui_rexuiz_cvarlist_select {
	string s;
	setSelectedListBox(me, i);
	if (me.nItems == 0)
		return;

	str_unzone_ifneeded(me.cvarName);
	str_unzone_ifneeded(me.cvarDescription);
	str_unzone_ifneeded(me.cvarType);
	str_unzone_ifneeded(me.cvarDefault);
	me.cvarName = str_zone_ifneeded(str_array_get(me.handle, me.selectedItem));
	me.cvarDescription = str_zone_ifneeded(cvar_description(me.cvarName));
	me.cvarDefault = str_zone_ifneeded(cvar_defstring(me.cvarName));
	float t;
	t = cvar_type(me.cvarName);
	me.cvarType = "";
	if (t & CVAR_TYPEFLAG_SAVED)
		me.cvarType = strcat(me.cvarType, _(", will be saved to config.cfg"));
	else
		me.cvarType = strcat(me.cvarType, _(", will not be saved"));

	if (t & CVAR_TYPEFLAG_PRIVATE)
		me.cvarType = strcat(me.cvarType, _(", private"));

	if (t & CVAR_TYPEFLAG_ENGINE)
		me.cvarType = strcat(me.cvarType, _(", engine setting"));

	if (t & CVAR_TYPEFLAG_READONLY)
		me.cvarType = strcat(me.cvarType, _(", read only"));

	me.cvarType = str_zone_ifneeded(str_sub(me.cvarType, 2, strlen(me.cvarType) - 2));
	me.cvarNameBox.setText(me.cvarNameBox, me.cvarName);
	me.cvarDescriptionBox.setText(me.cvarDescriptionBox, me.cvarDescription);
	me.cvarTypeBox.setText(me.cvarTypeBox, me.cvarType);
	me.cvarDefaultBox.setText(me.cvarDefaultBox, me.cvarDefault);
	// this one can handle tempstrings
	s = cvar_string(me.cvarName);
	me.cvarValueBox.setText(me.cvarValueBox, s);
	me.cvarValueBox.cursorPos = strlen(s);
}

void(entity box, entity me) gui_rexuiz_cvarlist_filter_change {
	str_array_cvar_list(me.handle, box.text, "_");
	me.nItems = str_array_size(me.handle);
	me.setSelected(me, 0);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_cvarlist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
	me.columnNameOrigin = 0;
	me.columnValueSize = me.realFontSize_x * 20;
	me.columnNameSize = 1 - me.columnValueSize - me.realFontSize_x;
	me.columnValueOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize_x;
	me.setSelected(me, me.selectedItem);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_cvarlist_item_draw {
	string k, v, d;
	float t;
	vector theColor;
	float theAlpha;
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	k = str_array_get(me.handle, i);
	v = cvar_string(k);
	d = cvar_defstring(k);
	t = cvar_type(k);
	if (t & CVAR_TYPEFLAG_SAVED)
		theAlpha = SKINALPHA_CVARLIST_SAVED;
	else
		theAlpha = SKINALPHA_CVARLIST_TEMPORARY;
	if (v == d)
		theColor = SKINCOLOR_CVARLIST_UNCHANGED;
	else
		theColor = SKINCOLOR_CVARLIST_CHANGED;

	s = gui_draw_text_shorten_to_width(k, me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
	s = gui_draw_text_shorten_to_width(v, me.columnValueSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin * eY + me.columnValueOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_cvarlist_key_down {
	if (keyDownListBox(me, scan, ascii, shift))
		return 1;
	else if(!me.controlledTextbox)
		return 0;
	else
		return me.controlledTextbox.keyDown(me.controlledTextbox, scan, ascii, shift);
}

void(entity box, entity me) gui_rexuiz_cvarlist_value_change {
	cvar_set(me.cvarNameBox.text, box.text);
}

void(entity btn, entity me) gui_rexuiz_cvarlist_revert_click {
	me.cvarValueBox.setText(me.cvarValueBox, me.cvarDefault);
	me.cvarValueBox.cursorPos = strlen(me.cvarDefault);
}
