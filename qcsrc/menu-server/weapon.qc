string(string order, float from, float to, float subtract, float complete) weapon_fix_priority_list {
	string neworder = "";
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

string(string order, float complete) weapon_fix_order {
	return weapon_fix_priority_list(order, WEP_FIRST, WEP_LAST, 230 - WEP_FIRST, complete);
}
