.void(entity e) drawGUI;
.entity frameGUI;
#define draw drawGUI
#define frame frameGUI
#include "../client-menu/classes.c"
#include "classes/nexuiz/rootdialog.c"
#include "classes/nexuiz/voteargslist.c"
#include "classes/nexuiz/votelist.c"
#include "classes/nexuiz/dialog_gamemenu.c"
#include "classes/nexuiz/dialog_gamesettings.c"
#include "classes/nexuiz/dialog_radio.c"
#include "classes/nexuiz/mainwindow.c"
#include "classes/nexuiz/dialog_vcall.c"
#include "classes/nexuiz/dialog_hint.c"
#include "classes/nexuiz/reportplayerlist.c"
#include "classes/nexuiz/reporttypelist.c"
#include "classes/nexuiz/dialog_report.c"
#include "classes/nexuiz/mutelist.c"
#include "classes/nexuiz/dialog_mutelist.c"
#include "classes/nexuiz/recordlist.c"
#include "classes/nexuiz/dialog_recordlist.c"
#include "classes/nexuiz/dialog_hud.c"
#include "classes/nexuiz/hudlist.c"
#include "classes/nexuiz/skinlist.c"
#undef draw
#undef frame
