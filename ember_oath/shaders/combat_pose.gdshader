shader_type canvas_item;
render_mode blend_mix, unshaded;

// 最早风条带是硬边 alpha（只有 0 / 255）。半透明采样直接丢弃，避免过滤或
// 预乘把中景灌进身体。COLOR 仍乘上去，必杀镀金、受击闪白、阵亡淡出保持原样。
// blend_mix 由引擎做一次预乘，着色器本身保持直通 alpha。
void fragment() {
	vec4 tex = textureLod(TEXTURE, UV, 0.0);
	if (tex.a < 0.5) {
		discard;
	}
	COLOR = vec4(tex.rgb * COLOR.rgb, COLOR.a);
}
