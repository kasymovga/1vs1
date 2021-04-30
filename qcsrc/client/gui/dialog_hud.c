#ifdef INTERFACE
CLASS(NexuizHudDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizHudDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizHudDialog, title, string, "HUD selection")
	ATTRIB(NexuizHudDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizHudDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizHudDialog, rows, float, 9)
	ATTRIB(NexuizHudDialog, columns, float, 2)
	ATTRIB(NexuizHudDialog, name, string, "HudMenu")
ENDCLASS(NexuizVcallDialog)
#endif

#ifdef IMPLEMENTATION
void(entity btn, entity me) loadNexuizHudDialog {
	me.clickListBoxItem(me, me.selectedItem, '0 0 0', 1); //emulate double click
}

void(entity me) fillNexuizHudDialog {
	entity e, hudlist;
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, "Available HUDs:"));
	me.TR(me);
		me.TD(me, 6, 2, hudlist = makeNexuizHudList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me); // ???
		me.TD(me, 1, 1, e = makeNexuizButton("Appply", '0 0 0'));
			e.onClick = loadNexuizHudDialog;
			e.onClickEntity = hudlist;
			hudlist.onClickEntity = e;
		me.TD(me, 1, 1, e = makeNexuizCommandButton("Cancel", '0 0 0', "", 1));
}
#endif
