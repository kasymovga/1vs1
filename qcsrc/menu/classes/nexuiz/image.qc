entity spawnNexuizImage() {
	entity me; me = spawnImage();
	me.configureNexuizImage = configureNexuizImageNexuizImage;
	me.classname = "NexuizImage";
	return me;
}
entity makeNexuizImage(string theImage, float theAspect);
entity makeNexuizImage(string theImage, float theAspect)
{
	entity me;
	me = spawnNexuizImage();
	me.configureNexuizImage(me, theImage, theAspect);
	return me;
}
void configureNexuizImageNexuizImage(entity me, string theImage, float theAspect)
{
	me.configureImage(me, theImage);
	if(theAspect < 0) // use image aspect
	{
		vector sz;
		sz = gui_picture_size(theImage);
		me.forcedAspect = sz_x / sz_y;
	}
	else
		me.forcedAspect = theAspect;
}
