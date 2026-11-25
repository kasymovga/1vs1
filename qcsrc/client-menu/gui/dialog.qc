void(entity me) gui_dialog_fill;
void(entity me, float row, float col, float rowspan, float colspan, entity e, vector v) gui_dialog_item_simple_add;
void(entity me, float row, float col) gui_dialog_gotorc;
void(entity me) gui_dialog_tr;
void(entity me, float rowspan, float colspan, entity e) gui_dialog_td;
void(entity me, float rowspan, float colspan, entity e, vector v) gui_dialog_tdnomargin;
void(entity me, float col) gui_dialog_column_first_set;
void(entity me, float colspan) gui_dialog_td_empty;
void(entity me) gui_dialog_close;
float(entity me, float key, float ascii, float shift) gui_dialog_key_down;

entity(void) gui_dialog_spawn {
	entity me; me = gui_inputcontainer_spawn();
	me.configureDialog = gui_dialog_configure; // no runtime configuration, all parameters are given in the code!
	me.fill = gui_dialog_fill; // to be overridden by user to fill the dialog with controls
	me.keyDown = gui_dialog_key_down;
	me.close = gui_dialog_close;
	me.addItemSimple = gui_dialog_item_simple_add;
	me.TD = gui_dialog_td;
	me.TDNoMargin = gui_dialog_tdnomargin;
	me.TDempty = gui_dialog_td_empty;
	me.setFirstColumn = gui_dialog_column_first_set;
	me.TR = gui_dialog_tr;
	me.gotoRC = gui_dialog_gotorc;
	me.isTabRoot = 1;
	me.closeButton = NULL;
	me.intendedHeight = 0;
	me.itemOrigin = '0 0 0';
	me.itemSize = '0 0 0';
	me.itemSpacing = '0 0 0';
	me.currentRow = 0;
	me.currentColumn = 0;
	me.firstColumn = 0;
	// to be customized
	me.closable = 1;
	me.title = "Form1"; // ;)
	me.color = '1 0.5 1';
	me.intendedWidth = 0;
	me.rows = 3;
	me.columns = 2;
	me.marginTop = 0; // pixels
	me.marginBottom = 0; // pixels
	me.marginLeft = 0; // pixels
	me.marginRight = 0; // pixels
	me.columnSpacing = 0; // pixels
	me.rowSpacing = 0; // pixels
	me.rowHeight = 0; // pixels
	me.titleHeight = 0; // pixels
	me.titleFontSize = 0; // pixels; if 0, title causes no margin
	me.zoomedOutTitleBarPosition = 0;
	me.zoomedOutTitleBar = 0;
	me.backgroundImage = NULL;
	me.closeButtonImage = NULL;
	me.frame = NULL;
	me.instanceOfDialog = 1;
	me.classname = "Dialog";
	return me;
}

void(entity button, entity me) gui_dialog_button_close {
	me.close(me);
}

void(entity me) gui_dialog_fill {
}

void(entity me, float row, float col, float rowspan, float colspan, entity e, vector v) gui_dialog_item_simple_add {
	//print(vtos(me.itemSpacing), " ", vtos(me.itemSize), "\n");
	vector o, s;
	o = me.itemOrigin + eX * ( col * me.itemSpacing_x) + eY * ( row * me.itemSpacing_y);
	s = me.itemSize + eX * ((colspan - 1) * me.itemSpacing_x) + eY * ((rowspan - 1) * me.itemSpacing_y);
	o_x -= 0.5 * (me.itemSpacing_x - me.itemSize_x) * v_x;
	s_x += (me.itemSpacing_x - me.itemSize_x) * v_x;
	o_y -= 0.5 * (me.itemSpacing_y - me.itemSize_y) * v_y;
	s_y += (me.itemSpacing_y - me.itemSize_y) * v_y;
	me.addItem(me, e, o, s, 1);
}

void(entity me, float row, float col) gui_dialog_gotorc {
	me.currentRow = row;
	me.currentColumn = col;
}

void(entity me) gui_dialog_tr {
	me.currentRow += 1;
	me.currentColumn = me.firstColumn;
}

void(entity me, float rowspan, float colspan, entity e) gui_dialog_td {
	me.addItemSimple(me, me.currentRow, me.currentColumn, rowspan, colspan, e, '0 0 0');
	me.currentColumn += colspan;
}

void(entity me, float rowspan, float colspan, entity e, vector v) gui_dialog_tdnomargin {
	me.addItemSimple(me, me.currentRow, me.currentColumn, rowspan, colspan, e, v);
	me.currentColumn += colspan;
}

void(entity me, float col) gui_dialog_column_first_set {
	me.firstColumn = col;
}

void(entity me, float colspan) gui_dialog_td_empty {
	me.currentColumn += colspan;
}

void(entity me) gui_dialog_configure {
	entity closebutton = NULL;
	float absWidth, absHeight;
	me.frame = gui_borderimage_spawn();
	me.frame.configureBorderImage(me.frame, me.title, me.titleFontSize, me.color, me.backgroundImage, me.titleHeight);
	me.frame.zoomedOutTitleBarPosition = me.zoomedOutTitleBarPosition;
	me.frame.zoomedOutTitleBar = me.zoomedOutTitleBar;
	me.frame.alpha = me.alpha;
	me.addItem(me, me.frame, '0 0 0', '1 1 0', 1);
	if not(me.titleFontSize)
		me.titleHeight = 0; // no title bar

	absWidth = me.intendedWidth * gui_conwidth;
	absHeight = me.titleHeight + me.marginTop + me.rows * me.rowHeight + (me.rows - 1) * me.rowSpacing + me.marginBottom;
	me.itemOrigin = eX * (me.marginLeft / absWidth)
			+ eY * ((me.titleHeight + me.marginTop) / absHeight);
	me.itemSize = eX * ((1 - (me.marginLeft + me.marginRight + me.columnSpacing * (me.columns - 1)) / absWidth) / me.columns)
			+ eY * (me.rowHeight / absHeight);
	me.itemSpacing = me.itemSize
			+ eX * (me.columnSpacing / absWidth)
			+ eY * (me.rowSpacing / absHeight);
	me.intendedHeight = absHeight / gui_conheight;
	me.currentRow = -1;
	me.currentColumn = -1;
	me.fill(me);
	if (me.closable) {
		closebutton = me.closeButton = gui_button_spawn();
		closebutton.configureButton(closebutton, "Close", 0, me.closeButtonImage);
		closebutton.onClick = gui_dialog_button_close; closebutton.onClickEntity = me;
		closebutton.srcMulti = 0;
		me.addItem(me, closebutton, '0 0 0', '1 1 0', 1); // put it as LAST
	}
	me.frame.closeButton = closebutton;
}

void(entity me) gui_dialog_close {
	if (me.parent.instanceOfNexposee) {
		gui_nexposee_close_click(me, me.parent);
	} else if(me.parent.instanceOfModalController) {
		gui_modalcontroller_open_click(me, me);
	}
}

float(entity me, float key, float ascii, float shift) gui_dialog_key_down {
	if (me.closable) {
		if (key == VM_K_ESCAPE) {
			me.close(me);
			return 1;
		}
	}
	return gui_inputcontainer_key_down(me, key, ascii, shift);
}
