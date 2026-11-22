entity spawnNexuizDemoList() {
	entity me; me = spawnNexuizListBox();
				me.configureNexuizDemoList = configureNexuizDemoListNexuizDemoList;
				me.rowsPerItem = 1;
				me.resizeNotify = resizeNotifyNexuizDemoList;
				me.drawListBoxItem = drawListBoxItemNexuizDemoList;
				me.getDemos = getDemosNexuizDemoList;
				me.startDemo = startDemoNexuizDemoList;
				me.demoName = demoNameNexuizDemoList;
				me.clickListBoxItem = clickListBoxItemNexuizDemoList;
				me.keyDown = keyDownNexuizDemoList;
				me.destroy = destroyNexuizDemoList;
				me.showNotify = showNotifyNexuizDemoList;
				me.listDemo = -1;
				me.realFontSize = '0 0 0';
				me.columnNameOrigin = 0;
				me.columnNameSize = 0;
				me.realUpperMargin = 0;
				me.origin = '0 0 0';
				me.itemAbsSize = '0 0 0';
				me.filterString = NULL;
	me.classname = "NexuizDemoList";
	return me;
}
entity makeNexuizDemoList();
void StartDemo_Click(entity btn, entity me);
void TimeDemo_Click(entity btn, entity me);
void DemoList_Filter_Change(entity box, entity me);
entity makeNexuizDemoList()
{
				entity me;
				me = spawnNexuizDemoList();
				me.configureNexuizDemoList(me);
				return me;
}
void configureNexuizDemoListNexuizDemoList(entity me)
{
				me.configureNexuizListBox(me);
				me.getDemos(me);
}
string demoNameNexuizDemoList(entity me, float i )
{
				string s;
				s = search_getfilename(me.listDemo, i);
				s = str_sub(s, 6, strlen(s) - 6 - 4); // demos/, .dem
				return s;
}
void getDemosNexuizDemoList(entity me)
{
				string s;
				if(me.filterString)
					//subdirectory in filterString allowed    
					s=strcat("demos/*", me.filterString, "*.dem");
				else
					s="demos/*.dem";
				//dprint("Search demos with the pattern ", s, "\n");    
	if(me.listDemo >= 0)
		search_end(me.listDemo);
				me.listDemo = search_begin(s, FALSE, TRUE);
				if(me.listDemo < 0)
					me.nItems=0;
				else
					me.nItems=search_getsize(me.listDemo);
}
void destroyNexuizDemoList(entity me)
{
	if (me.listDemo >= 0)
		search_end(me.listDemo);
}
void resizeNotifyNexuizDemoList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
				me.itemAbsSize = '0 0 0';
				resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
				me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
				me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
				me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
				me.columnNameOrigin = me.realFontSize_x;
				me.columnNameSize = 1 - 2 * me.realFontSize_x;
}
void drawListBoxItemNexuizDemoList(entity me, float i, vector absSize, float isSelected)
{
				string s;
				if(isSelected)
					gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
				s = me.demoName(me,i);
				s = gui_draw_text_shorten_to_width(s, me.columnNameSize / me.realFontSize_x, 0);
				gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
void showNotifyNexuizDemoList(entity me)
{
				me.getDemos(me);
}
void DemoList_Filter_Change(entity box, entity me)
{
				str_unzone_ifneeded(me.filterString);
				me.filterString = str_zone_ifneeded(box.text);
				me.getDemos(me);
}
void startDemoNexuizDemoList(entity me) {
				string s;
				s = me.demoName(me,me.selectedItem);
	demo_play(strcat("demos/", s, ".dem"));
}
void StartDemo_Click(entity btn, entity me)
{
				me.startDemo(me);
}
void TimeDemo_Click(entity btn, entity me)
{
				string s;
				s = me.demoName(me,me.selectedItem);
				localcmd("timedemo demos/", s, ".dem\nwait\ntogglemenu\n");
}
void clickListBoxItemNexuizDemoList(entity me, float i, vector where, float doubleclick) {
	if (doubleclick)
		me.startDemo(me);
}
float keyDownNexuizDemoList(entity me, float scan, float ascii, float shift)
{
				if(scan == VM_K_ENTER) {
						  me.startDemo(me);
						  return 1;
				}
				else
						  return keyDownListBox(me, scan, ascii, shift);
}
