#ifdef INTERFACE
CLASS(NexuizCampaignList) EXTENDS(NexuizListBox)
	METHOD(NexuizCampaignList, configureNexuizCampaignList, void(entity))
	ATTRIB(NexuizCampaignList, rowsPerItem, float, 10)
	METHOD(NexuizCampaignList, draw, void(entity))
	METHOD(NexuizCampaignList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizCampaignList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizCampaignList, setSelected, void(entity, float))
	METHOD(NexuizCampaignList, keyDown, float(entity, float, float, float))
	METHOD(NexuizCampaignList, destroy, void(entity))
	METHOD(NexuizCampaignList, clickListBoxItem, void(entity, float, vector, float))

	ATTRIB(NexuizCampaignList, realFontSize, vector, '0 0 0')
	ATTRIB(NexuizCampaignList, columnPreviewOrigin, float, 0)
	ATTRIB(NexuizCampaignList, columnPreviewSize, float, 0)
	ATTRIB(NexuizCampaignList, columnNameOrigin, float, 0)
	ATTRIB(NexuizCampaignList, columnNameSize, float, 0)
	ATTRIB(NexuizCampaignList, columnCheckMarkOrigin, float, 0)
	ATTRIB(NexuizCampaignList, columnCheckMarkSize, float, 0)
	ATTRIB(NexuizCampaignList, checkMarkOrigin, vector, '0 0 0')
	ATTRIB(NexuizCampaignList, checkMarkSize, vector, '0 0 0')
	ATTRIB(NexuizCampaignList, realUpperMargin1, float, 0)
	ATTRIB(NexuizCampaignList, realUpperMargin2, float, 0)

	ATTRIB(NexuizCampaignList, origin, vector, '0 0 0')
	ATTRIB(NexuizCampaignList, itemAbsSize, vector, '0 0 0')
	ATTRIB(NexuizCampaignList, emptyLineHeight, float, 0.5)

	ATTRIB(NexuizCampaignList, campaignIndex, float, 0)
	ATTRIB(NexuizCampaignList, cvarName, string, NULL)
	METHOD(NexuizCampaignList, loadCvars, void(entity))
	METHOD(NexuizCampaignList, saveCvars, void(entity))

	ATTRIB(NexuizCampaignList, buttonMPT, entity, NULL)
	ATTRIB(NexuizCampaignList, buttonSurv, entity, NULL)
ENDCLASS(NexuizCampaignList)
entity makeNexuizCampaignList();
void CampaignList_LoadMap(entity btn, entity me);
#endif

#ifdef IMPLEMENTATION
string campaign_longdesc_wrapped[CAMPAIGN_MAX_ENTRIES];

void rewrapCampaign(float w, float l0, float emptyheight)
{
	float i, j;
	float n, l;
	string r, s;
	for(i = 0; i < campaign_entries; ++i)
	{
		l = l0;
		if(campaign_longdesc_wrapped[i])
			strunzone(campaign_longdesc_wrapped[i]);
		n = tokenizebyseparator(campaign_longdesc[i], "\n");
		r = "";
		for(j = 0; j < n; ++j)
		{
			s = argv(j);
			if(s == "")
			{
				l -= emptyheight;
				r = strcat(r, "\n");
				continue;
			}

			str_wrapped_line_remaining = s;
			while(str_wrapped_line_remaining)
			{
				s = str_wrapped_line(w, gui_text_width_without_colors);
				if(--l < 0) goto toolong;
				r = strcat(r, s, "\n");
			}
		}
		goto nottoolong;
:toolong
		while(substring(r, strlen(r) - 1, 1) == "\n")
			r = substring(r, 0, strlen(r) - 1);
		r = strcat(r, "...\n");
:nottoolong
		campaign_longdesc_wrapped[i] = strzone(substring(r, 0, strlen(r) - 1));
	}
}

entity makeNexuizCampaignList()
{
	entity me;
	me = spawnNexuizCampaignList();
	me.configureNexuizCampaignList(me);
	return me;
}
void configureNexuizCampaignListNexuizCampaignList(entity me)
{
	me.configureNexuizListBox(me);
	me.loadCvars(me);
}

void destroyNexuizCampaignList(entity me)
{
}

void loadCvarsNexuizCampaignList(entity me)
{
	// read campaign cvars
	if(me.cvarName)
		strunzone(me.cvarName);
	campaign_file_unload();
	campaign_file_load(cvar_string("g_campaign_name"));
	me.cvarName = strzone(strcat("g_campaign", campaign_name, "_index"));
	registercvar(me.cvarName, "", 0); // saved by server QC anyway
	me.campaignIndex = bound(0, cvar(me.cvarName), campaign_entries);
	cvar_set(me.cvarName, ftos(me.campaignIndex));
	if(me.columnNameSize)
		rewrapCampaign(me.columnNameSize / me.realFontSize_x, me.rowsPerItem - 3, me.emptyLineHeight);
	me.nItems = min(me.campaignIndex + 2, campaign_entries);
	me.selectedItem = min(me.campaignIndex, me.nItems - 1);
	me.scrollPos = me.nItems * me.itemHeight - 1;
}

void saveCvarsNexuizCampaignList(entity me)
{
	// write campaign cvars
	// no reason to do this!
	// cvar_set("g_campaign_name", campaign_name);
	// cvar_set(me.cvarName, ftos(me.campaignIndex)); // NOTE: only server QC does that!
}

void drawNexuizCampaignList(entity me)
{
	if(cvar(me.cvarName) != me.campaignIndex || cvar_string("g_campaign_name") != campaign_name)
		me.loadCvars(me);
	drawListBox(me);
}

void resizeNotifyNexuizCampaignList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

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

	rewrapCampaign(me.columnNameSize / me.realFontSize_x, me.rowsPerItem - 3, me.emptyLineHeight);
}
void clickListBoxItemNexuizCampaignList(entity me, float i, vector where, float doubleclick) {
	if (doubleclick)
		CampaignList_LoadMap(me, me);
}
void drawListBoxItemNexuizCampaignList(entity me, float i, vector absSize, float isSelected)
{
	string s;
	float p = 0;
	vector theColor;
	float theAlpha;
	float j, n;
	vector o;

	if(i < me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_SELECTABLE;
		theColor = SKINCOLOR_CAMPAIGN_SELECTABLE;
	}
	else if(i == me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_CURRENT;
		theColor = SKINCOLOR_CAMPAIGN_CURRENT;
	}
	else
	{
		theAlpha = SKINALPHA_CAMPAIGN_FUTURE;
		theColor = SKINCOLOR_CAMPAIGN_FUTURE;
	}

	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = ftos(p);
	gui_draw_picture(me.columnPreviewOrigin * eX, strcat("/maps/", campaign_mapname[i]), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	if(i < me.campaignIndex)
		gui_draw_picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);
	if(i <= me.campaignIndex)
		s = campaign_shortdesc[i]; // fteqcc sucks
	else
		s = "???";
	s = gui_draw_text_shorten_to_width(strcat("Level ", ftos(i + 1), ": ", s), me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, theColor, theAlpha, 0);
	if(i <= me.campaignIndex)
	{
		s = campaign_longdesc_wrapped[i];
		n = tokenizebyseparator(s, "\n");
		o = me.realUpperMargin2 * eY + me.columnNameOrigin * eX;
		for(j = 0; j < n; ++j)
			if(argv(j) != "")
			{
				gui_draw_text(o, argv(j), me.realFontSize, theColor, theAlpha * SKINALPHA_CAMPAIGN_DESCRIPTION, 0);
				o_y += me.realFontSize_y;
			}
			else
				o_y += me.realFontSize_y * me.emptyLineHeight;
	}
}
void CampaignList_LoadMap(entity btn, entity me)
{
	if(me.selectedItem >= me.nItems || me.selectedItem < 0)
		return;

	cvar_set("g_campaign_skill", cvar_string("menu_campaign_skill"));
	campaign_setup(me.selectedItem);
}

void setSelectedNexuizCampaignList(entity me, float i)
{
	// prevent too late items from being played
	setSelectedListBox(me, min(i, me.campaignIndex));
}

float keyDownNexuizCampaignList(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_SPACE)
		CampaignList_LoadMap(me, me);
	else
		return keyDownListBox(me, scan, ascii, shift);
	return 1;
}
#endif
