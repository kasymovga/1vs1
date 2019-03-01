entity randomseed;
vector(float side, float up, float up_min, float up_min_rand) random_spread_vector {
    vector v;
	v_x = crandom() * 2 * side;
	v_y = crandom() * 2 * side;
	v_z = max(up * random(), up_min + up_min_rand * crandom() * 2);
	return v;
}

#define random_seed_send RandomSeed_Send
float(entity to, float sf) random_seed_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_RANDOMSEED);
	WriteShort(MSG_ENTITY, self.cnt);
	return TRUE;
}

#define random_seed_think RandomSeed_Think
void() random_seed_think {
	self.cnt = bound(0, floor(random() * 65536), 65535);
	self.nextthink = time + 5;
	self.SendFlags |= 1;
}

void() random_seed_spawn {
	randomseed = spawn();
	randomseed.think = RandomSeed_Think;
	Net_LinkEntity(randomseed, FALSE, 0, RandomSeed_Send);

	entity oldself;
	oldself = self;
	self = randomseed;
	self.think(); // sets random seed and nextthink
	self = oldself;
}

void() random_selection_init {
	random_selection_totalweight = 0;
	random_selection_chosen_ent = world;
	random_selection_chosen_float = 0;
	random_selection_chosen_string = string_null;
	random_selection_best_priority = -1;
}

void(entity e, float f, string s, float weight, float priority) random_selection_add {
	if(priority > random_selection_best_priority)
	{
		random_selection_best_priority = priority;
		random_selection_chosen_ent = e;
		random_selection_chosen_float = f;
		random_selection_chosen_string = s;
		random_selection_totalweight = weight;
	}
	else if(priority == random_selection_best_priority)
	{
		random_selection_totalweight += weight;
		if(random() * random_selection_totalweight <= weight)
		{
			random_selection_chosen_ent = e;
			random_selection_chosen_float = f;
			random_selection_chosen_string = s;
		}
	}
}
