void(entity me) gui_rexuiz_weaponlist_configure;
void(entity me) gui_rexuiz_weaponlist_draw;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_weaponlist_resize;
float(entity me, vector pos) gui_rexuiz_weaponlist_mouse_drag;
string(entity me) gui_rexuiz_weaponlist_to_string;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_weaponlist_item_draw;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_weaponlist_key_down;

entity(void) gui_rexuiz_weaponlist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.configureNexuizWeaponsList = gui_rexuiz_weaponlist_configure;
	me.toString = gui_rexuiz_weaponlist_to_string;
	me.rowsPerItem = 1;
	me.draw = gui_rexuiz_weaponlist_draw;
	me.drawListBoxItem = gui_rexuiz_weaponlist_item_draw;
	me.resizeNotify = gui_rexuiz_weaponlist_resize;
	me.keyDown = gui_rexuiz_weaponlist_key_down;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.mouseDrag = gui_rexuiz_weaponlist_mouse_drag;
	me.classname = "NexuizWeaponsList";
	return me;
}

string(string order, float i, float j) gui_rexuiz_weaponlist_swap_in_priority {
	string s;
	float w, n;
	n = tokenize_console(order);
	if(i >= 0 && i < n && j >= 0 && j < n && i != j) {
		s = "";
		for(w = 0; w < n; ++w)
		{
				if(w == i)
				s = strcat(s, argv(j), " ");
				else if(w == j)
				s = strcat(s, argv(i), " ");
				else
				s = strcat(s, argv(w), " ");
		}
		return str_sub(s, 0, strlen(s) - 1);
	}
	return order;
}

entity(void) gui_rexuiz_weaponlist_make {
	entity me;
	me = gui_rexuiz_weaponlist_spawn();
	me.configureNexuizWeaponsList(me);
	return me;
}

void(entity me) gui_rexuiz_weaponlist_configure {
	me.configureNexuizListBox(me);
}

void(entity me) gui_rexuiz_weaponlist_draw {
	// read in cvar?
	string s, t;
	s = cvar_string("cl_weaponpriority");
	t = weapon_fix_order(s, 1);
	if (t != s) {
		print("Weapon priority list fixed\n");
		cvar_set("cl_weaponpriority", t);
	}
	me.nItems = tokenize_console(t);
	gui_listbox_draw(me);
}

void(entity box, entity me) gui_rexuiz_weaponlist_moveup_click {
	if (me.selectedItem > 0) {
		cvar_set("cl_weaponpriority", gui_rexuiz_weaponlist_swap_in_priority(cvar_string("cl_weaponpriority"), me.selectedItem - 1, me.selectedItem));
		me.selectedItem -= 1;
	}
}

void gui_rexuiz_weaponlist_movedown_click(entity box, entity me) {
	if (me.selectedItem < me.nItems - 1) {
		cvar_set("cl_weaponpriority", gui_rexuiz_weaponlist_swap_in_priority(cvar_string("cl_weaponpriority"), me.selectedItem, me.selectedItem + 1));
		me.selectedItem += 1;
	}
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_weaponlist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

float(entity me, vector pos) gui_rexuiz_weaponlist_mouse_drag {
	float f, i;
	i = me.selectedItem;
	f = gui_listbox_mouse_drag(me, pos);
	if (me.selectedItem != i)
		cvar_set("cl_weaponpriority", gui_rexuiz_weaponlist_swap_in_priority(cvar_string("cl_weaponpriority"), me.selectedItem, i));

	return f;
}

string(entity me) gui_rexuiz_weaponlist_to_string {
	float n, i;
	string s;
	entity e;
	n = tokenize_console(cvar_string("cl_weaponpriority"));
	s = "";
	for(i = 0; i < n; ++i)
	{
		e = weapon_info(stof(argv(i)));
		s = strcat(s, e.message, ", ");
	}
	return str_sub(s, 0, strlen(s) - 2);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_weaponlist_item_draw {
	entity e;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	e = weapon_info(stof(argv(i)));
	gui_draw_text(me.realUpperMargin * eY, e.message, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_weaponlist_key_down {
	if (ascii == 43) {
		gui_rexuiz_weaponlist_moveup_click(NULL, me);
		return 1;
	} else if(scan == 45) { // -
		gui_rexuiz_weaponlist_movedown_click(NULL, me);
		return 1;
	} else if(gui_listbox_key_down(me, scan, ascii, shift))
		return 1;

	return 0;
}
