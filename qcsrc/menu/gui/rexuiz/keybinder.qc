void(entity me) gui_rexuiz_keybinder_configure;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_keybinder_resize;
void(entity me, float key, float ascii) gui_rexuiz_keybinder_grabbed;
void(entity me, string theName, string theCommandPress, string theCommandRelease) gui_rexuiz_keybinder_userbind_edit;
void(entity me, float i, vector where, float doubleclick) gui_rexuiz_keybinder_item_click;
void(entity me, float i) gui_rexuiz_keybinder_select;
float(entity me, float key, float ascii, float shift) gui_rexuiz_keybinder_key_down;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_keybinder_item_draw;

entity(void) gui_rexuiz_keybinder_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.configureNexuizKeyBinder = gui_rexuiz_keybinder_configure;
	me.rowsPerItem = 1;
	me.drawListBoxItem = gui_rexuiz_keybinder_item_draw;
	me.clickListBoxItem = gui_rexuiz_keybinder_item_click;
	me.resizeNotify = gui_rexuiz_keybinder_resize;
	me.setSelected = gui_rexuiz_keybinder_select;
	me.keyDown = gui_rexuiz_keybinder_key_down;
	me.keyGrabbed = gui_rexuiz_keybinder_grabbed;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.columnFunctionOrigin = 0;
	me.columnFunctionSize = 0;
	me.columnKeysOrigin = 0;
	me.columnKeysSize = 0;
	me.previouslySelected = -1;
	me.inMouseHandler = 0;
	me.userbindEditButton = NULL;
	me.keyGrabButton = NULL;
	me.userbindEditDialog = NULL;
	me.editUserbind = gui_rexuiz_keybinder_userbind_edit;
	me.classname = "NexuizKeyBinder";
	return me;
}

string gui_rexuiz_keybinder_functions[256];
string gui_rexuiz_keybinder_descriptions[256];
var float gui_rexuiz_keybinder_count = -1;

void(void) gui_rexuiz_keybinder_read {
	float fh;
	string s;
	gui_rexuiz_keybinder_count = 0;
	fh = fopen(strcat("keybinds_", cvar_string("prvm_language"), ".txt"), FILE_READ);
	if (fh < 0)
		fh = fopen("keybinds.txt", FILE_READ);

	if (fh < 0)
		return;

	while ((s = fgets(fh))) {
		if (tokenize_console(s) != 2)
			continue;

		gui_rexuiz_keybinder_functions[gui_rexuiz_keybinder_count] = str_zone_ifneeded(argv(0));
		gui_rexuiz_keybinder_descriptions[gui_rexuiz_keybinder_count] = str_zone_ifneeded(argv(1));
		++gui_rexuiz_keybinder_count;
		if (gui_rexuiz_keybinder_count >= 256)
			break;
	}
	fclose(fh);
}

entity(void) gui_rexuiz_keybinder_make {
	entity me = gui_rexuiz_keybinder_spawn();
	me.configureNexuizKeyBinder(me);
	return me;
}

void(entity me) gui_rexuiz_keybinder_configure {
	me.configureNexuizListBox(me);
	if (gui_rexuiz_keybinder_count < 0)
		gui_rexuiz_keybinder_read();

	me.nItems = gui_rexuiz_keybinder_count;
	me.setSelected(me, 0);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_keybinder_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
	me.columnFunctionOrigin = 0;
	me.columnKeysSize = me.realFontSize_x * 12;
	me.columnFunctionSize = 1 - me.columnKeysSize - 2 * me.realFontSize_x;
	me.columnKeysOrigin = me.columnFunctionOrigin + me.columnFunctionSize + me.realFontSize_x;
	if (me.userbindEditButton)
		me.userbindEditButton.disabled = (str_sub(gui_rexuiz_keybinder_descriptions[me.selectedItem], 0, 1) != "$");
}

void(entity btn, entity me) gui_rexuiz_keybinder_change {
	string func;
	func = gui_rexuiz_keybinder_functions[me.selectedItem];
	if (func == "")
		return;

	me.keyGrabButton.forcePressed = 1;
	keyGrabber = me;
}

void(entity me, float key, float ascii) gui_rexuiz_keybinder_grabbed {
	float n, j, k, nvalid;
	string func;
	me.keyGrabButton.forcePressed = 0;
	if (key == VM_K_ESCAPE)
		return;

	func = gui_rexuiz_keybinder_functions[me.selectedItem];
	if (func == "")
		return;

	n = tokenize(findkeysforcommand(func)); // uses '...' strings
	nvalid = 0;
	for (j = 0; j < n; ++j) {
		k = stof(argv(j));
		if(k != -1)
			++nvalid;
	}
	if (nvalid >= 2) {
		for(j = 0; j < n; ++j) {
			k = stof(argv(j));
			if(k != -1)
				localcmd("\nunbind \"", keynumtostring(k), "\"\n");
		}
	}
	localcmd("\nbind \"", keynumtostring(key), "\" \"", func, "\"\n");
}

void(entity me, string theName, string theCommandPress, string theCommandRelease) gui_rexuiz_keybinder_userbind_edit {
	string func, descr;
	if (!me.userbindEditDialog)
		return;

	func = gui_rexuiz_keybinder_functions[me.selectedItem];
	if (func == "")
		return;

	descr = gui_rexuiz_keybinder_descriptions[me.selectedItem];
	if (str_sub(descr, 0, 1) != "$")
		return;

	descr = str_sub(descr, 1, strlen(descr) - 1);
	// Hooray! It IS a user bind!
	cvar_set(strcat(descr, "_description"), theName);
	cvar_set(strcat(descr, "_press"), theCommandPress);
	cvar_set(strcat(descr, "_release"), theCommandRelease);
}

void(entity btn, entity me) gui_rexuiz_keybinder_edit {
	string func, descr;
	if (!me.userbindEditDialog)
		return;

	func = gui_rexuiz_keybinder_functions[me.selectedItem];
	if (func == "")
		return;

	descr = gui_rexuiz_keybinder_descriptions[me.selectedItem];
	if (str_sub(descr, 0, 1) != "$")
		return;

	descr = str_sub(descr, 1, strlen(descr) - 1);
	// Hooray! It IS a user bind!
	me.userbindEditDialog.loadUserBind(me.userbindEditDialog, cvar_string(strcat(descr, "_description")), cvar_string(strcat(descr, "_press")), cvar_string(strcat(descr, "_release")));
	DialogOpenButton_Click(btn, me.userbindEditDialog);
}

void(entity btn, entity me) gui_rexuiz_keybinder_clear {
	float n, j, k;
	string func;
	func = gui_rexuiz_keybinder_functions[me.selectedItem];
	if (func == "")
		return;

	n = tokenize(findkeysforcommand(func)); // uses '...' strings
	for (j = 0; j < n; ++j) {
		k = stof(argv(j));
		if(k != -1)
			localcmd("\nunbind \"", keynumtostring(k), "\"\n");
	}
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_keybinder_item_click {
	if (doubleclick)
		gui_rexuiz_keybinder_change(NULL, me);
}

void(entity me, float i) gui_rexuiz_keybinder_select {
	// handling of "unselectable" items
	i = floor(0.5 + bound(0, i, me.nItems - 1));
	if (me.pressed == 0 || me.pressed == 1) { // keyboard or scrolling - skip unselectable items
		if (i > me.previouslySelected) {
			while((i < me.nItems - 1) && (gui_rexuiz_keybinder_functions[i] == ""))
			++i;
		}
		while((i > 0) && (gui_rexuiz_keybinder_functions[i] == ""))
			--i;

		while((i < me.nItems - 1) && (gui_rexuiz_keybinder_functions[i] == ""))
			++i;
	}
	if (me.pressed == 3) { // released the mouse - fall back to last valid item
		if (gui_rexuiz_keybinder_functions[i] == "")
			i = me.previouslySelected;
	}
	if (gui_rexuiz_keybinder_functions[i] != "")
		me.previouslySelected = i;

	if (me.userbindEditButton)
		me.userbindEditButton.disabled = (str_sub(gui_rexuiz_keybinder_descriptions[i], 0, 1) != "$");

	setSelectedListBox(me, i);
}

float(entity me, float key, float ascii, float shift) gui_rexuiz_keybinder_key_down {
	float r;
	r = 1;
	switch(key) {
	case VM_K_ENTER:
	case VM_K_SPACE:
		gui_rexuiz_keybinder_change(me, me);
		break;
	case VM_K_DEL:
	case VM_K_BACKSPACE:
		gui_rexuiz_keybinder_clear(me, me);
		break;
	default:
		r = keyDownListBox(me, key, ascii, shift);
		break;
	}
	return r;
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_keybinder_item_draw {
	string s;
	float j, k, n;
	vector theColor;
	float theAlpha;
	string func, descr;
	float extraMargin;
	descr = gui_rexuiz_keybinder_descriptions[i];
	func = gui_rexuiz_keybinder_functions[i];
	if (func == "") {
		theAlpha = 1;
		theColor = SKINCOLOR_KEYGRABBER_TITLES;
		theAlpha = SKINALPHA_KEYGRABBER_TITLES;
		extraMargin = 0;
	} else {
		if (isSelected) {
			if (keyGrabber == me)
				gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_WAITING, SKINALPHA_LISTBOX_WAITING);
			else
				gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
		}
		theAlpha = SKINALPHA_KEYGRABBER_KEYS;
		theColor = SKINCOLOR_KEYGRABBER_KEYS;
		extraMargin = me.realFontSize_x * 0.5;
	}
	if (str_sub(descr, 0, 1) == "$") {
		s = str_sub(descr, 1, strlen(descr) - 1);
		descr = cvar_string(strcat(s, "_description"));
		if (descr == "")
			descr = s;
		if (cvar_string(strcat(s, "_press")) == "")
			if(cvar_string(strcat(s, "_release")) == "")
				theAlpha *= SKINALPHA_DISABLED;
	}
	gui_draw_text(me.realUpperMargin * eY + extraMargin * eX, descr, me.realFontSize, theColor, theAlpha, 0);
	if (func != "") {
		n = tokenize(findkeysforcommand(func)); // uses '...' strings
		s = "";
		for (j = 0; j < n; ++j) {
			k = stof(argv(j));
			if (k != -1) {
				if (s != "")
					s = strcat(s, ", ");
				s = strcat(s, keynumtostring(k));
			}
		}
		s = gui_draw_text_shorten_to_width(s, me.columnKeysSize / me.realFontSize_x, 0);
		gui_draw_text_center(me.realUpperMargin * eY + (me.columnKeysOrigin + 0.5 * me.columnKeysSize) * eX, s, me.realFontSize, theColor, theAlpha, 0);
	}
}
