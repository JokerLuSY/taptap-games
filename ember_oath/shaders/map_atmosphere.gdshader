shader_type canvas_item;
// 地图氛围层（盖在整张棋盘上，不吃输入）：
// 云影 —— 低频噪声慢慢飘过，压暗一点；暖色调色 —— 第二章火场偏橙；暗角 —— 四角收一点光，把视线拉回中间。

uniform sampler2D noise : repeat_enable, filter_linear;
uniform float cloud_strength = 0.16;
uniform vec2 cloud_speed = vec2(0.012, 0.004);
uniform vec4 grade : source_color = vec4(1.0, 0.6, 0.25, 0.0);
uniform float vignette = 0.32;

void fragment() {
	vec2 uv = UV;
	float n = texture(noise, uv * vec2(1.5, 1.0) + TIME * cloud_speed).r;
	float cloud = smoothstep(0.52, 0.72, n) * cloud_strength;
	vec2 d = (uv - 0.5) * vec2(1.0, 0.85);
	float vig = smoothstep(0.35, 0.78, length(d)) * vignette;
	float a = clamp(cloud + vig + grade.a, 0.0, 0.85);
	vec3 col = (cloud * vec3(0.05, 0.06, 0.12) + vig * vec3(0.02, 0.01, 0.0) + grade.a * grade.rgb) / max(a, 0.001);
	COLOR = vec4(col, a);
}
