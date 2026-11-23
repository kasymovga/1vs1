void(entity me) gui_rexuiz_mainwindow_configure;

entity(void) gui_rexuiz_mainwindow_spawn {
	entity me = gui_modalcontroller_spawn();
	me.configureMainWindow = gui_rexuiz_mainwindow_configure;
	me.classname = "MainWindow";
	return me;
}

void(entity me) gui_rexuiz_mainwindow_dialog_quit_close {
	GUI_Hide();
}

void(entity me) gui_rexuiz_mainwindow_configure {
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
	gui_voteCallDialog = i = gui_rexuiz_dialog_vcall_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_radioDialog = i = gui_rexuiz_dialog_radio_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_saveLoad = i = gui_rexuiz_dialog_saveload_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_quitDialog = i = gui_rexuiz_dialog_quit_spawn();
	i.close = gui_rexuiz_mainwindow_dialog_quit_close;
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_hint = i = gui_rexuiz_dialog_hint_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_report = i = gui_rexuiz_dialog_report_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_muteList = i = gui_rexuiz_dialog_mutelist_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_recordList = i = gui_rexuiz_dialog_recordlist_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_hud = i = gui_rexuiz_dialog_hud_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.initializeDialog(me, me);
}
