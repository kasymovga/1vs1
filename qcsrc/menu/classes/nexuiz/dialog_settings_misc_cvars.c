#ifdef INTERFACE
CLASS(NexuizCvarsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizCvarsDialog, toString, string(entity))
	METHOD(NexuizCvarsDialog, fill, void(entity))
	METHOD(NexuizCvarsDialog, showNotify, void(entity))
	ATTRIB(NexuizCvarsDialog, title, string, _("Advanced settings"))
	ATTRIB(NexuizCvarsDialog, color, vector, SKINCOLOR_DIALOG_CVARS)
	ATTRIB(NexuizCvarsDialog, intendedWidth, float, 0.8)
	ATTRIB(NexuizCvarsDialog, rows, float, 25)
	ATTRIB(NexuizCvarsDialog, columns, float, 6)
ENDCLASS(NexuizCvarsDialog)
#endif

#ifdef IMPLEMENTATION
void showNotifyNexuizCvarsDialog(entity me)
{
	loadAllCvars(me);
}
string toStringNexuizCvarsDialog(entity me)
{
	return "XXX";
}
void fillNexuizCvarsDialog(entity me)
{
	entity e, cvarlist, btn;
	cvarlist = makeNexuizCvarList();
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Cvar filter:")));
		me.TD(me, 1, 0.5, btn = makeNexuizButton(_("Clear"), '0 0 0'));
		me.TD(me, 1, me.columns - 1.5, e = makeNexuizInputBox(0, NULL));
			e.onChange = CvarList_Filter_Change;
			e.onChangeEntity = cvarlist;
			btn.onClick = InputBox_Clear_Click;
			btn.onClickEntity = e;
			cvarlist.controlledTextbox = e; // this COULD also be the Value box, but this leads to accidentally editing stuff
	me.TR(me);
		me.TD(me, me.rows - me.currentRow - 7, me.columns, cvarlist);
	me.gotoRC(me, me.rows - 7, 0);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Setting:")));
		me.TD(me, 1, me.columns - 1, e = makeNexuizTextLabel(0, NULL));
			cvarlist.cvarNameBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Type:")));
		me.TD(me, 1, me.columns - 1, e = makeNexuizTextLabel(0, NULL));
			cvarlist.cvarTypeBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Value:")));
		me.TD(me, 1, me.columns - 2, e = makeNexuizInputBox(0, NULL));
			cvarlist.cvarValueBox = e;
			e.onChange = CvarList_Value_Change;
			e.onChangeEntity = cvarlist;
		me.TD(me, 1, 1, e = makeNexuizButton(NULL, SKINCOLOR_CVARLIST_REVERTBUTTON));
			cvarlist.cvarDefaultBox = e;
			e.onClick = CvarList_Revert_Click;
			e.onClickEntity = cvarlist;
			e.allowCut = 1;
			e.marginLeft = e.marginRight = 0.5;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Description:")));
		me.TD(me, 1, me.columns - 1, e = makeNexuizTextLabel(0, NULL));
			cvarlist.cvarDescriptionBox = e;
			e.allowWrap = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

#endif
