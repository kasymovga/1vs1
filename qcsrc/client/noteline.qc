entity noteline;

void NoteLine_Draw();

void NoteLine_Remove() {
	entity e;
	if (noteline == self) {
		noteline = noteline.entchain;
		if (noteline) {
			noteline.draw2dflag = 1;
			noteline.draw2d = NoteLine_Draw;
		}
	} else
		for (e = noteline; e.entchain; e = e.entchain) {
			if (e.entchain == self) {
				e.entchain = self.entchain;
				break;
			}
		}
	strunzone(self.message);
}

vector NoteLine_Pos;
void NoteLine_DrawLine(string s)
{
	drawcolorcodedstring(
		NoteLine_Pos - sbar_fontsize_x * '1 0 0' * (stringwidth(s, TRUE) + 1),
		s,
		sbar_fontsize,
		sbar_alpha_fg,
		0
	);
	NoteLine_Pos_y += sbar_fontsize_y;
}

void NoteLine_Draw() {
	NoteLine_Pos_x = CVAR(vid_conwidth);
	NoteLine_Pos_y = 28;
	entity e;
	string head, tail;
	float n;
	for (e = noteline; e; e = e.entchain) {
		NoteLine_Pos_y += sbar_fontsize_y * 0.5;
		tail = e.message;
		for (;;) {
			n = strstrofs(tail, "\n", 0);
			if (n < 0) {
				NoteLine_DrawLine(tail);
				break;
			}
			head = substring(tail, 0, n + 1);
			tail = substring(tail, n + 1, -1);
			NoteLine_DrawLine(head);
		}
	}
}

string NoteLine_PrepareLine(string s) {
	float cmdkey, cmdkey_end;
	while ((cmdkey = strstrofs(s, "{", 0)) > 0) {
		cmdkey_end = strstrofs(s, "}", cmdkey);
		if (cmdkey_end < 0)
			break;

		string s1, s2, s3;
		s1 = substring(s, 0, cmdkey);
		s2 = substring(s, cmdkey + 1, cmdkey_end - cmdkey - 1);
		if (s2 == "")
			s2 = "{";
		else
			s2 = getcommandkey(s2, s2);

		s3 = substring(s, cmdkey_end + 1, -1);
		s = strcat(s1, s2, s3);
	}
	return s;
}

void Ent_NoteLine(float bIsNew) {
	self.entremove = NoteLine_Remove;
	if (self.message)
		strunzone(self.message);

	self.message = strzone(NoteLine_PrepareLine(ReadString()));
	entity e;
	for (e = noteline; e; e = e.entchain) {
		if (e == self)
			goto skip;
	}
	if (noteline) {
		self.entchain = noteline;
		noteline.draw2dflag = 0;
		noteline.draw2d = world.draw2d;
	}
	noteline = self;
	noteline.draw2dflag = 1;
	noteline.draw2d = NoteLine_Draw;
:skip
	return;
}
