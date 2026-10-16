shader_type canvas_item;
render_mode blend_mix, unshaded;

// 最早风条带是硬边 alpha（只有 0 / 255）。
// 片段里的 COLOR 已经是「贴图 × 父级 modulate」。再乘一次会把身体压暗，必杀镀金也会错。
// 这里只丢掉半透明采样，不透明像素保持引擎原来的直通 mix。阵亡淡出仍走 COLOR.a。
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.5) {
		discard;
	}
}
