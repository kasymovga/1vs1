void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_borderimage_resize;
void(entity me, string theTitle, float sz, vector theColor, string path, float theBorderHeight) gui_borderimage_configure;
void(entity me) gui_borderimage_draw;

entity(void) gui_borderimage_spawn {
	entity me; me = gui_label_spawn();
	me.configureBorderImage = gui_borderimage_configure;
	me.resizeNotify = gui_borderimage_resize;
	me.draw = gui_borderimage_draw;
	me.src = NULL;
	me.borderHeight = 0;
	me.borderVec = '0 0 0';
	me.color = '1 1 1';
	me.closeButton = NULL;
	me.realFontSize_Nexposeed = '0 0 0';
	me.realOrigin_Nexposeed = '0 0 0';
	me.isNexposeeTitleBar = 0;
	me.zoomedOutTitleBarPosition = 0;
	me.zoomedOutTitleBar = 0;
	me.borderLines = 1;
	me.classname = "BorderImage";
	return me;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_borderimage_resize {
	me.isNexposeeTitleBar = 0;
	if (me.zoomedOutTitleBar)
		if (me.parent.parent.instanceOfNexposee)
			if (me.parent.instanceOfDialog)
				if (me == me.parent.frame)
					me.isNexposeeTitleBar = 1;

	if (me.isNexposeeTitleBar) {
		vector scrs;
		scrs = eX * gui_conwidth + eY * gui_conheight;
		gui_label_resize(me, relOrigin, relSize, gui_box_to_global(me.parent.Nexposee_smallOrigin, '0 0 0', scrs), gui_box_to_global_size(me.parent.Nexposee_smallSize, scrs));
		me.realOrigin_y = me.realFontSize_y * me.zoomedOutTitleBarPosition;
		me.realOrigin_Nexposeed = me.realOrigin;
		me.realFontSize_Nexposeed = me.realFontSize;
	}
	gui_label_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.borderVec = me.borderHeight / absSize_y * (eY + eX * (absSize_y / absSize_x));
	me.realOrigin_y = 0.5 * (me.borderVec_y - me.realFontSize_y);
	if (me.closeButton) {
		// move the close button to the right place
		me.closeButton.Container_origin = '1 0 0' * (1 - me.borderVec_x);
		me.closeButton.Container_size = me.borderVec;
		me.closeButton.color = me.color;
		me.closeButton.colorC = me.color;
		me.closeButton.colorF = me.color;
	}
}

void(entity me, string theTitle, float sz, vector theColor, string path, float theBorderHeight) gui_borderimage_configure {
	me.configureLabel(me, theTitle, sz, 0.5);
	me.src = path;
	me.color = theColor;
	me.borderHeight = theBorderHeight;
}

void(entity me) gui_borderimage_draw {
	//print(vtos(me.borderVec), "\n");
	if (me.src)
		gui_draw_picture_border('0 0 0', me.src, '1 1 0', me.color, 1, me.borderLines * me.borderVec);

	if (me.fontSize > 0) {
		vector ro = '0 0 0', rf = '0 0 0';
		if (me.isNexposeeTitleBar) {
			// me.parent.Nexposee_animationFactor 0 (small) or 1 (full)
			// default values are for 1
			ro = me.realOrigin;
			rf = me.realFontSize;
			me.realOrigin = ro * me.parent.Nexposee_animationFactor + me.realOrigin_Nexposeed * (1 - me.parent.Nexposee_animationFactor);
			me.realFontSize = rf * me.parent.Nexposee_animationFactor + me.realFontSize_Nexposeed * (1 - me.parent.Nexposee_animationFactor);
		}
		gui_label_draw(me);
		if (me.isNexposeeTitleBar) {
			// me.Nexposee_animationState 0 (small) or 1 (full)
			// default values are for 1
			me.realOrigin = ro;
			me.realFontSize = rf;
		}
	}
}
