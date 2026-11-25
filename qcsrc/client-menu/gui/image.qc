string(entity me) gui_image_to_string;
void(entity me, string path) gui_image_configure;

entity(void) gui_image_spawn {
	entity me; me = gui_item_spawn();
	me.configureImage = gui_image_configure;
	me.draw = gui_image_draw;
	me.toString = gui_image_to_string;
	me.resizeNotify = gui_image_resize;
	me.src = NULL;
	me.color = '1 1 1';
	me.forcedAspect = 0;
	me.imgOrigin = '0 0 0';
	me.imgSize = '0 0 0';
	me.classname = "Image";
	return me;
}

string(entity me) gui_image_to_string {
	return me.src;
}

void(entity me, string path) gui_image_configure {
	me.src = path;
}

void(entity me) gui_image_draw {
	gui_draw_picture(me.imgOrigin, me.src, me.imgSize, me.color, 1);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_image_resize {
	gui_item_resize(me, relOrigin, relSize, absOrigin, absSize);
	if (me.forcedAspect == 0) {
		me.imgOrigin = '0 0 0';
		me.imgSize = '1 1 0';
	} else {
		if (absSize_x > me.forcedAspect * absSize_y) {
			// x too large, so center x-wise
			me.imgSize = eY + eX * (absSize_y * me.forcedAspect / absSize_x);
		} else {
			// y too large, so center y-wise
			me.imgSize = eX + eY * (absSize_x / (me.forcedAspect * absSize_y));
		}
		me.imgOrigin = '0.5 0.5 0' - 0.5 * me.imgSize;
	}
}
