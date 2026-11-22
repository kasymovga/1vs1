entity spawnListBox() {
	entity me; me = spawnItem();
	me.resizeNotify = resizeNotifyListBox;
	me.configureListBox = configureListBoxListBox;
	me.draw = drawListBox;
	me.keyDown = keyDownListBox;
	me.mousePress = mousePressListBox;
	me.mouseDrag = mouseDragListBox;
	me.mouseRelease = mouseReleaseListBox;
	me.mouseDoubleClick = mouseDoubleClickListBox;
	me.focusable = 1;
	me.selectedItem = 0;
	me.size = '0 0 0';
	me.origin = '0 0 0';
	me.scrollPos = 0; // measured in window heights, fixed when needed
	me.previousValue = 0;
	me.pressed = 0; // 0 = normal, 1 = scrollbar dragging, 2 = item dragging, 3 = released
	me.pressOffset = 0;
	me.updateControlTopBottom = updateControlTopBottomListBox;
	me.controlTop = 0;
	me.controlBottom = 0;
	me.controlWidth = 0;
	me.dragScrollTimer = 0;
	me.dragScrollPos = '0 0 0';
	me.src = NULL; // scrollbar
	me.color = '1 1 1';
	me.color2 = '1 1 1';
	me.colorC = '1 1 1';
	me.colorF = '1 1 1';
	me.tolerance = '0 0 0'; // drag tolerance
	me.scrollbarWidth = 0; // pixels
	me.nItems = 42;
	me.itemHeight = 0;
	me.drawListBoxItem = drawListBoxItemListBox; // item number, width/height, selected
	me.clickListBoxItem = clickListBoxItemListBox; // item number, relative clickpos, double click
	me.setSelected = setSelectedListBox;
	me.classname = "ListBox";
	return me;
}
void setSelectedListBox(entity me, float i)
{
	me.selectedItem = floor(0.5 + bound(0, i, me.nItems - 1));
}
void resizeNotifyListBox(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyItem(me, relOrigin, relSize, absOrigin, absSize);
	me.controlWidth = me.scrollbarWidth / absSize_x;
}
void configureListBoxListBox(entity me, float theScrollbarWidth, float theItemHeight)
{
	me.scrollbarWidth = theScrollbarWidth;
	me.itemHeight = theItemHeight;
}
float keyDownListBox(entity me, float key, float ascii, float shift)
{
	me.dragScrollTimer = time;
	if(key == VM_K_MWHEELUP)
	{
		me.scrollPos = max(me.scrollPos - 0.5, 0);
		me.setSelected(me, min(me.selectedItem, floor((me.scrollPos + 1) / me.itemHeight - 1)));
	}
	else if(key == VM_K_MWHEELDOWN)
	{
		me.scrollPos = min(me.scrollPos + 0.5, me.nItems * me.itemHeight - 1);
		me.setSelected(me, max(me.selectedItem, ceil(me.scrollPos / me.itemHeight)));
	}
	else if(key == VM_K_PGUP)
		me.setSelected(me, me.selectedItem - 1 / me.itemHeight);
	else if(key == VM_K_PGDN)
		me.setSelected(me, me.selectedItem + 1 / me.itemHeight);
	else if(key == VM_K_UPARROW)
		me.setSelected(me, me.selectedItem - 1);
	else if(key == VM_K_DOWNARROW)
		me.setSelected(me, me.selectedItem + 1);
	else if(key == VM_K_HOME)
	{
		me.scrollPos = 0;
		me.setSelected(me, 0);
	}
	else if(key == VM_K_END)
	{
		me.scrollPos = max(0, me.nItems * me.itemHeight - 1);
		me.setSelected(me, me.nItems - 1);
	}
	else
		return 0;
	return 1;
}
float mouseDragListBox(entity me, vector pos)
{
	float hit;
	float i;
	me.updateControlTopBottom(me);
	me.dragScrollPos = pos;
	if(me.pressed == 1)
	{
		hit = 1;
		if(pos_x < 1 - me.controlWidth - me.tolerance_y * me.controlWidth) hit = 0;
		if(pos_y < 0 - me.tolerance_x) hit = 0;
		if(pos_x >= 1 + me.tolerance_y * me.controlWidth) hit = 0;
		if(pos_y >= 1 + me.tolerance_x) hit = 0;
		if(hit)
		{
			// calculate new pos to v
			float delta;
			delta = (pos_y - me.pressOffset) / (1 - (me.controlBottom - me.controlTop)) * (me.nItems * me.itemHeight - 1);
			me.scrollPos = me.previousValue + delta;
		}
		else
			me.scrollPos = me.previousValue;
		me.scrollPos = min(me.scrollPos, me.nItems * me.itemHeight - 1);
		me.scrollPos = max(me.scrollPos, 0);
		i = min(me.selectedItem, floor((me.scrollPos + 1) / me.itemHeight - 1));
		i = max(i, ceil(me.scrollPos / me.itemHeight));
		me.setSelected(me, i);
	}
	else if(me.pressed == 2)
	{
		me.setSelected(me, floor((me.scrollPos + pos_y) / me.itemHeight));
	}
	return 1;
}
float mousePressListBox(entity me, vector pos)
{
	if(pos_x < 0) return 0;
	if(pos_y < 0) return 0;
	if(pos_x >= 1) return 0;
	if(pos_y >= 1) return 0;
	me.dragScrollPos = pos;
	me.updateControlTopBottom(me);
	me.dragScrollTimer = time;
	if(pos_x >= 1 - me.controlWidth)
	{
		// if hit, set me.pressed, otherwise scroll by one page
		if(pos_y < me.controlTop)
		{
			// page up
			me.scrollPos = max(me.scrollPos - 1, 0);
			me.setSelected(me, min(me.selectedItem, floor((me.scrollPos + 1) / me.itemHeight - 1)));
		}
		else if(pos_y > me.controlBottom)
		{
			// page down
			me.scrollPos = min(me.scrollPos + 1, me.nItems * me.itemHeight - 1);
			me.setSelected(me, max(me.selectedItem, ceil(me.scrollPos / me.itemHeight)));
		}
		else
		{
			me.pressed = 1;
			me.pressOffset = pos_y;
			me.previousValue = me.scrollPos;
		}
	}
	else
	{
		// continue doing that while dragging (even when dragging outside). When releasing, forward the click to the then selected item.
		me.pressed = 2;
		// an item has been clicked. Select it, ...
		me.setSelected(me, floor((me.scrollPos + pos_y) / me.itemHeight));
	}
	return 1;
}
float mouseReleaseListBox(entity me, vector pos)
{
	vector absSize;
	if(me.pressed == 1)
	{
		// slider dragging mode
		// in that case, nothing happens on releasing
	}
	else if(me.pressed == 2)
	{
		me.pressed = 3; // do that here, so setSelected can know the mouse has been released
		// item dragging mode
		// select current one one last time...
		me.setSelected(me, floor((me.scrollPos + pos_y) / me.itemHeight));
		// and give it a nice click event
		if(me.nItems > 0)
		{
			absSize = gui_box_to_global_size(me.size, eX * (1 - me.controlWidth) + eY * me.itemHeight);
			me.clickListBoxItem(me, me.selectedItem, gui_global_to_box(pos, eY * (me.selectedItem * me.itemHeight - me.scrollPos), eX * (1 - me.controlWidth) + eY * me.itemHeight), 0);
		}
	}
	me.pressed = 0;
	return 1;
}
float mouseDoubleClickListBox(entity me, vector pos) {
	if (me.pressed == 2) {
		me.clickListBoxItem(me, me.selectedItem, gui_global_to_box(pos, eY * (me.selectedItem * me.itemHeight - me.scrollPos), eX * (1 - me.controlWidth) + eY * me.itemHeight), 1);
		return 1;
	}
	return 0;
}
void updateControlTopBottomListBox(entity me)
{
	float f;
	// scrollPos is in 0..1 and indicates where the "page" currently shown starts.
	if(me.nItems * me.itemHeight <= 1)
	{
		// we don't need no stinkin' scrollbar, we don't need no view control...
		me.controlTop = 0;
		me.controlBottom = 1;
		me.scrollPos = 0;
	}
	else
	{
		if(frametime) // only do this in draw frames
		{
			if(me.dragScrollTimer < time)
			{
				float save;
				save = me.scrollPos;
				// if selected item is below listbox, increase scrollpos so it is in
				me.scrollPos = max(me.scrollPos, me.selectedItem * me.itemHeight - 1 + me.itemHeight);
				// if selected item is above listbox, decrease scrollpos so it is in
				me.scrollPos = min(me.scrollPos, me.selectedItem * me.itemHeight);
				if(me.scrollPos != save)
					me.dragScrollTimer = time + 0.2;
			}
		}
		// if scroll pos is below end of list, fix it
		me.scrollPos = min(me.scrollPos, me.nItems * me.itemHeight - 1);
		// if scroll pos is above beginning of list, fix it
		me.scrollPos = max(me.scrollPos, 0);
		// now that we know where the list is scrolled to, find out where to draw the control
		me.controlTop = max(0, me.scrollPos / (me.nItems * me.itemHeight));
		me.controlBottom = min((me.scrollPos + 1) / (me.nItems * me.itemHeight), 1);
		float fmin;
		fmin = 1 * me.controlWidth / me.size_y * me.size_x;
		f = me.controlBottom - me.controlTop;
		if(f < fmin) // FIXME good default?
		{
			// f * X + 1 * (1-X) = fmin
			// (f - 1) * X + 1 = fmin
			// (f - 1) * X = fmin - 1
			// X = (fmin - 1) / (f - 1)
			f = (fmin - 1) / (f - 1);
			me.controlTop = me.controlTop * f + 0 * (1 - f);
			me.controlBottom = me.controlBottom * f + 1 * (1 - f);
		}
	}
}
void drawListBox(entity me)
{
	float i;
	vector absSize;
	vector oldshift, oldscale;
	if(me.pressed == 2)
		me.mouseDrag(me, me.dragScrollPos); // simulate mouseDrag event
	me.updateControlTopBottom(me);
	if(me.controlWidth)
	{
		gui_draw_button_picture_vertical(eX * (1 - me.controlWidth), strcat(me.src, "_s"), eX * me.controlWidth + eY, me.color2, 1);
		if(me.nItems * me.itemHeight > 1)
		{
			vector o, s;
			o = eX * (1 - me.controlWidth) + eY * me.controlTop;
			s = eX * me.controlWidth + eY * (me.controlBottom - me.controlTop);
			if(me.pressed == 1)
				gui_draw_button_picture_vertical(o, strcat(me.src, "_c"), s, me.colorC, 1);
			else if(me.focused)
				gui_draw_button_picture_vertical(o, strcat(me.src, "_f"), s, me.colorF, 1);
			else
				gui_draw_button_picture_vertical(o, strcat(me.src, "_n"), s, me.color, 1);
		}
	}
	gui_draw_set_clip();
	oldshift = gui_draw_shift;
	oldscale = gui_draw_scale;
	absSize = gui_box_to_global_size(me.size, eX * (1 - me.controlWidth) + eY * me.itemHeight);
	float odf = drawfont;
	float nf = FALSE;
	if (me.nexuizFont)
	if (cvar("utf8_oldfont_for_oldchars"))
	if (cvar("font3_is_unicode_compat"))
		drawfont = FONT_USER + 0;
	for(i = floor(me.scrollPos / me.itemHeight); i < me.nItems; ++i)
	{
		float y;
		y = i * me.itemHeight - me.scrollPos;
		if(y >= 1)
			break;
		gui_draw_shift = gui_box_to_global(eY * y, oldshift, oldscale);
		gui_draw_scale = gui_box_to_global_size(eY * me.itemHeight + eX * (1 - me.controlWidth), oldscale);
		me.drawListBoxItem(me, i, absSize, (me.selectedItem == i));
	}
	drawfont = odf;
	gui_draw_clip_clear();
}
void clickListBoxItemListBox(entity me, float i, vector where, float doubleclick)
{
	// itemclick, itemclick, does whatever itemclick does
}
void drawListBoxItemListBox(entity me, float i, vector absSize, float selected)
{
	gui_draw_text('0 0 0', strcat("Item ", ftos(i)), eX * (8 / absSize_x) + eY * (8 / absSize_y), (selected ? '0 1 0' : '1 1 1'), 1, 0);
}
