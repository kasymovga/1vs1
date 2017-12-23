#ifdef INTERFACE
CLASS(MainWindow) EXTENDS(ModalController)
	METHOD(MainWindow, configureMainWindow, void(entity))
ENDCLASS(MainWindow)
#endif

#ifdef IMPLEMENTATION

void configureMainWindowMainWindow(entity me)
{
	entity n, i;
	GUI_gameMenuDialog = i = spawnNexuizGameMenuDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	GUI_teamSelectDialog = i = spawnNexuizTeamSelectDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	GUI_gameSettingsDialog = i = spawnNexuizGameSettingsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	GUI_voteCallDialog = i = spawnNexuizVcallDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.initializeDialog(me, me);
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
