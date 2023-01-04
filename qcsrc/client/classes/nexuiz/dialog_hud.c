#ifdef INTERFACE
CLASS(NexuizHudDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizHudDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizHudDialog, title, string, "HUD selection")
	ATTRIB(NexuizHudDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizHudDialog, intendedWidth, float, 0.6)
	ATTRIB(NexuizHudDialog, rows, float, 9)
	ATTRIB(NexuizHudDialog, columns, float, 4)
	ATTRIB(NexuizHudDialog, name, string, "HudMenu")
ENDCLASS(NexuizVcallDialog)
#endif

#ifdef IMPLEMENTATION
entity skinListNexuizHudDialog;
entity hudListNexuizHudDialog;

void(entity btn, entity me) applyNexuizHudDialog {
	if (hudListNexuizHudDialog.selectedItem >= 0)
		hudListNexuizHudDialog.clickListBoxItem(hudListNexuizHudDialog, hudListNexuizHudDialog.selectedItem, '0 0 0', 1); //emulate double click

	if (skinListNexuizHudDialog.selectedItem >= 0)
		skinListNexuizHudDialog.clickListBoxItem(skinListNexuizHudDialog, skinListNexuizHudDialog.selectedItem, '0 0 0', 1); //emulate double click

	GUI_Hide();
	GUI_Hide();
	GUI_Hide();
}

void(entity me) saveCvarsUseRMSkinsNexuizHudDialog {
	if (me.checked && !rm_skin_loaded) {
		rm_skin_load("default");
	} else if (!me.checked && rm_skin_loaded) {
		rm_skin_unload();
	}
}

void(entity me) loadCvarsUseRMSkinsNexuizHudDialog {
	me.checked = rm_skin_loaded;
}

void(entity me) fillNexuizHudDialog {
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, "Available HUDs:"));
	me.TR(me);
		me.TD(me, 6, 2, e = makeNexuizHudList());
		hudListNexuizHudDialog = e;
	me.TR(me);
	me.gotoRC(me, 0, 2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2, e = makeNexuizCheckBox(0, "cl_rm_skin", "Use RM skins:"));
		e.saveCvars = saveCvarsUseRMSkinsNexuizHudDialog;
		e.loadCvars = loadCvarsUseRMSkinsNexuizHudDialog;
		e.loadCvars(e);
	me.TR(me);
		me.TD(me, 6, 2, e = makeNexuizSkinList());
		skinListNexuizHudDialog = e;
	me.gotoRC(me, me.rows - 1, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2, e = makeNexuizButton("Apply", '0 0 0'));
			e.onClick = applyNexuizHudDialog;
		me.TD(me, 1, 2, e = makeNexuizCommandButton("Cancel", '0 0 0', "", 1));
}
#endif
