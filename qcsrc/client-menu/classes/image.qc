entity spawnImage() {
	entity me; me = spawnItem();
	me.configureImage = configureImageImage;
	me.draw = drawImage;
	me.toString = toStringImage;
	me.resizeNotify = resizeNotifyImage;
	me.src = NULL;
	me.color = '1 1 1';
	me.forcedAspect = 0;
	me.imgOrigin = '0 0 0';
	me.imgSize = '0 0 0';
	me.classname = "Image";
	return me;
}
string toStringImage(entity me)
{
	return me.src;
}
void configureImageImage(entity me, string path)
{
	me.src = path;
}
void drawImage(entity me)
{
	gui_draw_picture(me.imgOrigin, me.src, me.imgSize, me.color, 1);
}
void resizeNotifyImage(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyItem(me, relOrigin, relSize, absOrigin, absSize);
	if(me.forcedAspect == 0)
	{
		me.imgOrigin = '0 0 0';
		me.imgSize = '1 1 0';
	}
	else
	{
		if(absSize_x > me.forcedAspect * absSize_y)
		{
			// x too large, so center x-wise
			me.imgSize = eY + eX * (absSize_y * me.forcedAspect / absSize_x);
		}
		else
		{
			// y too large, so center y-wise
			me.imgSize = eX + eY * (absSize_x / (me.forcedAspect * absSize_y));
		}
		me.imgOrigin = '0.5 0.5 0' - 0.5 * me.imgSize;
	}
}
