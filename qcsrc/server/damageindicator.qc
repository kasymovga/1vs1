float sv_damageindicator_accumulate_interval;

float DamageIndicator_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_DMG_INDICATOR);
	float damage = self.dmg + 0.4;
	if (self.dmg < 251)
		WriteByte(MSG_ENTITY, bound(0, damage, 255));
	else if (self.dmg < 500)
		WriteByte(MSG_ENTITY, 251);
	else if (self.dmg < 1000)
		WriteByte(MSG_ENTITY, 252);
	else if (self.dmg < 2000)
		WriteByte(MSG_ENTITY, 253);
	else if (self.dmg < 5000)
		WriteByte(MSG_ENTITY, 254);
	else
		WriteByte(MSG_ENTITY, 255);

	WriteShort(MSG_ENTITY, self.origin_x);
	WriteShort(MSG_ENTITY, self.origin_y);
	WriteShort(MSG_ENTITY, self.origin_z);
	return TRUE;
}

void DamageIndicator_Remove() {
	entity e;
	for (e = self.owner; e; e = e.dmg_indicator)
		if (e.dmg_indicator == self) {
			e.dmg_indicator = self.dmg_indicator;
			break;
		}
	remove(self);
}

float DamageIndicator_Customize() {
	if (self.enemy == other)
		return TRUE;

	if (other.classname == "spectator")
		if (other.enemy == self.enemy)
			return TRUE;

	return FALSE;
}

var void(entity targ, entity attacker, float damage, vector ignore) DamageIndicator_DamageForceDone_NextLink;
void DamageIndicator_DamageForceDone(entity targ, entity attacker, float damage, vector ignore) {
	DamageIndicator_DamageForceDone_NextLink(targ, attacker, damage, ignore);
	if (targ == attacker)
		return;

	if not(targ.modelindex)
		return;

	if (targ.flags & FL_PROJECTILE)
		return;

	entity e;
	for (e = targ.dmg_indicator; e ;e = e.dmg_indicator) {
		if (e.enemy == attacker)
			break;
	}
	if not(e) {
		e = spawn();
		e.dmg_indicator = targ.dmg_indicator;
		e.think = DamageIndicator_Remove;
		e.owner = targ;
		e.enemy = attacker;
		e.customizeentityforclient = DamageIndicator_Customize;
		Net_LinkEntity(e, FALSE, 0, DamageIndicator_SendEntity);
		targ.dmg_indicator = e;
	}
	setorigin(e, targ.origin + 0.5 * (targ.maxs + targ.mins));
	e.SendFlags = 1;
	e.dmg = e.dmg + damage;
	e.nextthink = time + sv_damageindicator_accumulate_interval;
}

void DamageIndicator_Init() {
	if not(cvar("sv_damageindicator"))
		return;
	
	CACHE_CVAR(sv_damageindicator_accumulate_interval);
	DamageIndicator_DamageForceDone_NextLink = GameHookChain_DamageForceDone;
	GameHookChain_DamageForceDone = DamageIndicator_DamageForceDone;
}
