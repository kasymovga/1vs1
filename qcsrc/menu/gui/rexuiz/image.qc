void(entity me, string theImage, float theAspect) gui_rexuiz_image_configue;

entity(void) gui_rexuiz_image_spawn {
	entity me; me = gui_image_spawn();
	me.configureNexuizImage = gui_rexuiz_image_configue;
	me.classname = "NexuizImage";
	return me;
}

entity(string theImage, float theAspect) gui_rexuiz_image_make {
	entity me;
	me = gui_rexuiz_image_spawn();
	me.configureNexuizImage(me, theImage, theAspect);
	return me;
}

void(entity me, string theImage, float theAspect) gui_rexuiz_image_configue {
	me.configureImage(me, theImage);
	if (theAspect < 0) { // use image aspect
		vector sz;
		sz = gui_picture_size(theImage);
		me.forcedAspect = sz_x / sz_y;
	} else
		me.forcedAspect = theAspect;
}
