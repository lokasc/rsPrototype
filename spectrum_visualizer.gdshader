shader_type canvas_item;
render_mode unshaded;
global uniform sampler2D spectrum_analyzer;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR.rgb = texture(spectrum_analyzer,UV).rgb;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
