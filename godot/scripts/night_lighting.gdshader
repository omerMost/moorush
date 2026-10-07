shader_type canvas_item;
render_mode unshaded;
uniform int light_count = 0;
uniform vec4 lights[24]; // world x/y, radius, center strength
varying vec2 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	float coverage = 1.0;
	for (int i = 0; i < light_count; i++) {
		float hole = max(0.0, 1.0 - distance(world_position, lights[i].xy) / lights[i].z) * lights[i].w;
		coverage *= 1.0 - hole;
	}
	COLOR.a *= coverage;
}
