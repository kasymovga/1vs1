// unzone the string, and return it as tempstring. Safe to be called on string_null
string fstrunzone(string s)
{
	string sc;
	if not(s)
		return s;
	sc = strcat(s, "");
	strunzone(s);
	return sc;
}

string fixPriorityList(string order, float from, float to, float subtract, float complete)
{
	string neworder;
	float i, n, w;

	n = tokenize_console(order);
	for(i = 0; i < n; ++i)
	{
		w = stof(argv(i));
		if(w == floor(w))
		{
			if(w >= from && w <= to)
				neworder = strcat(neworder, ftos(w), " ");
			else
			{
				w -= subtract;
				if(w >= from && w <= to)
					neworder = strcat(neworder, ftos(w), " ");
			}
		}
	}

	if(complete)
	{
		n = tokenize_console(neworder);
		for(w = to; w >= from; --w)
		{
			for(i = 0; i < n; ++i)
				if(stof(argv(i)) == w)
					break;
			if(i == n) // not found
				neworder = strcat(neworder, ftos(w), " ");
		}
	}

	return substring(neworder, 0, strlen(neworder) - 1);
}

string swapInPriorityList(string order, float i, float j)
{
	string s;
	float w, n;

	n = tokenize_console(order);

	if(i >= 0 && i < n && j >= 0 && j < n && i != j)
	{
		s = "";
		for(w = 0; w < n; ++w)
		{
			if(w == i)
				s = strcat(s, argv(j), " ");
			else if(w == j)
				s = strcat(s, argv(i), " ");
			else
				s = strcat(s, argv(w), " ");
		}
		return substring(s, 0, strlen(s) - 1);
	}

	return order;
}

float cvar_value_issafe(string s)
{
	if(strstrofs(s, "\"", 0) >= 0)
		return 0;
	if(strstrofs(s, "\\", 0) >= 0)
		return 0;
	if(strstrofs(s, ";", 0) >= 0)
		return 0;
	if(strstrofs(s, "$", 0) >= 0)
		return 0;
	if(strstrofs(s, "\r", 0) >= 0)
		return 0;
	if(strstrofs(s, "\n", 0) >= 0)
		return 0;
	return 1;
}

void cvar_settemp(string pKey, string pValue)
{
	if(cvar_string(pKey) == pValue)
		return;
	cvar_set("settemp_list", strcat("1 ", pKey, " ", cvar_string("settemp_var"), " ", cvar_string("settemp_list")));
#ifdef MENUQC
	registercvar(cvar_string("settemp_var"), "", 0);
	registercvar(pKey, "", 0);
#else
	registercvar(cvar_string("settemp_var"), "");
	registercvar(pKey, "");
#endif
	cvar_set(cvar_string("settemp_var"), cvar_string(pKey));
	cvar_set("settemp_var", strcat(cvar_string("settemp_var"), "x"));
	cvar_set(pKey, pValue);
}

void cvar_settemp_restore()
{
	// undo what cvar_settemp did
	float n, i;
	n = tokenize_console(cvar_string("settemp_list"));
	for(i = 0; i < n - 3; i += 3)
		cvar_set(argv(i + 1), cvar_string(argv(i + 2)));
	cvar_set("settemp_list", "0");
}

void shuffle(float n, swapfunc_t swap, entity pass)
{
	float i, j;
	for(i = 1; i < n; ++i)
	{
		// swap i-th item at a random position from 0 to i
		// proof for even distribution:
		//   n = 1: obvious
		//   n -> n+1:
		//     item n+1 gets at any position with chance 1/(n+1)
		//     all others will get their 1/n chance reduced by factor n/(n+1)
		//     to be on place n+1, their chance will be 1/(n+1)
		//     1/n * n/(n+1) = 1/(n+1)
		//     q.e.d.
		j = floor(random() * (i + 1));
		if(j != i)
			swap(j, i, pass);
	}
}

string substring_range(string s, float b, float e)
{
	return substring(s, b, e - b);
}

string swapwords(string str, float i, float j)
{
	float n;
	string s1, s2, s3, s4, s5;
	float si, ei, sj, ej, s0, en;
	n = tokenizebyseparator(str, " "); // must match g_maplist processing in ShuffleMaplist and "shuffle"
	si = argv_start_index(i);
	sj = argv_start_index(j);
	ei = argv_end_index(i);
	ej = argv_end_index(j);
	s0 = argv_start_index(0);
	en = argv_end_index(n-1);
	s1 = substring_range(str, s0, si);
	s2 = substring_range(str, si, ei);
	s3 = substring_range(str, ei, sj);
	s4 = substring_range(str, sj, ej);
	s5 = substring_range(str, ej, en);
	return strcat(s1, s4, s3, s2, s5);
}

string _shufflewords_str;
void _shufflewords_swapfunc(float i, float j, entity pass)
{
	_shufflewords_str = swapwords(_shufflewords_str, i, j);
}
string shufflewords(string str)
{
	float n;
	_shufflewords_str = str;
	n = tokenizebyseparator(str, " ");
	shuffle(n, _shufflewords_swapfunc, world);
	str = _shufflewords_str;
	_shufflewords_str = string_null;
	return str;
}

void heapsort(float n, swapfunc_t swap, comparefunc_t cmp, entity pass)
{
	float start, end, root, child;

	// heapify
	start = floor((n - 2) / 2);
	while(start >= 0)
	{
		// siftdown(start, count-1);
		root = start;
		while(root * 2 + 1 <= n-1)
		{
			child = root * 2 + 1;
			if(child < n-1)
				if(cmp(child, child+1, pass) < 0)
					++child;
			if(cmp(root, child, pass) < 0)
			{
				swap(root, child, pass);
				root = child;
			}
			else
				break;
		}
		// end of siftdown
		--start;
	}

	// extract
	end = n - 1;
	while(end > 0)
	{
		swap(0, end, pass);
		--end;
		// siftdown(0, end);
		root = 0;
		while(root * 2 + 1 <= end)
		{
			child = root * 2 + 1;
			if(child < end && cmp(child, child+1, pass) < 0)
				++child;
			if(cmp(root, child, pass) < 0)
			{
				swap(root, child, pass);
				root = child;
			}
			else
				break;
		}
		// end of siftdown
	}
}
