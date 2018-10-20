#define ANTILAG_MAX_ORIGINS 16
.vector antilag_origins[ANTILAG_MAX_ORIGINS];
var float antilag_times[ANTILAG_MAX_ORIGINS];
float antilag_index;
.vector antilag_saved_origin;
.entity antilag_chain;

entity _antilag_chain;
float antilag_context_index;

void antilag_record(float t) {
	if (t - antilag_times[antilag_index] < 0.03)
		return;

	antilag_index = antilag_index + 1;
	if(antilag_index >= ANTILAG_MAX_ORIGINS)
		antilag_index = 0;

	entity e;
	antilag_times[antilag_index] = t;
	FOR_EACH_PLAYER(e)
		e.(antilag_origins[antilag_index]) = e.origin;

	for (e = _antilag_chain; e; e = e.antilag_chain)
		e.(antilag_origins[antilag_index]) = e.origin;
}

void antilag_teleported(entity e) {
	float i;
	for (i = 0; i < ANTILAG_MAX_ORIGINS; i++)
		e.(antilag_origins[i]) = e.origin;
}

// finds the index BEFORE t
float antilag_find(entity e, float t)
{
	float i;

	for(i = antilag_index; i > 0; --i) {
		if((antilag_times[i]) >= t)
			if((antilag_times[i - 1]) < t)
				return i - 1;
	}

	if((antilag_times[0]) >= t)
		if((antilag_times[ANTILAG_MAX_ORIGINS - 1]) < t)
			return ANTILAG_MAX_ORIGINS - 1;

	for(i = ANTILAG_MAX_ORIGINS - 1; i > antilag_index + 1; --i)
		if((antilag_times[i]) >= t)
			if((antilag_times[i - 1]) < t)
				return i - 1;

	// if we get here, t is sandwiched nowhere, so let's assume it's in the present
	return -1;
}

vector lerp(float t0, vector v0, float t1, vector v1, float t)
{
	return v0 + (v1 - v0) * ((t - t0) / (t1 - t0));
}

vector antilag_takebackorigin(entity e, float t)
{
	float i0, i1;

	i0 = antilag_context_index;
	if(i0 < 0)
	{
		i0 = antilag_index - 1;
		if(i0 < 0)
			i0 = ANTILAG_MAX_ORIGINS - 1;
	}
	i1 = i0 + 1;
	if(i1 >= ANTILAG_MAX_ORIGINS)
		i1 = 0;

	return lerp((antilag_times[i0]), e.(antilag_origins[i0]), (antilag_times[i1]), e.(antilag_origins[i1]), t);
}

void antilag_takeback(entity e, float t)
{
	e.antilag_saved_origin = e.origin;
	setorigin(e, antilag_takebackorigin(e, t));
}

void antilag_restore(entity e)
{
	setorigin(e, e.antilag_saved_origin);
}

float antilag_oldhitmask;
float antilag_lag;
entity antilag_source;
void antilag_begin(entity source) {
	if (clienttype(source) != CLIENTTYPE_REAL)
		antilag_lag = 0; // only antilag for clients
	else
		antilag_lag = ANTILAG_LATENCY(source);

	float past = time - antilag_lag;
	antilag_context_index = antilag_find(source, past);
	// change shooter to SOLID_BBOX so the shot can hit corpses
	antilag_source = source;
	if(source)
	{
		antilag_oldhitmask = source.dphitcontentsmask;
		source.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	}
	if (antilag_lag)
	{
		// take players back into the past
		entity e;
		FOR_EACH_PLAYER(e)
			if (e != source) {
				antilag_takeback(e, past);
			}

		for (e = _antilag_chain; e; e = e.antilag_chain)
			antilag_takeback(e, past);
	}
}

void antilag_end() {
	// restore players to current positions
	if (antilag_lag)
	{
		entity e;
		FOR_EACH_PLAYER(e)
			if (e != antilag_source)
				antilag_restore(e);

		for (e = _antilag_chain; e; e = e.antilag_chain)
			antilag_restore(e);
	}
	// restore shooter solid type
	if(antilag_source)
		antilag_source.dphitcontentsmask = antilag_oldhitmask;
}

void antilag_remove(entity e) {
	if (_antilag_chain == e) {
		_antilag_chain = e.antilag_chain;
	}
	entity e0;
	for (e0 = _antilag_chain; e0.antilag_chain; e0 = e0.antilag_chain)
		if (e0.antilag_chain == e) {
			e0.antilag_chain = e.antilag_chain;
			return;
		}
}

void antilag_add(entity e) {
	e.antilag_chain = _antilag_chain;
	_antilag_chain = e;
	antilag_teleported(e);
}
