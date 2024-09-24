shader_type canvas_item;

// We need to send in a value of 0-1

uniform vec3 end_color:source_color;
uniform float flash_speed = 1.0;

float anim() {
	return (sin(TIME * flash_speed) + 1.0) / 2.0;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (flash_speed != 0.0 && COLOR.rgb == vec3(1,1,1)){
		COLOR.rgb = mix(vec3(1,1,1), end_color, anim());
	}
	
}
