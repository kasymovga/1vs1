#ifdef INTERFACE
CLASS(NexuizDemoList) EXTENDS(NexuizListBox)
    METHOD(NexuizDemoList, configureNexuizDemoList, void(entity))
    ATTRIB(NexuizDemoList, rowsPerItem, float, 1)
    METHOD(NexuizDemoList, resizeNotify, void(entity, vector, vector, vector, vector))
    METHOD(NexuizDemoList, drawListBoxItem, void(entity, float, vector, float))
    METHOD(NexuizDemoList, getDemos, void(entity))
    METHOD(NexuizDemoList, startDemo, void(entity))
    METHOD(NexuizDemoList, demoName, string(entity, float))
    METHOD(NexuizDemoList, clickListBoxItem, void(entity, float, vector, float))
    METHOD(NexuizDemoList, keyDown, float(entity, float, float, float))
    METHOD(NexuizDemoList, destroy, void(entity))
    METHOD(NexuizDemoList, showNotify, void(entity))
    ATTRIB(NexuizDemoList, listDemo, float, -1)
    ATTRIB(NexuizDemoList, realFontSize, vector, '0 0 0')
    ATTRIB(NexuizDemoList, columnNameOrigin, float, 0)
    ATTRIB(NexuizDemoList, columnNameSize, float, 0)
    ATTRIB(NexuizDemoList, realUpperMargin, float, 0)
    ATTRIB(NexuizDemoList, origin, vector, '0 0 0')
    ATTRIB(NexuizDemoList, itemAbsSize, vector, '0 0 0')
    ATTRIB(NexuizDemoList, filterString, string, NULL)
ENDCLASS(NexuizDemoList)

entity makeNexuizDemoList();
void StartDemo_Click(entity btn, entity me);
void TimeDemo_Click(entity btn, entity me);
void DemoList_Filter_Change(entity box, entity me);
#endif

#ifdef IMPLEMENTATION

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
    s = substring(s, 6, strlen(s) - 6 - 4);  // demos/, .dem
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
    if(me.filterString)
    	strunzone(me.filterString);
    
    if(box.text != "")
    	me.filterString = strzone(box.text);
    else
    	me.filterString = NULL;
		
    me.getDemos(me);
}

void startDemoNexuizDemoList(entity me)
{
    string s;
    s = me.demoName(me,me.selectedItem);
    localcmd("playdemo demos/", s, ".dem\nwait\ntogglemenu\n");	
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
    if(scan == K_ENTER) {
        me.startDemo(me);
        return 1;
    }
    else
        return keyDownListBox(me, scan, ascii, shift);
}
#endif

