.void(entity e) drawGUI;
.entity frameGUI;
#define draw drawGUI
#define frame frameGUI
#define conwidth CVAR(vid_conwidth)
#define conheight CVAR(vid_conheight)
#define other _other
#include "../client-menu/item.c"
#include "../client-menu/item/container.c"
#include "../client-menu/item/inputcontainer.c"
#include "../client-menu/item/nexposee.c"
#include "../client-menu/item/modalcontroller.c"
#include "../client-menu/item/image.c"
#include "../client-menu/item/label.c"
#include "../client-menu/item/button.c"
#include "../client-menu/item/checkbox.c"
#include "../client-menu/item/radiobutton.c"
#include "../client-menu/item/borderimage.c"
#include "../client-menu/item/slider.c"
#include "../client-menu/item/dialog.c"
#include "../client-menu/item/tab.c"
#include "../client-menu/item/textslider.c"
#include "../client-menu/item/listbox.c"
#include "../client-menu/item/inputbox.c"
#include "../client-menu/nexuiz/dialog.c"
#include "../client-menu/nexuiz/rootdialog.c"
#include "../client-menu/nexuiz/button.c"
#include "../client-menu/nexuiz/commandbutton.c"
#include "../client-menu/nexuiz/bigcommandbutton.c"
#include "gui/dialog_teamselect.c"
#undef draw
#undef frame
#undef conwidth
#undef conheight
#undef other
