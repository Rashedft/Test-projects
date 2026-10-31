shader_type spatial;
render_mode cull_disabled, diffuse_toon;
uniform vec4 grass_color : source_color = vec4(0.29,0.48,0.26,1.0);
void vertex() {
 vec3 p = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float sway = sin(p.x*1.9+p.z*1.3+TIME*1.5)*0.085;
 VERTEX.x += sway*max(VERTEX.y,0.0);
}
void fragment() {
 ALBEDO = grass_color.rgb*mix(0.65,1.25,UV.y);
 ROUGHNESS = 1.0;
}
