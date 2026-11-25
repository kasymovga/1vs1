void(entity me) gui_rexuiz_campaign_configure;
void(entity me) gui_rexuiz_campaign_destroy;
void(entity me) gui_rexuiz_campaign_load;
void(entity me) gui_rexuiz_campaign_save;
void(entity me) gui_rexuiz_campaign_draw;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_campaign_resize;
void(entity me, float i, vector where, float doubleclick) gui_rexuiz_campaign_item_click;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_campaign_item_draw;
void(entity me, float i) gui_rexuiz_campaign_select;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_campaign_key_down;

entity(void) gui_rexuiz_campaign_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.configureNexuizCampaignList = gui_rexuiz_campaign_configure;
	me.rowsPerItem = 10;
	me.draw = gui_rexuiz_campaign_draw;
	me.drawListBoxItem = gui_rexuiz_campaign_item_draw;
	me.resizeNotify = gui_rexuiz_campaign_resize;
	me.setSelected = gui_rexuiz_campaign_select;
	me.keyDown = gui_rexuiz_campaign_key_down;
	me.destroy = gui_rexuiz_campaign_destroy;
	me.clickListBoxItem = gui_rexuiz_campaign_item_click;
	me.realFontSize = '0 0 0';
	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = 0;
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.columnCheckMarkOrigin = 0;
	me.columnCheckMarkSize = 0;
	me.checkMarkOrigin = '0 0 0';
	me.checkMarkSize = '0 0 0';
	me.realUpperMargin1 = 0;
	me.realUpperMargin2 = 0;
	me.origin = '0 0 0';
	me.itemAbsSize = '0 0 0';
	me.emptyLineHeight = 0.5;
	me.campaignIndex = 0;
	me.cvarName = NULL;
	me.loadCvars = gui_rexuiz_campaign_load;
	me.saveCvars = gui_rexuiz_campaign_save;
	me.classname = "NexuizCampaignList";
	return me;
}

string gui_rexuiz_campaign_longdesc_wrapped[CAMPAIGN_MAX_ENTRIES];
void(float w, float l0, float emptyheight) gui_rexuiz_campaign_rewrap {
	float i, j;
	float n, l;
	string r, s;
	for (i = 0; i < campaign_entries; ++i) {
		l = l0;
		str_unzone_ifneeded(gui_rexuiz_campaign_longdesc_wrapped[i]);
		n = tokenizebyseparator(campaign_longdesc[i], "\n");
		r = "";
		for (j = 0; j < n; ++j) {
			s = argv(j);
			if(s == "") {
				l -= emptyheight;
				r = strcat(r, "\n");
				continue;
			}
			str_wrapped_line_remaining = s;
			while(str_wrapped_line_remaining) {
				s = str_wrapped_line(w, gui_text_width_without_colors);
				if(--l < 0) goto toolong;
				r = strcat(r, s, "\n");
			}
		}
		goto nottoolong;
:toolong
		while (str_sub(r, strlen(r) - 1, 1) == "\n")
			r = str_sub(r, 0, strlen(r) - 1);

		r = strcat(r, "...\n");
:nottoolong
		gui_rexuiz_campaign_longdesc_wrapped[i] = str_zone_ifneeded(str_sub(r, 0, strlen(r) - 1));
	}
}

entity(void) gui_rexuiz_campaign_make {
	entity me;
	me = gui_rexuiz_campaign_spawn();
	me.configureNexuizCampaignList(me);
	return me;
}

void(entity me) gui_rexuiz_campaign_configure {
	me.configureNexuizListBox(me);
	me.loadCvars(me);
}

void(entity me) gui_rexuiz_campaign_destroy {
}

void(entity me) gui_rexuiz_campaign_load {
	// read campaign cvars
	str_unzone_ifneeded(me.cvarName);
	campaign_file_unload();
	campaign_file_load(cvar_string("g_campaign_name"));
	me.cvarName = str_zone_ifneeded(strcat("g_campaign", campaign_name, "_index"));
	registercvar(me.cvarName, "", 0); // saved by server QC anyway
	me.campaignIndex = bound(0, cvar(me.cvarName), campaign_entries);
	cvar_set(me.cvarName, ftos(me.campaignIndex));
	if (me.columnNameSize)
		gui_rexuiz_campaign_rewrap(me.columnNameSize / me.realFontSize_x, me.rowsPerItem - 3, me.emptyLineHeight);

	me.nItems = min(me.campaignIndex + 2, campaign_entries);
	me.selectedItem = min(me.campaignIndex, me.nItems - 1);
	me.scrollPos = me.nItems * me.itemHeight - 1;
}

void(entity me) gui_rexuiz_campaign_save {
	// write campaign cvars
	// no reason to do this!
	// cvar_set("g_campaign_name", campaign_name);
	// cvar_set(me.cvarName, ftos(me.campaignIndex)); // NOTE: only server QC does that!
}

void(entity me) gui_rexuiz_campaign_draw {
	if (cvar(me.cvarName) != me.campaignIndex || cvar_string("g_campaign_name") != campaign_name)
		me.loadCvars(me);

	drawListBox(me);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_campaign_resize {
	me.itemAbsSize = '0 0 0';
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin1 = 0.5 * me.realFontSize_y;
	me.realUpperMargin2 = me.realUpperMargin1 + 2 * me.realFontSize_y;
	me.checkMarkSize = (eX * (me.itemAbsSize_y / me.itemAbsSize_x) + eY) * 0.5;
	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize_y / me.itemAbsSize_x * 4 / 3;
	me.columnCheckMarkSize = me.checkMarkSize_x;
	me.columnNameSize = 1 - me.columnPreviewSize - me.columnCheckMarkSize - 4 * me.realFontSize_x;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize_x;
	me.columnCheckMarkOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize_x * 2;
	me.checkMarkOrigin = eY + eX * (me.columnCheckMarkOrigin + me.columnCheckMarkSize) - me.checkMarkSize;
	gui_rexuiz_campaign_rewrap(me.columnNameSize / me.realFontSize_x, me.rowsPerItem - 3, me.emptyLineHeight);
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_campaign_item_click {
	if (doubleclick)
		gui_rexuiz_campaign_map_load(me, me);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_campaign_item_draw {
	string s;
	float p = 0;
	vector theColor;
	float theAlpha;
	float j, n;
	vector o;
	if (i < me.campaignIndex) {
		theAlpha = SKINALPHA_CAMPAIGN_SELECTABLE;
		theColor = SKINCOLOR_CAMPAIGN_SELECTABLE;
	} else if(i == me.campaignIndex) {
		theAlpha = SKINALPHA_CAMPAIGN_CURRENT;
		theColor = SKINCOLOR_CAMPAIGN_CURRENT;
	} else {
		theAlpha = SKINALPHA_CAMPAIGN_FUTURE;
		theColor = SKINCOLOR_CAMPAIGN_FUTURE;
	}
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = ftos(p);
	gui_draw_picture(me.columnPreviewOrigin * eX, strcat("/maps/", campaign_mapname[i]), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	if (i < me.campaignIndex)
		gui_draw_picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);

	if (i <= me.campaignIndex)
		s = campaign_shortdesc[i]; // fteqcc sucks
	else
		s = "???";

	s = gui_draw_text_shorten_to_width(strcat("Level ", ftos(i + 1), ": ", s), me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, theColor, theAlpha, 0);
	if (i <= me.campaignIndex) {
		s = gui_rexuiz_campaign_longdesc_wrapped[i];
		n = tokenizebyseparator(s, "\n");
		o = me.realUpperMargin2 * eY + me.columnNameOrigin * eX;
		for (j = 0; j < n; ++j)
			if(argv(j) != "") {
				gui_draw_text(o, argv(j), me.realFontSize, theColor, theAlpha * SKINALPHA_CAMPAIGN_DESCRIPTION, 0);
				o_y += me.realFontSize_y;
			} else
				o_y += me.realFontSize_y * me.emptyLineHeight;
	}
}

void(entity btn, entity me) gui_rexuiz_campaign_map_load {
	if (me.selectedItem >= me.nItems || me.selectedItem < 0)
		return;

	cvar_set("g_campaign_skill", cvar_string("menu_campaign_skill"));
	campaign_setup(me.selectedItem);
}

void(entity me, float i) gui_rexuiz_campaign_select {
	// prevent too late items from being played
	setSelectedListBox(me, min(i, me.campaignIndex));
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_campaign_key_down {
	if (scan == VM_K_ENTER || scan == VM_K_SPACE)
		gui_rexuiz_campaign_map_load(me, me);
	else
		return keyDownListBox(me, scan, ascii, shift);

	return 1;
}
