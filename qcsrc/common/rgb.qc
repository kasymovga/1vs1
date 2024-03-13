string(vector rgb) rgb_to_hexcolor {
	return strcat(
			"^x",
			DIGIT_DEC_TO_HEX(floor(rgb_x * 15 + 0.5)),
			DIGIT_DEC_TO_HEX(floor(rgb_y * 15 + 0.5)),
			DIGIT_DEC_TO_HEX(floor(rgb_z * 15 + 0.5))
	);
}
