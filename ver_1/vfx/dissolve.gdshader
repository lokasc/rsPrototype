shader_type canvas_item;

uniform sampler2D dissolve_texture;
uniform float dissolve_value : hint_range(0,1);

void fragment(){
    vec4 main_texture = texture(TEXTURE, UV);
    vec4 noise_texture = texture(dissolve_texture, UV);
    main_texture.a *= floor(dissolve_value + min(1, noise_texture.x));
    COLOR = main_texture;
}

//shader_type canvas_item;
//
//uniform vec3 edge_color;
//uniform float threshold;
//uniform float edge_offset;
//uniform sampler2D noise : source_color;
//
//void fragment() {
	//// Called for every pixel the material is visible on.
	//
	//float noise_color = texture(noise, UV).x;
	//vec4 sprite = texture(TEXTURE,UV);
	//
	//// Alpha clipping
	//if (noise_color >= threshold)
	//{
		//COLOR.a = 1.0;
	//}
	//else
	//{
		//COLOR.a = 0.0;
	//}
	//
	//// edge glow:
	//float tmp = threshold + edge_offset;
	//
	//COLOR.r = step(noise_color, tmp);
	//COLOR.g = step(noise_color, tmp);// * edge_color.y;
	//COLOR.b = step(noise_color, tmp);// * edge_color.z;
	//
	//COLOR.rgb *= edge_color;
	//COLOR.rgb += sprite.rgb;
//}
//
////void light() {
	//// Called for every pixel for every light affecting the CanvasItem.
	//// Uncomment to replace the default light processing function with this one.
////}
