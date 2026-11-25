void(entity me) gui_rexuiz_mainwindow_configure;

entity(void) gui_rexuiz_mainwindow_spawn {
	entity me = gui_modalcontroller_spawn();
	me.configureMainWindow = gui_rexuiz_mainwindow_configure;
	me.classname = "MainWindow";
	return me;
}

void(entity me) gui_rexuiz_mainwindow_dialog_quit_close {
	gui_hide();
}

void(entity me) gui_rexuiz_mainwindow_configure {
	entity i;
	gui_gamemenu = i = gui_rexuiz_dialog_gamemenu_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_teamselect = i = gui_rexuiz_dialog_teamselect_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_gamesettings = i = gui_rexuiz_dialog_gamesettings_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_votecall = i = gui_rexuiz_dialog_vcall_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_radio = i = gui_rexuiz_dialog_radio_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_saveload = i = gui_rexuiz_dialog_saveload_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_quit = i = gui_rexuiz_dialog_quit_spawn();
	i.close = gui_rexuiz_mainwindow_dialog_quit_close;
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_hint = i = gui_rexuiz_dialog_hint_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_report = i = gui_rexuiz_dialog_report_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_mutelist = i = gui_rexuiz_dialog_mutelist_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_recordlist = i = gui_rexuiz_dialog_recordlist_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_hud = i = gui_rexuiz_dialog_hud_spawn();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.initializeDialog(me, me);
}
