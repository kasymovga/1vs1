void(entity me) gui_rexuiz_mainwindow_configure;

entity(void) gui_rexuiz_mainwindow_spawn {
	entity me = gui_modalcontroller_spawn();
	me.configureMainWindow = gui_rexuiz_mainwindow_configure;
	me.mutatorsDialog = NULL;
	me.oldMutatorsDialog = NULL;
	me.weaponsDialog = NULL;
	me.mapInfoDialog = NULL;
	me.userbindEditDialog = NULL;
	me.winnerDialog = NULL;
	me.hudDialog = NULL;
	me.serverInfoDialog = NULL;
	me.languageDialog = NULL;
	me.saveLoadDialog = NULL;
	me.mainNexposee = NULL;
	me.fadedAlpha = SKINALPHA_BEHIND;
	me.classname = "MainWindow";
	return me;
}

void(entity me) gui_rexuiz_mainwindow_configure {
	entity n, i;
	i = gui_rexuiz_dialog_teamselect_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.mutatorsDialog = i = gui_rexuiz_dialog_mutators_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.oldMutatorsDialog = i = gui_rexuiz_dialog_oldmutators_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.mapInfoDialog = i = gui_rexuiz_dialog_mapinfo_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.userbindEditDialog = i = gui_rexuiz_dialog_userbind_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.winnerDialog = i = gui_rexuiz_dialog_winner_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.weaponsDialog = i = gui_rexuiz_dialog_weapons_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.hudDialog = i = gui_rexuiz_dialog_hud_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.serverInfoDialog = i = gui_rexuiz_dialog_serverinfo_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.languageDialog = i = gui_rexuiz_dialog_language_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.saveLoadDialog = i = gui_rexuiz_dialog_saveload_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.mainNexposee = n = gui_rexuiz_nexposee_spawn();
	i = gui_rexuiz_dialog_singleplayer_spawn();
	i.configureDialog(i);
	n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	n.setNexposee(n, i, SKINPOSITION_DIALOG_SINGLEPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
	i = gui_rexuiz_dialog_multiplayer_spawn();
	i.configureDialog(i);
	n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	n.setNexposee(n, i, SKINPOSITION_DIALOG_MULTIPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
	i = gui_rexuiz_dialog_settings_spawn();
	i.configureDialog(i);
	n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	n.setNexposee(n, i, SKINPOSITION_DIALOG_SETTINGS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
	i = gui_rexuiz_dialog_credits_spawn();
	i.configureDialog(i);
	n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	n.setNexposee(n, i, SKINPOSITION_DIALOG_CREDITS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
	n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / gui_conheight));
	i = gui_rexuiz_dialog_quit_spawn();
	i.configureDialog(i);
	n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	n.setNexposee(n, i, SKINPOSITION_DIALOG_QUIT, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
	n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / gui_conheight));
	me.addItem(me, n, '0 0 0', '1 1 0', SKINALPHAS_MAINMENU_z);
	me.moveItemAfter(me, n, NULL);
	me.initializeDialog(me, n);
	if (cvar("_menu_show_language_dialog")) {
		cvar_set("_menu_show_language_dialog", "0");
		me.showChild(me, me.languageDialog, '0 0 0', '1 1 0', 0);
	}
}
