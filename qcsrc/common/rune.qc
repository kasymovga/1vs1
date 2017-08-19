string RuneName(float r)
{
	if(r == RUNE_IGNITE)
		return "^1Ignite^7";
	if(r == RUNE_DEFENSE)
		return "^4Defense^7";
	if(r == RUNE_REGEN)
		return "^2Vitality^7";
	if(r == RUNE_SPEED)
		return "^3Speed^7";
	if(r == RUNE_VAMPIRE)
		return "^6Vampire^7";

	if(r == CURSE_BURNING)
		return "^1Burning^7";
	if(r == CURSE_VULNER)
		return "^4Vulnerability^7";
	if(r == CURSE_VENOM)
		return "^2Venom^7";
	if(r == CURSE_SLOW)
		return "^3Slow^7";
	if(r == CURSE_ALTRUISM)
		return "^6Altruism^7";
	return strcat("^8[unnamed", ftos(r), "]^7");
}
