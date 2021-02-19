#ifdef INTERFACE
CLASS(MainWindow) EXTENDS(ModalController)
	METHOD(MainWindow, configureMainWindow, void(entity))
ENDCLASS(MainWindow)
#endif

#ifdef IMPLEMENTATION

void QuitDialogClose(entity me) {
	GUI_Hide();
}

void configureMainWindowMainWindow(entity me)
{
	entity i;
	gui_gameMenuDialog = i = spawnNexuizGameMenuDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_teamSelectDialog = i = spawnNexuizTeamSelectDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_gameSettingsDialog = i = spawnNexuizGameSettingsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_voteCallDialog = i = spawnNexuizVcallDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_radioDialog = i = spawnNexuizRadioDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_saveLoad = i = spawnNexuizSaveLoadDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	gui_quitDialog = i = spawnNexuizQuitDialog();
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
	me.initializeDialog(me, me);
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
