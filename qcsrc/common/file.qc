float(string path) file_exists {
	float f = fopen(path, FILE_READ);
	if (f < 0)
		return FALSE;

	fclose(f);
	return TRUE;
}

float(string path) file_exists_image {
	if not(file_exists(strcat(path, ".jpg")))
	if not(file_exists(strcat(path, ".tga")))
	if not(file_exists(strcat(path, ".png"))) {
		return FALSE;
	}
	return TRUE;
}
