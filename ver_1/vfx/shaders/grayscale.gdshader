shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = texture(TEXTURE, UV);
	float avg = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
    COLOR.rgb = vec3(avg);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
