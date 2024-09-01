#ifdef INTERFACE
#ifdef CSQC
#define SAVELOADTITLE "Save/Load Game"
#else
#define SAVELOADTITLE "Load Game"
#endif
CLASS(NexuizSaveLoadDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizSaveLoadDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizSaveLoadDialog, configureDialog, void(entity))
	METHOD(NexuizSaveLoadDialog, loadCvars, void(entity))
	ATTRIB(NexuizSaveLoadDialog, title, string, _(SAVELOADTITLE))
	ATTRIB(NexuizSaveLoadDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizSaveLoadDialog, intendedWidth, float, 0.5)
	ATTRIB(NexuizSaveLoadDialog, rows, float, 10)
	ATTRIB(NexuizSaveLoadDialog, columns, float, 6)
	ATTRIB(NexuizSaveLoadDialog, name, string, SAVELOADTITLE)
ENDCLASS(NexuizSaveLoadDialog)
#undef SAVELOADTITLE
#endif

#ifdef IMPLEMENTATION
string descriptionsNexuizSaveLoadDialog[14];

float slotNotEmptyNexuizSaveLoadDialog(float n) {
	return file_exists(strcat("slot", ftos(n), ".sav"));
}

.entity saveSlot;

void loadCvarsNexuizSaveLoadDialog(entity me) {
	entity e;
	float i;
	for (i = 0; i < 14; i++) {
		str_unzone_ifneeded(descriptionsNexuizSaveLoadDialog[i]);
		if (slotNotEmptyNexuizSaveLoadDialog(i + 1)) {
			descriptionsNexuizSaveLoadDialog[i] = cvar_string_zone_ifneeded(strcat("_slot_description", ftos(i + 1)));
		} else if (i < 10)
			descriptionsNexuizSaveLoadDialog[i] = strzone(strcat(_("Empty slot"), ftos(i + 1)));
		else if (i == 10 || i == 12)
			descriptionsNexuizSaveLoadDialog[i] = strzone(_("Autosave"));
		else
			descriptionsNexuizSaveLoadDialog[i] = strzone(_("Quicksave"));
	}
	i = 0;
	for (e = me.saveSlot; e; e = e.saveSlot) {
		e.setText(e, descriptionsNexuizSaveLoadDialog[i]);
		i++;
	}
}

void configureDialogNexuizSaveLoadDialog(entity me) {
	me.loadCvars(me);
	configureDialogNexuizDialog(me); //Parent method
}

float GetSlotNumber(entity e) {
	float i;
	i = 0;
	for (; e.saveSlot; e = e.saveSlot) {
		i++;
		if (e.saveSlot.forcePressed)
			return i;
	}
	return 0;
}

void loadGameNexuizSaveLoadDialog(entity btn, entity me) {
	float slot = GetSlotNumber(me);
	if (slotNotEmptyNexuizSaveLoadDialog(slot)) {
		localcmd(strcat("\nset _restore_game 1; maxplayers 1; load slot", ftos(slot), "\n"));
		localcmd(strcat("menu_cmd loadfallback slot", ftos(slot), ".sav\n"));
		me.close(me);
	}
}

#ifdef CSQC
void saveGameNexuizSaveLoadDialog(entity btn, entity me) {
	float slot = GetSlotNumber(me);
	localcmd(strcat("\nseta _slot_description", ftos(slot), " \""));
	localcmd(strcat(map_shortname, " - ", strftime(TRUE, "%Y %b %e %H:%M:%S")));
	localcmd(" \"\n");
	localcmd(strcat("\nsave slot", ftos(slot), "\nsaveconfig\nmenu_cmd sync\n"));
	me.close(me);
}
#endif

#ifdef CSQC
entity buttonSave;
#endif
void SlotSelect(entity btn, entity me) {
	entity e;
	for (e = me.saveSlot; e; e = e.saveSlot) {
		e.forcePressed = 0;
	}
	btn.forcePressed = 1;
#ifdef CSQC
	if (GetSlotNumber(me) > 10)
		buttonSave.disabled = TRUE;
	else
		buttonSave.disabled = FALSE;
#endif
}

#ifdef MENUQC
float mouseDoubleClickNexuizSaveLoadDialogSlot(entity btn, vector v) {
	loadGameNexuizSaveLoadDialog(btn, btn.onClickEntity);
	return TRUE;
}
#endif

void fillNexuizSaveLoadDialog(entity me)
{
	entity e;
	float i, j;
	e = me;
	for (i = 0; i < 14; i += 2) {
		me.TR(me);
			if (i == 10) {
				me.TD(me, 1, 3, makeNexuizTextLabel(0, _("Autosave:")));
				me.TD(me, 1, 3, makeNexuizTextLabel(0, _("Quicksave:")));
				me.TR(me);
			}
			for (j = 0; j < 2; j++) {
				me.TD(me, 1, 3, e.saveSlot = makeNexuizButton(descriptionsNexuizSaveLoadDialog[i + j], '0 0 0'));
				e = e.saveSlot;
				e.onClick = SlotSelect;
				e.onClickEntity = me;
#ifdef MENUQC
				e.mouseDoubleClick = mouseDoubleClickNexuizSaveLoadDialogSlot;
#endif
			}
	}
	me.TR(me);
	me.TR(me);
#ifdef CSQC
		float button_width = 3;
#else
		float button_width = 6;
#endif
#ifdef CSQC
		me.TD(me, 1, button_width, e = makeNexuizButton(_("Save"), '0 0 0'));
		buttonSave = e;
		e.onClick = saveGameNexuizSaveLoadDialog;
		e.onClickEntity = me;
#endif
		me.TD(me, 1, button_width, e = makeNexuizButton(_("Load"), '0 0 0'));
		e.onClick = loadGameNexuizSaveLoadDialog;
		e.onClickEntity = me;
}
#endif
