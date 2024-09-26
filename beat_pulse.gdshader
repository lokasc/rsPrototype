shader_type canvas_item;

render_mode unshaded;

uniform sampler2D albedo : source_color;
uniform float spectrum_position;
global uniform sampler2D spectrum_analyzer;

varying float spectrum_value;

void vertex() {
	// Called for every vertex the material is visible on.
	spectrum_value = texture(spectrum_analyzer, vec2(spectrum_position, 0)).r;
	VERTEX *= 1.0 + spectrum_value;
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR.rgb = texture(albedo, UV).rgb;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
