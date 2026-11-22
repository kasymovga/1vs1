entity spawnItem() {
	entity me; me = spawnObject();
	me.draw = drawItem;
	me.keyDown = keyDownItem;
	me.keyUp = keyUpItem;
	me.mouseMove = mouseMoveItem;
	me.mousePress = mousePressItem;
	me.mouseDrag = mouseDragItem;
	me.mouseRelease = mouseReleaseItem;
	me.focusEnter = focusEnterItem;
	me.focusLeave = focusLeaveItem;
	me.resizeNotify = resizeNotifyItem;
	me.relinquishFocus = relinquishFocusItem;
	me.showNotify = showNotifyItem;
	me.hideNotify = hideNotifyItem;
	me.toString = toStringItem;
	me.destroy = destroyItem;
	me.nexuizFont = 0;
	me.focused = 0;
	me.focusable = 0;
	me.parent = NULL;
	me.preferredFocusPriority = 0;
	me.origin = '0 0 0';
	me.size = '0 0 0';
	me.classname = "Item";
	return me;
}
void destroyItem(entity me)
{
	// free memory associated with me
}
void relinquishFocusItem(entity me)
{
	if(me.parent)
		if(me.parent.instanceOfContainer)
			me.parent.setFocus(me.parent, NULL);
}
void resizeNotifyItem(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.origin = absOrigin;
	me.size = absSize;
}
void drawItem(entity me)
{
}
void showNotifyItem(entity me)
{
}
void hideNotifyItem(entity me)
{
}
float keyDownItem(entity me, float scan, float ascii, float shift)
{
	return 0; // unhandled
}
float keyUpItem(entity me, float scan, float ascii, float shift)
{
	return 0; // unhandled
}
float mouseMoveItem(entity me, vector pos)
{
	return 0; // unhandled
}
float mousePressItem(entity me, vector pos)
{
	return 0; // unhandled
}
float mouseDragItem(entity me, vector pos)
{
	return 0; // unhandled
}
float mouseReleaseItem(entity me, vector pos)
{
	return 0; // unhandled
}
void focusEnterItem(entity me)
{
}
void focusLeaveItem(entity me)
{
}
string toStringItem(entity me)
{
	return NULL;
}
