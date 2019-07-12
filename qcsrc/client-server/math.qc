vector(vector a, vector b) math_cross {
	return
		'1 0 0' * (a_y * b_z - a_z * b_y)
	+	'0 1 0' * (a_z * b_x - a_x * b_z)
	+	'0 0 1' * (a_x * b_y - a_y * b_x);
}

float(float a, float b) math_mod {
	return a - (floor(a / b) * b);
}

float(float a, float b) math_almost_equals {
	float eps;
	eps = (max(a, -a) + max(b, -b)) * 0.001;
	if(a - b < eps && b - a < eps)
		return TRUE;

	return FALSE;
}

// requires that m2>m1 in all coordinates, and that m4>m3
float(vector m1, vector m2, vector m3, vector m4) math_boxes_overlap {
	return m2_x >= m3_x && m1_x <= m4_x && m2_y >= m3_y && m1_y <= m4_y && m2_z >= m3_z && m1_z <= m4_z;
}
