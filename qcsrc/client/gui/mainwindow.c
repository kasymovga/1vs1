#ifdef INTERFACE
CLASS(MainWindow) EXTENDS(ModalController)
	METHOD(MainWindow, configureMainWindow, void(entity))
	ATTRIB(MainWindow, teamSelectDialog, entity, NULL)
	ATTRIB(MainWindow, gameMenuDialog, entity, NULL)
ENDCLASS(MainWindow)
#endif

#ifdef IMPLEMENTATION

void configureMainWindowMainWindow(entity me)
{
	entity n, i;
	me.gameMenuDialog = i = spawnNexuizGameMenuDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.teamSelectDialog = i = spawnNexuizTeamSelectDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	me.initializeDialog(me, me);
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
