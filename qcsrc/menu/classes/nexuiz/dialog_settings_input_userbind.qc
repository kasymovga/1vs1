entity spawnNexuizUserbindEditDialog() {
	entity me; me = spawnNexuizDialog();
	me.loadUserBind = loadUserBindNexuizUserbindEditDialog;
	me.fill = fillNexuizUserbindEditDialog;
	me.title = _("User defined key bind");
	me.color = SKINCOLOR_DIALOG_USERBIND;
	me.intendedWidth = 0.7;
	me.rows = 4;
	me.columns = 3;
	me.keybindBox = NULL;
	me.nameBox = NULL;
	me.commandPressBox = NULL;
	me.commandReleaseBox = NULL;
	me.classname = "NexuizUserbindEditDialog";
	return me;
}
void NexuizUserbindEditDialog_Save(entity btn, entity me)
{
	me.keybindBox.editUserbind(me.keybindBox, me.nameBox.text, me.commandPressBox.text, me.commandReleaseBox.text);
	gui_dialog_close(btn, me);
}
void loadUserBindNexuizUserbindEditDialog(entity me, string theName, string theCommandPress, string theCommandRelease)
{
	me.nameBox.setText(me.nameBox, theName);
		me.nameBox.keyDown(me.nameBox, VM_K_END, 0, 0);
	me.commandPressBox.setText(me.commandPressBox, theCommandPress);
		me.nameBox.keyDown(me.commandPressBox, VM_K_END, 0, 0);
	me.commandReleaseBox.setText(me.commandReleaseBox, theCommandRelease);
		me.nameBox.keyDown(me.commandReleaseBox, VM_K_END, 0, 0);
}
void fillNexuizUserbindEditDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Name:")));
		me.TD(me, 1, me.columns - 1, me.nameBox = makeNexuizInputBox(0, NULL));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Command when pressed:")));
		me.TD(me, 1, me.columns - 1, me.commandPressBox = makeNexuizInputBox(0, NULL));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Command when released:")));
		me.TD(me, 1, me.columns - 1, me.commandReleaseBox = makeNexuizInputBox(0, NULL));
	me.TR(me);
		me.TD(me, 1, me.columns / 2, e = makeNexuizButton(_("Save"), '0 0 0'));
				e.onClick = NexuizUserbindEditDialog_Save;
				e.onClickEntity = me;
		me.TD(me, 1, me.columns / 2, e = makeNexuizButton(_("Cancel"), '0 0 0'));
				e.onClick = gui_dialog_close;
				e.onClickEntity = me;
}
