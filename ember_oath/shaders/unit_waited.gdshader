shader_type canvas_item;
// 地图像素小人：阵营色 1px 外描边 + 「已行动」去饱和压暗（GBA 火纹式）
// amount 0 = 原色，1 = 全灰；frame_uv 是当前帧在整张表里的 UV 范围，防止描边采到隔壁帧

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.35, 0.6, 1.0, 1.0);
uniform vec4 frame_uv = vec4(0.0, 0.0, 1.0, 1.0);

float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < frame_uv.x || uv.y < frame_uv.y || uv.x > frame_uv.z || uv.y > frame_uv.w) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec4 c = COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(g) * 0.72 + vec3(0.03, 0.03, 0.07);
	c.rgb = mix(c.rgb, grey, amount);
	if (c.a < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float n = max(max(alpha_at(TEXTURE, UV + vec2(px.x, 0.0)), alpha_at(TEXTURE, UV - vec2(px.x, 0.0))),
				max(alpha_at(TEXTURE, UV + vec2(0.0, px.y)), alpha_at(TEXTURE, UV - vec2(0.0, px.y))));
		if (n > 0.5) {
			vec3 oc = mix(outline_color.rgb, grey * 0.8, amount);
			c = vec4(oc, outline_color.a);
		}
	}
	COLOR = c;
}
