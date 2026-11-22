entity spawnMainWindow() {
	entity me; me = gui_modalcontroller_spawn();
	me.configureMainWindow = configureMainWindowMainWindow;
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
/* Click. The c-word is here so you can grep for it :-) */
void configureMainWindowMainWindow(entity me)
{
	entity n, i;
	i = spawnNexuizTeamSelectDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.mutatorsDialog = i = spawnNexuizMutatorsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.oldMutatorsDialog = i = spawnNexuizOldMutatorsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.mapInfoDialog = i = spawnNexuizMapInfoDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.userbindEditDialog = i = spawnNexuizUserbindEditDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.winnerDialog = i = spawnNexuizWinnerDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.weaponsDialog = i = spawnNexuizWeaponsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.hudDialog = i = spawnNexuizHUDDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.serverInfoDialog = i = spawnNexuizServerInfoDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.languageDialog = i = spawnNexuizLanguageDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.saveLoadDialog = i = spawnNexuizSaveLoadDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.mainNexposee = n = spawnNexuizNexposee();
		i = spawnNexuizSingleplayerDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_SINGLEPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		i = spawnNexuizMultiplayerDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_MULTIPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		i = spawnNexuizSettingsDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_SETTINGS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		i = spawnNexuizCreditsDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_CREDITS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / gui_conheight));
		i = spawnNexuizQuitDialog();
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
/* Click. The c-word is here so you can grep for it :-) */
