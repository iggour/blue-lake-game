shader_type canvas_item;

// Blue Lake spreads out from Graham like water, with a chalky, broken edge.
uniform vec2 center = vec2(590.0, 580.0);
uniform float radius = 0.0;
uniform float feather = 70.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float n = hash(floor(world_pos / 3.0)) * feather * 0.7;
	float d = distance(world_pos, center) + n;
	float a = 1.0 - smoothstep(radius - feather, radius, d);
	float edge = (1.0 - smoothstep(0.0, feather * 0.5, abs(d - radius + feather * 0.3))) * step(1.0, radius) * step(radius, 1500.0);
	COLOR = vec4(mix(c.rgb, vec3(1.0), edge * 0.55), c.a * a);
}
