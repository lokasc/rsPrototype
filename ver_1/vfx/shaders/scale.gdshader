shader_type canvas_item;


uniform float size;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX *= vec2(size, size);
}

void fragment() {
	// Called for every pixel the material is visible on.
}
