.float light_lev;

/*QUAKED dynlight (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Dynamic spawnfunc_light.
Can do one of these things: sit still and be just a silly spawnfunc_light, travel along a path, follow an entity around, attach to a tag on an entity.
It can spin around it's own axis in all the above cases.
If targeted, it will toggle between on or off.
keys:
"light_lev" spawnfunc_light radius, default 200
"color" spawnfunc_light color in rgb and brightness, 1 1 1 produces bright white, up to 255 255 255 (nuclear blast), recommended values up to 1 1 1, default 1 1 1
"style" lightstyle, same as for static lights
"targetname" will toggle on and off when triggered
"weaponmodel" model
"START_OFF" spawnfunc_light will be in off state until targeted
*/
float dynlight_customize() {
	if (vlen(self.origin - other.origin) > 2000)
		return FALSE;

	return TRUE;
}

void dynlight_on()
{
	self.light_lev = self.dmg;
	if (self.weaponmodel != "")
		setmodel(self.enemy, self.weaponmodel);
}

void dynlight_off()
{
	self.light_lev = 0;
	setmodel(self.enemy, "");
}

void dynlight_use()
{
	if (self.light_lev == 0)
		dynlight_on();
	else
		dynlight_off();
}

void dynlight_reset() {
	if (self.targetname != "")
		dynlight_off();
	else
		dynlight_on();
}

void spawnfunc_dynlight()
{
	if (!self.light_lev)
		self.light_lev = 200;
	if (!self.color)
		self.color = '1 1 1';

	self.pflags = PFLAGS_FULLDYNAMIC;
	self.dmg = self.light_lev;
	self.use = dynlight_use;
	self.customizeentityforclient = dynlight_customize;
	self.effects = EF_NODEPTHTEST;
	if (self.weaponmodel != "") {
		precache_model(self.weaponmodel);
		self.enemy = spawn();
		setattachment(self.enemy, self, "");
	}

	self.solid = SOLID_NOT;
	self.light_lev = 0;
	self.reset = dynlight_reset;
	dynlight_reset();
}
