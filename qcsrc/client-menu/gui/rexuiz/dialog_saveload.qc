void(entity me) gui_rexuiz_dialog_saveload_configure;
void(entity me) gui_rexuiz_dialog_saveload_load;
void(entity me) gui_rexuiz_dialog_saveload_fill;

entity(void) gui_rexuiz_dialog_saveload_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_saveload_fill;
	me.configureDialog = gui_rexuiz_dialog_saveload_configure;
	me.loadCvars = gui_rexuiz_dialog_saveload_load;
	me.title = _("Load Game");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.5;
	me.rows = 10;
	me.columns = 6;
	me.name = "Load Game";
	me.classname = "NexuizSaveLoadDialog";
	return me;
}

string gui_rexuiz_dialog_saveload_descriptions[14];

float(float n) gui_rexuiz_dialog_saveload_slot_empty {
	return file_exists(strcat("slot", ftos(n), ".sav"));
}

.entity saveSlot;

void(entity me) gui_rexuiz_dialog_saveload_load {
	entity e;
	float i;
	for (i = 0; i < 14; i++) {
		str_unzone_ifneeded(gui_rexuiz_dialog_saveload_descriptions[i]);
		if (gui_rexuiz_dialog_saveload_slot_empty(i + 1)) {
			gui_rexuiz_dialog_saveload_descriptions[i] = cvar_string_zone_ifneeded(strcat("_slot_description", ftos(i + 1)));
		} else if (i < 10)
			gui_rexuiz_dialog_saveload_descriptions[i] = str_zone_ifneeded(strcat(_("Empty slot"), ftos(i + 1)));
		else if (i == 10 || i == 12)
			gui_rexuiz_dialog_saveload_descriptions[i] = str_zone_ifneeded(_("Autosave"));
		else
			gui_rexuiz_dialog_saveload_descriptions[i] = str_zone_ifneeded(_("Quicksave"));
	}
	i = 0;
	for (e = me.saveSlot; e; e = e.saveSlot) {
		e.setText(e, gui_rexuiz_dialog_saveload_descriptions[i]);
		i++;
	}
}

void(entity me) gui_rexuiz_dialog_saveload_configure {
	me.loadCvars(me);
	gui_rexuiz_dialog_configure(me); //Parent method
}

float(entity e) gui_rexuiz_dialog_saveload_slot_number {
	float i;
	i = 0;
	for (; e.saveSlot; e = e.saveSlot) {
		i++;
		if (e.saveSlot.forcePressed)
			return i;
	}
	return 0;
}

void(entity btn, entity me) gui_rexuiz_dialog_saveload_game_load {
	float slot = gui_rexuiz_dialog_saveload_slot_number(me);
	if (gui_rexuiz_dialog_saveload_slot_empty(slot)) {
		localcmd(strcat("\nset _restore_game 1; maxplayers 1; load slot", ftos(slot), "\n"));
		localcmd(strcat("menu_cmd loadfallback slot", ftos(slot), ".sav\n"));
		me.close(me);
	}
}

#ifdef CSQC
void(entity btn, entity me) gui_rexuiz_dialog_saveload_game_save {
	float slot = gui_rexuiz_dialog_saveload_slot_number(me);
	localcmd(strcat("\nseta _slot_description", ftos(slot), " \""));
	localcmd(strcat(map_shortname, " - ", strftime(TRUE, "%Y %b %e %H:%M:%S")));
	localcmd(" \"\n");
	localcmd(strcat("\nsave slot", ftos(slot), "\nsaveconfig\nmenu_cmd sync\n"));
	me.close(me);
}
#endif

#ifdef CSQC
entity gui_rexuiz_dialog_saveload_button_save;
#endif
void gui_rexuiz_dialog_saveload_slot_select(entity btn, entity me) {
	entity e;
	for (e = me.saveSlot; e; e = e.saveSlot) {
		e.forcePressed = 0;
	}
	btn.forcePressed = 1;
#ifdef CSQC
	if (gui_rexuiz_dialog_saveload_slot_number(me) > 10)
		gui_rexuiz_dialog_saveload_button_save.disabled = TRUE;
	else
		gui_rexuiz_dialog_saveload_button_save.disabled = FALSE;
#endif
}

#ifdef MENUQC
float(entity btn, vector v) gui_rexuiz_dialog_saveload_doubleclick {
	gui_rexuiz_dialog_saveload_game_load(btn, btn.onClickEntity);
	return TRUE;
}
#endif

void(entity me) gui_rexuiz_dialog_saveload_fill {
	entity e;
	float i, j;
	e = me;
	for (i = 0; i < 14; i += 2) {
		me.TR(me);
			if (i == 10) {
				me.TD(me, 1, 3, gui_rexuiz_textlabel_make(0, _("Autosave:")));
				me.TD(me, 1, 3, gui_rexuiz_textlabel_make(0, _("Quicksave:")));
				me.TR(me);
			}
			for (j = 0; j < 2; j++) {
				me.TD(me, 1, 3, e.saveSlot = gui_rexuiz_button_make(gui_rexuiz_dialog_saveload_descriptions[i + j], '0 0 0'));
					e = e.saveSlot;
					e.onClick = gui_rexuiz_dialog_saveload_slot_select;
					e.onClickEntity = me;
#ifdef MENUQC
					e.mouseDoubleClick = gui_rexuiz_dialog_saveload_doubleclick;
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
		me.TD(me, 1, button_width, e = gui_rexuiz_button_make(_("Save"), '0 0 0'));
			gui_rexuiz_dialog_saveload_button_save = e;
			e.onClick = gui_rexuiz_dialog_saveload_game_save;
			e.onClickEntity = me;
#endif
		me.TD(me, 1, button_width, e = gui_rexuiz_button_make(_("Load"), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_saveload_game_load;
			e.onClickEntity = me;
}
