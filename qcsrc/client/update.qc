void(void) update_message_draw {
	string msg;
	vector pos;
	pos_z = 0;
	float _alpha = 0.5 + math_mod(time, 2) * 0.5;
	msg = "^1WARNING: ^3Your client is not recommended!";
	pos_y = 10;
	pos_x = 10;
	drawcolorcodedstring(pos, msg, '18 36 0', _alpha, DRAWFLAG_NORMAL);
	pos_y += 32;
	drawcolorcodedstring(pos, self.bgmscript, '18 36 0', _alpha, DRAWFLAG_NORMAL);
	msg = "^3Please download and install Rexuiz from ^2http://rexuiz.com^7";
	pos_y += 32;
	drawcolorcodedstring(pos, msg, '18 36 0', _alpha, DRAWFLAG_NORMAL);
}

void(string msg, float timeout) update_message {
	entity e = spawn();
	e.draw2d = update_message_draw;
	e.draw2dflag = 1;
	e.nextthink = time + timeout;
	e.think = stdproc_remove;
	e.bgmscript = msg;
}
