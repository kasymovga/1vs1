entity spawnMainWindow() {
	entity me; me = gui_modalcontroller_spawn();
	me.configureMainWindow = configureMainWindowMainWindow;
	me.classname = "MainWindow";
	return me;
}
void QuitDialogClose(entity me) {
	GUI_Hide();
}
void configureMainWindowMainWindow(entity me)
{
	entity i;
	gui_gameMenuDialog = i = gui_rexuiz_dialog_gamemenu_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_teamSelectDialog = i = gui_rexuiz_dialog_teamselect_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_gameSettingsDialog = i = gui_rexuiz_dialog_gamesettings_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_voteCallDialog = i = spawnNexuizVcallDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_radioDialog = i = spawnNexuizRadioDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_saveLoad = i = gui_rexuiz_dialog_saveload_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_quitDialog = i = gui_rexuiz_dialog_quit_spawn();
	i.close = QuitDialogClose;
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_hint = i = spawnNexuizHintDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_report = i = spawnNexuizReportDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_muteList = i = spawnNexuizMuteListDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_recordList = i = spawnNexuizRecordListDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_hud = i = spawnNexuizHudDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.initializeDialog(me, me);
}
