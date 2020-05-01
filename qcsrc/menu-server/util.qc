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
