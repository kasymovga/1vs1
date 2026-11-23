entity(void) gui_rexuiz_listbox_spawn {
	entity me; me = gui_listbox_spawn();
	me.configureNexuizListBox = configureNexuizListBoxNexuizListBox;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.scrollbarWidth = SKINWIDTH_SCROLLBAR;
	me.src = SKINGFX_SCROLLBAR;
	me.tolerance = SKINTOLERANCE_SLIDER;
	me.rowsPerItem = 1;
	me.resizeNotify = resizeNotifyNexuizListBox;
	me.color = SKINCOLOR_SCROLLBAR_N;
	me.colorF = SKINCOLOR_SCROLLBAR_F;
	me.color2 = SKINCOLOR_SCROLLBAR_S;
	me.colorC = SKINCOLOR_SCROLLBAR_C;
	me.classname = "NexuizListBox";
	return me;
}

entity(void) gui_rexuiz_listbox_make {
	entity me;
	me = gui_rexuiz_listbox_spawn();
	me.configureNexuizListBox(me);
	return me;
}
void configureNexuizListBoxNexuizListBox(entity me)
{
	me.configureListBox(me, me.scrollbarWidth, 1); // item height gets set up later
}
void resizeNotifyNexuizListBox(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemHeight = me.rowsPerItem * me.fontSize / absSize_y;
	resizeNotifyListBox(me, relOrigin, relSize, absOrigin, absSize);
}
