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
void dynlight_use()
{
	if (self.light_lev == 0) {
		self.light_lev = self.dmg;
		setmodel(self, self.weaponmodel);
	} else {
		self.light_lev = 0;
		setmodel(self, "");
	}
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
	if (self.weaponmodel != "")
		precache_model(self.weaponmodel);

	self.solid = SOLID_NOT;
	self.light_lev = 0;
	if not(self.spawnflags & 1)
	if not(self.targetname != "")
		dynlight_use();
}
