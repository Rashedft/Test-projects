shader_type spatial;
render_mode diffuse_burley;
uniform vec4 shallow : source_color = vec4(0.28,0.66,0.70,1.0);
uniform vec4 deep : source_color = vec4(0.18,0.45,0.58,1.0);
void vertex() {
 VERTEX.y += sin(VERTEX.x*1.7+TIME*0.9)*0.025+cos(VERTEX.z*2.3+TIME*0.7)*0.02;
}
void fragment() {
 float ripple = sin(UV.x*90.0+TIME*1.1+sin(UV.y*40.0))*cos(UV.y*110.0-TIME*0.8);
 ALBEDO = mix(shallow.rgb,deep.rgb,0.25+0.12*ripple);
 ALBEDO += smoothstep(0.84,1.0,ripple)*0.09;
 ROUGHNESS = 0.3;
 SPECULAR = 0.35;
}
