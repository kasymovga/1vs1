//# define COMMANDBUTTON_REVERT 4
entity spawnNexuizCommandButton() {
	entity me; me = spawnNexuizButton();
	me.configureNexuizCommandButton = configureNexuizCommandButtonNexuizCommandButton;
	me.onClickCommand = NULL;
	me.flags = 0;
	me.classname = "NexuizCommandButton";
	return me;
}
entity makeNexuizCommandButton(string theText, vector theColor, string theCommand, float closesMenu);
entity makeNexuizCommandButton(string theText, vector theColor, string theCommand, float theFlags)
{
	entity me;
	me = spawnNexuizCommandButton();
	me.configureNexuizCommandButton(me, theText, theColor, theCommand, theFlags);
	return me;
}
void NexuizCommandButton_Click(entity me, entity theOther)
{
	//if(me.flags & COMMANDBUTTON_APPLY)
	//	saveAllCvars(me.parent);
	localcmd("\n", me.onClickCommand, "\n");
	//if(me.flags & COMMANDBUTTON_REVERT)
	//	loadAllCvars(me.parent);
	if(me.flags & 1)
#ifdef MENUQC
		menu_goto(NULL);
#endif
#ifdef CSQC
		GUI_Hide();
#endif
}
void configureNexuizCommandButtonNexuizCommandButton(entity me, string theText, vector theColor, string theCommand, float theFlags)
{
	me.configureNexuizButton(me, theText, theColor);
	me.onClickCommand = theCommand;
	me.flags = theFlags;
	me.onClick = NexuizCommandButton_Click;
	me.onClickEntity = me;
}
