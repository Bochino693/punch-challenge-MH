shader_type spatial;

// Material híbrido: conserva a cor de ilustração, mas deixa as luzes reais
// da arena descreverem o volume. A versão antiga era `unshaded`; por isso
// peito, rosto e braços continuavam chapados mesmo cercados por três luzes.
render_mode cull_back, depth_draw_opaque, shadows_disabled;

uniform vec4 cor_base : source_color = vec4(0.91, 0.64, 0.44, 1.0);
uniform vec4 contorno_quente : source_color = vec4(1.0, 0.04, 0.22, 1.0);
uniform vec4 contorno_frio : source_color = vec4(0.08, 0.68, 1.0, 1.0);
uniform float forca_do_contorno = 0.34;
uniform float clarao = 0.0;

varying vec3 cor_do_vertice;
varying float brilho_da_peca;

void vertex() {
	cor_do_vertice = COLOR.rgb;
	brilho_da_peca = clamp(UV.y, 0.0, 1.0);
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	vec3 tinta = cor_base.rgb * cor_do_vertice;

	ALBEDO = tinta;
	ROUGHNESS = mix(0.72, 0.24, brilho_da_peca);
	SPECULAR = mix(0.28, 0.84, brilho_da_peca);
	METALLIC = 0.0;

	// Borda discreta, somente para separar a silhueta do fundo.
	float fresnel = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.4);
	vec3 cor_da_borda = mix(contorno_quente.rgb, contorno_frio.rgb,
		smoothstep(-0.25, 0.25, n.x));
	EMISSION = cor_da_borda * fresnel * forca_do_contorno
		+ vec3(1.0, 0.88, 0.78) * clamp(clarao, 0.0, 1.0) * 0.48;
}
