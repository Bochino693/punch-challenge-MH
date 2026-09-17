shader_type spatial;

// O CONTORNO — A LINHA PRETA EM VOLTA DO BONECO.
//
// É o traço que separa um render 3D de um DESENHO. Sem ele, o lutador é
// um objeto iluminado; com ele, é um personagem desenhado, porque contorno
// é o que todo desenho tem e nenhuma fotografia tem. É também o que faz a
// figura se destacar de um fundo escuro sem precisar de mais luz.
//
// COMO FUNCIONA: a casca invertida. O mesmo corpo é desenhado uma segunda
// vez, com cada vértice empurrado um pouco para fora ao longo da própria
// normal e com as faces da FRENTE descartadas (`cull_front`). Sobra só a
// parte de trás dessa casca um pouco maior — que aparece exatamente como
// uma borda em volta da silhueta.
//
// POR QUE ASSIM E NÃO COM UM FILTRO DE TELA. Detectar borda lendo a
// profundidade da tela inteira custa uma passada de pós-processamento em
// cada quadro, em cada pixel — o contrário do que uma TV Box aguenta.
// A casca invertida custa desenhar o boneco de novo, e o boneco tem umas
// poucas centenas de triângulos.
//
// E ELE ACOMPANHA A ANIMAÇÃO SOZINHO: o deslocamento acontece antes de o
// esqueleto ser aplicado, então a casca dobra o braço junto com o braço.

render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

// Em metros. O lutador tem cerca de 1,8 m, então um centímetro e meio é
// um traço grosso de desenho sem virar uma mancha.
uniform float espessura = 0.016;
uniform vec4 cor : source_color = vec4(0.05, 0.02, 0.06, 1.0);

void vertex() {
	VERTEX += normalize(NORMAL) * espessura;
}

void fragment() {
	ALBEDO = cor.rgb;
}
