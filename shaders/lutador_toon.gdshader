shader_type spatial;

// O LUTADOR EM DESENHO, E NÃO EM PLÁSTICO.
//
// O QUE ESTAVA ERRADO. O GLB vinha com material comum: luz contínua e
// brilho especular. Num boneco feito de formas redondas, brilho especular
// vira uma bolota clara em cima de cada volume — e dezenas de bolotas
// claras em superfície lisa é exatamente a aparência de brinquedo de
// plástico barato. Não é estilo nenhum; é o resultado de não ter escolhido
// estilo.
//
// O QUE UM JOGO MODERNO DE DESENHO FAZ, e este arquivo faz:
//
//   BANDAS EM VEZ DE DEGRADÊ. A luz é arredondada para poucos degraus, e
//   não varia continuamente. É o que separa "sombreado" de "pintado": o
//   olho lê áreas de cor chapada com uma divisa nítida entre elas, que é
//   como um desenho animado é colorido de verdade.
//
//   SOMBRA COLORIDA, NÃO PRETA. A parte escura não é a cor multiplicada
//   por um número menor — isso dá cinza sujo. É a cor puxada para um tom
//   frio e roxo, que é o que pintor de desenho faz e o que dá vida à
//   pele.
//
//   ZERO ESPECULAR. Nenhum brilho de plástico. O que marca o volume é a
//   divisa das bandas e a luz de contorno, e mais nada.
//
//   LUZ DE CONTORNO NOS DOIS LADOS. Vermelha de um lado, ciano do outro,
//   nas bordas viradas para fora — a mesma linguagem das duas luzes que a
//   arena já tem. É ela que recorta o lutador contra o fundo escuro e dá
//   o ar de cartaz de jogo de luta.
//
// `unshaded` é de propósito: toda a conta acontece aqui, com uma direção
// de luz fixa. Assim o resultado é o mesmo em qualquer aparelho, não
// depende de quantas luzes a cena tem e não custa nada — o que importa
// numa TV Box.

render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled;

// A cor da peça. Para um corpo cujas peças foram fundidas numa malha só
// (ver `Figura.fundir`) ela é branca, e quem manda é a cor do VÉRTICE —
// é assim que cabeça, cabelo, olhos, sobrancelhas, nariz, boca e os sete
// espetos do cabelo cabem numa chamada de desenho em vez de dezenove.
uniform vec4 cor_base : source_color = vec4(0.91, 0.64, 0.44, 1.0);

varying vec3 cor_do_vertice;

void vertex() {
	cor_do_vertice = COLOR.rgb;
}

// De onde vem a luz principal, em coordenadas do mundo. Combina com o
// refletor que o cenário 2D já desenha caindo sobre o saco.
uniform vec3 direcao_da_luz = vec3(0.42, 0.78, 0.46);

// QUANTOS DEGRAUS DE LUZ — e por que dois, e não três.
//
// Três degraus é o clássico do desenho à mão. Neste boneco não funciona:
// o corpo é feito de volumes redondos empilhados (braço, antebraço, coxa,
// panturrilha), e cada volume redondo atravessa todos os degraus por
// conta própria. Com três, cada membro ganhava as suas três listras, e a
// figura inteira saía riscada como veludo cotelê — mais suja do que o
// plástico que a gente veio consertar.
//
// Com dois, cada volume tem uma parte na luz e uma na sombra, e a divisa
// é uma só: é a leitura chapada e limpa dos jogos de desenho modernos.
uniform float bandas = 2.0;

// Quanto a sombra escurece, e para que tom ela puxa.
uniform float profundidade_da_sombra = 0.34;
uniform vec4 tom_da_sombra : source_color = vec4(0.30, 0.22, 0.42, 1.0);

// As duas luzes de contorno e o quanto elas invadem para dentro.
uniform vec4 contorno_quente : source_color = vec4(1.00, 0.16, 0.24, 1.0);
uniform vec4 contorno_frio : source_color = vec4(0.20, 0.86, 1.00, 1.0);
uniform float dureza_do_contorno = 3.2;
uniform float forca_do_contorno = 0.85;

// O clarão do impacto, empurrado pelo jogo no instante do soco.
uniform float clarao = 0.0;

void fragment() {
	vec3 tinta = cor_base.rgb * cor_do_vertice;
	vec3 n = normalize(NORMAL);
	// A direção da luz vem do mundo e precisa chegar ao espaço da câmera,
	// senão a iluminação gira junto com o passeio da câmera e o lutador
	// parece estar num mundo que balança.
	vec3 l = normalize((VIEW_MATRIX * vec4(normalize(direcao_da_luz), 0.0)).xyz);
	float nl = clamp(dot(n, l), 0.0, 1.0);

	// AS BANDAS. Arredondar para o degrau mais próximo é o passo inteiro;
	// o `smoothstep` em volta da divisa evita o serrilhado que apareceria
	// numa borda perfeitamente dura em resolução baixa.
	float degraus = max(bandas, 1.0);
	float bruto = nl * degraus;
	float degrau = floor(bruto);
	float sobra = fract(bruto);
	float banda = (degrau + smoothstep(0.42, 0.58, sobra)) / degraus;

	// A sombra puxa para o tom frio em vez de apagar para o cinza.
	vec3 na_sombra = mix(tinta, tom_da_sombra.rgb * tinta * 1.6, profundidade_da_sombra);
	vec3 cor = mix(na_sombra, tinta, banda);

	// AS DUAS LUZES DE CONTORNO. A escolha pelo lado do normal em vez de
	// duas luzes de verdade: custa uma linha e dá o mesmo recorte.
	float borda = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), dureza_do_contorno);
	vec3 tom_da_borda = mix(contorno_quente.rgb, contorno_frio.rgb, smoothstep(-0.35, 0.35, n.x));
	cor += tom_da_borda * borda * forca_do_contorno;

	// No soco a figura inteira acende por um instante.
	cor = mix(cor, vec3(1.0), clamp(clarao, 0.0, 1.0) * 0.55);

	ALBEDO = cor;
}
