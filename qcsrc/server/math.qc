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

float(float a) math_safeangle {
    if((a > -361) && (a < 361))
        return a;

    a -= (360 * floor(a / 360));

    return a;
}

float(float ang1,float ang2) math_shortangle_f {
    if(ang1 > ang2) {
        if(ang1 > 180)
            return ang1 - 360;
    } else {
        if(ang1 < -180)
            return ang1 + 360;
    }
    return ang1;
}

vector(vector ang1,vector ang2) math_shortangle_vxy {
    vector vtmp;
    vtmp_x = math_shortangle_f(ang1_x,ang2_x);
    vtmp_y = math_shortangle_f(ang1_y,ang2_y);
    vtmp_z = 0;
    return vtmp;
}
