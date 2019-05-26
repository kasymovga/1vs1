// ax^2 + bx + c = 0
vector(float a, float b, float c) math_solve_quadratic {
	vector v;
	float D;
	v = '0 0 0';
	if(a == 0)
	{
		if(b != 0)
		{
			v_x = v_y = -c / b;
			v_z = 1;
		}
		else
		{
			if(c == 0)
			{
				// actually, every number solves the equation!
				v_z = 1;
			}
		}
	}
	else
	{
		D = b*b - 4*a*c;
		if(D >= 0)
		{
			D = sqrt(D);
			if(a > 0) // put the smaller solution first
			{
				v_x = ((-b)-D) / (2*a);
				v_y = ((-b)+D) / (2*a);
			}
			else
			{
				v_x = (-b+D) / (2*a);
				v_y = (-b-D) / (2*a);
			}
			v_z = 1;
		}
		else
		{
			// complex solutions!
			D = sqrt(-D);
			v_x = -b / (2*a);
			if(a > 0)
				v_y =  D / (2*a);
			else
				v_y = -D / (2*a);
			v_z = 0;
		}
	}
	return v;
}
