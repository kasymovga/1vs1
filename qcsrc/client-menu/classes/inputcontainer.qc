entity spawnInputContainer() {
	entity me; me = spawnContainer();
	me.keyDown = keyDownInputContainer;
	me.mouseMove = mouseMoveInputContainer;
	me.mousePress = mousePressInputContainer;
	me.mouseRelease = mouseReleaseInputContainer;
	me.mouseDrag = mouseDragInputContainer;
	me.focusLeave = focusLeaveInputContainer;
	me.resizeNotify = resizeNotifyInputContainer;
	me._changeFocusXY = _changeFocusXYInputContainer;
	me.mouseFocusedChild = NULL;
	me.isTabRoot = 0;
	me.instanceOfInputContainer = 1;
	me.classname = "InputContainer";
	return me;
}
void resizeNotifyInputContainer(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyContainer(me, relOrigin, relSize, absOrigin, absSize);
	/*
	if(me.parent.instanceOfInputContainer)
		me.isTabRoot = 0;
	else
		me.isTabRoot = 1;
	*/
}
void focusLeaveInputContainer(entity me)
{
	focusLeaveContainer(me);
	me.mouseFocusedChild = NULL;
}
float keyDownInputContainer(entity me, float scan, float ascii, float shift)
{
	entity f, ff;
	if(keyDownContainer(me, scan, ascii, shift))
		return 1;
	if(scan == VM_K_ESCAPE)
	{
		f = me.focusedChild;
		if(f)
		{
			me.setFocus(me, NULL);
			return 1;
		}
		return 0;
	}
	if(scan == VM_K_TAB)
	{
		f = me.focusedChild;
		if(shift & GUI_KEY_STATE_SHIFT)
		{
			if(f)
			{
				for(ff = f.prevSibling; ff; ff = ff.prevSibling)
				{
					if not(ff.focusable)
						continue;
					me.setFocus(me, ff);
					return 1;
				}
			}
			if(!f || me.isTabRoot)
			{
				for(ff = me.lastChild; ff; ff = ff.prevSibling)
				{
					if not(ff.focusable)
						continue;
					me.setFocus(me, ff);
					return 1;
				}
				return 0; // AIIIIEEEEE!
			}
		}
		else
		{
			if(f)
			{
				for(ff = f.nextSibling; ff; ff = ff.nextSibling)
				{
					if not(ff.focusable)
						continue;
					me.setFocus(me, ff);
					return 1;
				}
			}
			if(!f || me.isTabRoot)
			{
				for(ff = me.firstChild; ff; ff = ff.nextSibling)
				{
					if not(ff.focusable)
						continue;
					me.setFocus(me, ff);
					return 1;
				}
				return 0; // AIIIIEEEEE!
			}
		}
	}
	return 0;
}
float _changeFocusXYInputContainer(entity me, vector pos)
{
	entity e, ne;
	e = me.mouseFocusedChild;
	ne = me.itemFromPoint(me, pos);
	if(ne)
		if not(ne.focusable)
			ne = NULL;
	me.mouseFocusedChild = ne;
	if(ne)
		if(ne != e)
		{
			me.setFocus(me, ne);
			if(ne.instanceOfInputContainer)
			{
				ne.focusedChild = NULL;
				ne._changeFocusXY(e, gui_global_to_box(pos, ne.Container_origin, ne.Container_size));
			}
		}
	return (ne ? TRUE : FALSE);
}
float mouseDragInputContainer(entity me, vector pos)
{
	if(mouseDragContainer(me, pos))
		return 1;
	if(pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;
	return 0;
}
float mouseMoveInputContainer(entity me, vector pos)
{
	if(me._changeFocusXY(me, pos))
		if(mouseMoveContainer(me, pos))
			return 1;
	if(pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;
	return 0;
}
float mousePressInputContainer(entity me, vector pos)
{
	me.mouseFocusedChild = NULL; // force focusing
	if(me._changeFocusXY(me, pos))
		if(mousePressContainer(me, pos))
			return 1;
	if(pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;
	return 0;
}
float mouseReleaseInputContainer(entity me, vector pos)
{
	float r;
	r = mouseReleaseContainer(me, pos);
	if(me.focused) // am I still eligible for this? (UGLY HACK, but a mouse event could have changed focus away)
		if(me._changeFocusXY(me, pos))
			return 1;
	if(pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;
	return 0;
}
