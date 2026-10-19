shader_type canvas_item;
// 战斗特写角色：调色（tint，只染身体不染白色刀光）+ 受击闪白（flash 0..1）+ 必杀蓄力镀色（glow 的 rgb 叠加，a 为强度）

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow : source_color = vec4(1.0, 0.8, 0.3, 0.0);

void fragment() {
	vec4 c = COLOR;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb *= mix(tint.rgb, vec3(1.0), smoothstep(0.78, 0.95, lum));
	c.rgb = mix(c.rgb, c.rgb + glow.rgb * 0.6, glow.a);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c;
}
