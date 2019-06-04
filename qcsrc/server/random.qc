entity randomseed;
vector(float side, float up, float up_min, float up_min_rand) random_spread_vector {
    vector v;
	v_x = random_2() * 2 * side;
	v_y = random_2() * 2 * side;
	v_z = max(up * random(), up_min + up_min_rand * random_2() * 2);
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
	net_link_entity(randomseed, FALSE, 0, RandomSeed_Send);

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

vector(vector m1, vector m2) random_pos {
    local vector v;
    m2 = m2 - m1;
    v_x = m2_x * random() + m1_x;
    v_y = m2_y * random() + m1_y;
    v_z = m2_z * random() + m1_z;
    return  v;
}

float(void) random_2 {
	return random() * 2 - 1;
}

entity random_queue;
entity random_queue_iterator;
float random_queue_depth;
void(void) random_queue_end {
	entity e;
	for (e = random_queue; e; e = e.owner) {
		e.think = stdproc_remove;
		e.nextthink = time;
	}
	random_queue = world;
	random_queue_iterator = world;
	random_queue_depth = 0;
}

void(void) random_queue_start {
	random_queue_end();
}

void(entity e, float f, string s) random_queue_push {
	entity before, after;
	after = world;
	before = random_queue;
	random_queue_depth++;
	float n = floor(random_queue_depth * random());
	float i;
	for (i = 0; i < n; i++) {
		after = before;
		before = before.owner;
	}
	entity insert = spawn();
	insert.owner = before;
	insert.enemy = e;
	insert.health = f;
	insert.message = s;
	if (after) {
		after.owner = insert;
	} else {
		random_queue = insert;
	}
}

float(void) random_queue_next {
	if (random_queue_iterator)
		random_queue_iterator = random_queue_iterator.owner;
	else
		random_queue_iterator = random_queue;

	return (random_queue_iterator != world);
}

float(void) random_queue_next_circle {
	if not(random_queue_next())
		return random_queue_next();

	return TRUE;
}

entity(void) random_queue_ent {
	return random_queue_iterator.enemy;
}

float(void) random_queue_float {
	return random_queue_iterator.health;
}
