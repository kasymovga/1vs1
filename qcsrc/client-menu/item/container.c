#ifdef INTERFACE
CLASS(Container) EXTENDS(Item)
	METHOD(Container, draw, void(entity))
	METHOD(Container, keyUp, float(entity, float, float, float))
	METHOD(Container, keyDown, float(entity, float, float, float))
	METHOD(Container, mouseMove, float(entity, vector))
	METHOD(Container, mousePress, float(entity, vector))
	METHOD(Container, mouseDrag, float(entity, vector))
	METHOD(Container, mouseRelease, float(entity, vector))
	METHOD(Container, focusLeave, void(entity))
	METHOD(Container, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(Container, resizeNotifyLie, void(entity, vector, vector, vector, vector, .vector, .vector))
	METHOD(Container, addItem, void(entity, entity, vector, vector, float))
	METHOD(Container, addItemCentered, void(entity, entity, vector, float))
	METHOD(Container, moveItemAfter, void(entity, entity, entity))
	METHOD(Container, removeItem, void(entity, entity))
	METHOD(Container, setFocus, void(entity, entity))
	METHOD(Container, setAlphaOf, void(entity, entity, float))
	METHOD(Container, itemFromPoint, entity(entity, vector))
	METHOD(Container, showNotify, void(entity))
	METHOD(Container, hideNotify, void(entity))
	METHOD(Container, preferredFocusedGrandChild, entity(entity))
	ATTRIB(Container, focusable, float, 0)
	ATTRIB(Container, firstChild, entity, NULL)
	ATTRIB(Container, lastChild, entity, NULL)
	ATTRIB(Container, focusedChild, entity, NULL)
	ATTRIB(Container, shown, float, 0)
ENDCLASS(Container)
.entity nextSibling;
.entity prevSibling;
.float resized;
.vector Container_origin;
.vector Container_size;
.float Container_alpha;
#endif

#ifdef IMPLEMENTATION
void showNotifyContainer(entity me)
{
	entity e;
	if(me.shown)
		return;
	me.shown = 1;
	for(e = me.firstChild; e; e = e.nextSibling)
		if(e.Container_alpha > 0)
			e.showNotify(e);
}

void hideNotifyContainer(entity me)
{
	entity e;
	if not(me.shown)
		return;
	me.shown = 0;
	for(e = me.firstChild; e; e = e.nextSibling)
		if(e.Container_alpha > 0)
			e.hideNotify(e);
}

void setAlphaOfContainer(entity me, entity _other, float theAlpha)
{
	if(theAlpha <= 0)
	{
		if(_other.Container_alpha > 0)
			_other.hideNotify(_other);
	}
	else // value > 0
	{
		if(_other.Container_alpha <= 0)
			_other.showNotify(_other);
	}
	_other.Container_alpha = theAlpha;
}

void resizeNotifyLieContainer(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize, .vector originField, .vector sizeField)
{
	entity e;
	vector o, s;
	float d;
	for(e = me.firstChild; e; e = e.nextSibling)
	{
		o = e.originField;
		s = e.sizeField;
		e.resizeNotify(e, o, s, boxToGlobal(o, absOrigin, absSize), boxToGlobalSize(s, absSize));
	}
	do
	{
		d = 0;
		for(e = me.firstChild; e; e = e.nextSibling)
			if(e.resized)
			{
				e.resized = 0;
				d = 1;
				o = e.originField;
				s = e.sizeField;
				e.resizeNotify(e, o, s, boxToGlobal(o, absOrigin, absSize), boxToGlobalSize(s, absSize));
			}
	}
	while(d);
	resizeNotifyItem(me, relOrigin, relSize, absOrigin, absSize);
}

void resizeNotifyContainer(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.resizeNotifyLie(me, relOrigin, relSize, absOrigin, absSize, Container_origin, Container_size);
}

entity itemFromPointContainer(entity me, vector pos)
{
	entity e;
	vector o, s;
	for(e = me.lastChild; e; e = e.prevSibling)
	{
		o = e.Container_origin;
		s = e.Container_size;
		if(pos_x < o_x) continue;
		if(pos_y < o_y) continue;
		if(pos_x >= o_x + s_x) continue;
		if(pos_y >= o_y + s_y) continue;
		return e;
	}
	return NULL;
}

void drawContainer(entity me)
{
	vector oldshift;
	vector oldscale;
	float oldalpha;
	entity e;

	oldshift = draw_shift;
	oldscale = draw_scale;
	oldalpha = draw_alpha;
	me.focusable = 0;
	for(e = me.firstChild; e; e = e.nextSibling)
	{
		if(e.focusable)
			me.focusable += 1;
		if(e.Container_alpha < 0.003) // can't change color values anyway
			continue;
		draw_shift = boxToGlobal(e.Container_origin, oldshift, oldscale);
		draw_scale = boxToGlobalSize(e.Container_size, oldscale);
		draw_alpha *= e.Container_alpha;
		e.draw(e);
		draw_shift = oldshift;
		draw_scale = oldscale;
		draw_alpha = oldalpha;
	}
};

void focusLeaveContainer(entity me)
{
	me.setFocus(me, NULL);
}

float keyUpContainer(entity me, float scan, float ascii, float shift)
{
	entity f;
	f = me.focusedChild;
	if(f)
		return f.keyUp(f, scan, ascii, shift);
	return 0;
}

float keyDownContainer(entity me, float scan, float ascii, float shift)
{
	entity f;
	f = me.focusedChild;
	if(f)
		return f.keyDown(f, scan, ascii, shift);
	return 0;
}

float mouseMoveContainer(entity me, vector pos)
{
	entity f;
	f = me.focusedChild;
	if(f)
		return f.mouseMove(f, globalToBox(pos, f.Container_origin, f.Container_size));

	return 0;
}
float mousePressContainer(entity me, vector pos)
{
	entity f;
	f = me.focusedChild;
	if(f)
		return f.mousePress(f, globalToBox(pos, f.Container_origin, f.Container_size));
	return 0;
}
float mouseDragContainer(entity me, vector pos)
{
	entity f;
	f = me.focusedChild;
	if(f)
		return f.mouseDrag(f, globalToBox(pos, f.Container_origin, f.Container_size));
	return 0;
}
float mouseReleaseContainer(entity me, vector pos)
{
	entity f;
	f = me.focusedChild;
	if(f)
		return f.mouseRelease(f, globalToBox(pos, f.Container_origin, f.Container_size));
	return 0;
}

void addItemCenteredContainer(entity me, entity _other, vector theSize, float theAlpha)
{
	me.addItem(me, _other, '0.5 0.5 0' - 0.5 * theSize, theSize, theAlpha);
}

void addItemContainer(entity me, entity _other, vector theOrigin, vector theSize, float theAlpha)
{
	if(_other.parent)
		error("Can't add already added item!");

	if(_other.focusable)
		me.focusable += 1;

	if(theSize_x > 1)
	{
		theOrigin_x -= 0.5 * (theSize_x - 1);
		theSize_x = 1;
	}
	if(theSize_y > 1)
	{
		theOrigin_y -= 0.5 * (theSize_y - 1);
		theSize_y = 1;
	}
	theOrigin_x = bound(0, theOrigin_x, 1 - theSize_x);
	theOrigin_y = bound(0, theOrigin_y, 1 - theSize_y);

	_other.parent = me;
	_other.Container_origin = theOrigin;
	_other.Container_size = theSize;
	me.setAlphaOf(me, _other, theAlpha);

	entity f, l;
	f = me.firstChild;
	l = me.lastChild;

	if(l)
		l.nextSibling = _other;
	else
		me.firstChild = _other;

	_other.prevSibling = l;
	_other.nextSibling = NULL;
	me.lastChild = _other;

	draw_NeedResizeNotify = 1;
}

void removeItemContainer(entity me, entity _other)
{
	if(_other.parent != me)
		error("Can't remove from wrong container!");

	if(_other.focusable)
		me.focusable -= 1;

	_other.parent = NULL;

	entity n, p, f, l;
	f = me.firstChild;
	l = me.lastChild;
	n = _other.nextSibling;
	p = _other.prevSibling;

	if(p)
		p.nextSibling = n;
	else
		me.firstChild = n;

	if(n)
		n.prevSibling = p;
	else
		me.lastChild = p;
}

void setFocusContainer(entity me, entity _other)
{
	if(_other)
		if not(me.focused)
			error("Trying to set focus in a non-focused control!");
	if(me.focusedChild == _other)
		return;
	//print(etos(me), ": focus changes from ", etos(me.focusedChild), " to ", etos(_other), "\n");
	if(me.focusedChild)
	{
		me.focusedChild.focused = 0;
		me.focusedChild.focusLeave(me.focusedChild);
	}
	if(_other)
	{
		_other.focused = 1;
		_other.focusEnter(_other);
	}
	me.focusedChild = _other;
}

void moveItemAfterContainer(entity me, entity _other, entity dest)
{
	// first: remove _other from the chain
	entity n, p, f, l;

	if(_other.parent != me)
		error("Can't move in wrong container!");

	f = me.firstChild;
	l = me.lastChild;
	n = _other.nextSibling;
	p = _other.prevSibling;

	if(p)
		p.nextSibling = n;
	else
		me.firstChild = n;

	if(n)
		n.prevSibling = p;
	else
		me.lastChild = p;
	
	// now _other got removed. Insert it behind dest now.
	_other.prevSibling = dest;
	if(dest)
		_other.nextSibling = dest.nextSibling;
	else
		_other.nextSibling = me.firstChild;

	if(dest)
		dest.nextSibling = _other;
	else
		me.firstChild = _other;

	if(_other.nextSibling)
		_other.nextSibling.prevSibling = _other;
	else
		me.lastChild = _other;
}

entity preferredFocusedGrandChildContainer(entity me)
{
	entity e, e2;
	entity best;

	best = NULL;

	for(e = me.firstChild; e; e = e.nextSibling)
	{
		if(e.instanceOfContainer)
		{
			e2 = e.preferredFocusedGrandChild(e);
			if(e2)
				if(!best || best.preferredFocusPriority < e2.preferredFocusPriority)
					best = e2;
		}
		if(e)
			if(!best || best.preferredFocusPriority < e.preferredFocusPriority)
				best = e;
	}

	return best;
}
#endif
