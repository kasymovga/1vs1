// Note: this class is called Dialog, but it can also handle a tab under the following conditions:
// - isTabRoot is 0
// - backgroundImage is the tab's background
// - closable is 0
// - rootDialog is 0
// - title is ""
// - marginTop is 
// - intendedHeight ends up to be the tab's actual height, or at least close
// - titleFontSize is 0
// - marginTop cancels out as much of titleHeight as needed (that is, it should be actualMarginTop - titleHeight)
// To ensure the latter, you best create all tabs FIRST and insert the tabbed
// control to your dialog THEN - with the right height
//
// a subclass may help with using this as a tab
entity spawnDialog() {
	entity me; me = spawnInputContainer();
	me.configureDialog = configureDialogDialog; // no runtime configuration, all parameters are given in the code!
	me.fill = fillDialog; // to be overridden by user to fill the dialog with controls
	me.keyDown = keyDownDialog;
	me.close = closeDialog;
	me.addItemSimple = addItemSimpleDialog;
	me.TD = TDDialog;
	me.TDNoMargin = TDNoMarginDialog;
	me.TDempty = TDemptyDialog;
	me.setFirstColumn = setFirstColumnDialog;
	me.TR = TRDialog;
	me.gotoRC = gotoRCDialog;
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
// Note: this class is called Dialog, but it can also handle a tab under the following conditions:
// - isTabRoot is 0
// - backgroundImage is the tab's background
// - closable is 0
// - rootDialog is 0
// - title is ""
// - marginTop is 
// - intendedHeight ends up to be the tab's actual height, or at least close
// - titleFontSize is 0
// - marginTop cancels out as much of titleHeight as needed (that is, it should be actualMarginTop - titleHeight)
// To ensure the latter, you best create all tabs FIRST and insert the tabbed
// control to your dialog THEN - with the right height
//
// a subclass may help with using this as a tab
void Dialog_Close(entity button, entity me)
{
	me.close(me);
}
void fillDialog(entity me)
{
}
void addItemSimpleDialog(entity me, float row, float col, float rowspan, float colspan, entity e, vector v)
{
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
void gotoRCDialog(entity me, float row, float col)
{
	me.currentRow = row;
	me.currentColumn = col;
}
void TRDialog(entity me)
{
	me.currentRow += 1;
	me.currentColumn = me.firstColumn;
}
void TDDialog(entity me, float rowspan, float colspan, entity e)
{
	me.addItemSimple(me, me.currentRow, me.currentColumn, rowspan, colspan, e, '0 0 0');
	me.currentColumn += colspan;
}
void TDNoMarginDialog(entity me, float rowspan, float colspan, entity e, vector v)
{
	me.addItemSimple(me, me.currentRow, me.currentColumn, rowspan, colspan, e, v);
	me.currentColumn += colspan;
}
void setFirstColumnDialog(entity me, float col)
{
	me.firstColumn = col;
}
void TDemptyDialog(entity me, float colspan)
{
	me.currentColumn += colspan;
}
void configureDialogDialog(entity me)
{
	entity closebutton = NULL;
	float absWidth, absHeight;
	me.frame = spawnBorderImage();
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
	if(me.closable)
	{
		closebutton = me.closeButton = spawnButton();
		closebutton.configureButton(closebutton, "Close", 0, me.closeButtonImage);
		closebutton.onClick = Dialog_Close; closebutton.onClickEntity = me;
		closebutton.srcMulti = 0;
		me.addItem(me, closebutton, '0 0 0', '1 1 0', 1); // put it as LAST
	}
	me.frame.closeButton = closebutton;
}
void closeDialog(entity me)
{
	if(me.parent.instanceOfNexposee)
	{
		ExposeeCloseButton_Click(me, me.parent);
	}
	else if(me.parent.instanceOfModalController)
	{
		DialogCloseButton_Click(me, me);
	}
}
float keyDownDialog(entity me, float key, float ascii, float shift)
{
	if(me.closable)
	{
		if(key == VM_K_ESCAPE)
		{
			me.close(me);
			return 1;
		}
	}
	return keyDownInputContainer(me, key, ascii, shift);
}
