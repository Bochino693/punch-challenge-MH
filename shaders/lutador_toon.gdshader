shader_type spatial;

// O LUTADOR EM DESENHO — MAS EM DESENHO COM VOLUME.
//
// O QUE ESTAVA ERRADO NA VERSÃO ANTERIOR, e a queixa foi exata: "parece
// 2D". Estava, e por escolha: o sombreador tinha DUAS bandas de luz e
// ZERO especular. Duas bandas chapadas num corpo redondo produzem
// exatamente o que se vê num boneco de papelão — uma área clara, uma
// escura, e nenhuma informação entre elas sobre a forma que está
// embaixo.
//
// Olhando a referência que o operador mandou, o que ela tem e isto não
// tinha:
//
//   BRILHO. Cada músculo tem um estouro de luz branca em cima. É ele
//   que diz "isto é uma superfície curva e lisa", e é o que mais falta
//   quando um desenho parece chapado. Não é brilho de plástico — é
//   duro, recortado, com borda definida, do jeito que um ilustrador
//   pinta um realce e não do jeito que um motor calcula reflexo.
//
//   MAIS DE UM DEGRAU DE SOMBRA. A referência tem luz, meio-tom, sombra
//   e sombra profunda nas dobras. Com dois degraus, peito e abdome
//   caíam no mesmo tom e o relevo modelado não aparecia.
//
//   MATERIAIS DIFERENTES. A luva de couro envernizado e a pele não
//   podem refletir igual. Aqui cada vértice traz o seu brilho em
//   `UV.y` — ver `Figura.fundir` —, então a luva estoura e a pele
//   acompanha de leve, na mesma chamada de desenho.
//
//   OCLUSÃO NAS DOBRAS. Onde duas formas se encontram — a axila, a
//   virilha, o vinco entre os peitorais — a luz não chega. Sem isso, um
//   corpo montado de volumes sobrepostos parece um monte de balões
//   encostados; com isso, parece um corpo.
//
// `unshaded` continua de propósito: toda a conta acontece aqui, com uma
// direção de luz fixa. O resultado é o mesmo em qualquer aparelho, não
// depende de quantas luzes a cena tem e não custa nada — que é o que
// importa numa TV Box.

render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled;

// A cor da peça. Para um corpo cujas peças foram fundidas numa malha só
// (ver `Figura.fundir`) ela é branca, e quem manda é a cor do VÉRTICE.
uniform vec4 cor_base : source_color = vec4(0.91, 0.64, 0.44, 1.0);

// DE ONDE VEM A LUZ — e esta é a linha que mais muda a impressão de
// volume da figura inteira.
//
// Era quase frontal, e luz frontal APAGA a forma: ela ilumina tudo o que
// a câmera vê com a mesma intensidade, e o que sobra é uma silhueta
// preenchida. Foi a maior causa do "parece 2D", mais do que o número de
// bandas. Vinda de cima e bem de lado, a mesma conta parte o corpo em
// metade clara e metade escura, e é essa divisa correndo por cima do
// peitoral, do bíceps e da coxa que diz ao olho o que é redondo.
uniform vec3 direcao_da_luz = vec3(0.82, 0.54, 0.30);

// E UMA SEGUNDA LUZ, FRACA E FRIA, DO LADO OPOSTO.
//
// Sem ela a metade escura vira um bloco sem informação — o que um
// fotógrafo chama de sombra morta. Um rebatedor fraco do outro lado
// devolve o desenho ao lado escuro sem desfazer o contraste: é o
// procedimento padrão de qualquer estúdio, e custa um produto escalar.
uniform vec3 direcao_do_rebatedor = vec3(-0.76, 0.22, 0.42);
uniform vec4 cor_do_rebatedor : source_color = vec4(0.42, 0.58, 0.95, 1.0);
uniform float forca_do_rebatedor = 0.22;

// QUANTOS DEGRAUS DE LUZ — e por que agora são três, e não dois.
//
// Dois foi a resposta certa para a pergunta errada. A primeira versão
// tinha três e o boneco saía riscado como veludo cotelê, porque o corpo
// era feito de cilindros e cada cilindro atravessava os três degraus por
// conta própria. Baixar para dois tirou as listras e tirou junto TODA a
// informação de forma: sobraram duas cores chapadas.
//
// O que conserta não é o número de degraus: é onde eles caem. Com os
// degraus espremidos na metade escura (ver `_banda`), a metade iluminada
// fica larga e limpa — sem listra — e a transição para a sombra ganha o
// meio-tom que descreve a curvatura. É como um ilustrador pinta: muita
// luz, pouca sombra, e a informação toda na divisa.
uniform float bandas = 4.0;

// Quanto a sombra escurece, e para que tom ela puxa. SOMBRA COLORIDA,
// NÃO PRETA: a parte escura não é a cor multiplicada por um número menor
// — isso dá cinza sujo. É a cor puxada para um tom frio e roxo, que é o
// que pintor de desenho faz e o que dá vida à pele.
uniform float profundidade_da_sombra = 0.88;
uniform vec4 tom_da_sombra : source_color = vec4(0.26, 0.13, 0.36, 1.0);

// O BRILHO. `forca` é o teto (a luva chega nele; a pele fica bem abaixo,
// porque `UV.y` a segura), e `dureza` é o tamanho do estouro.
//
// E O TAMANHO É TUDO. Com 52 o realce saía como MANCHA: numa superfície
// quase plana — um peitoral, uma testa — a conta se mantém alta por uma
// área enorme, e o que aparece são borrões brancos moles espalhados pelo
// corpo, como tinta respingada. Um realce de verdade é pequeno e duro;
// 140 é o que o encolhe até o tamanho de um ponto de luz em vez de um
// borrão, que é como um ilustrador o pinta.
uniform float forca_do_brilho = 1.15;
uniform float dureza_do_brilho = 140.0;
uniform vec4 cor_do_brilho : source_color = vec4(1.0, 0.97, 0.92, 1.0);

// As duas luzes de contorno e o quanto elas invadem para dentro.
uniform vec4 contorno_quente : source_color = vec4(1.00, 0.14, 0.30, 1.0);
uniform vec4 contorno_frio : source_color = vec4(0.32, 0.86, 1.00, 1.0);
uniform float dureza_do_contorno = 2.6;
uniform float forca_do_contorno = 1.25;

// O clarão do impacto, empurrado pelo jogo no instante do soco.
uniform float clarao = 0.0;

varying vec3 cor_do_vertice;
varying float brilho_da_peca;

void vertex() {
	cor_do_vertice = COLOR.rgb;
	// `UV.y` traz o brilho da peça (ver `Figura.fundir`); `UV.x` é a
	// máscara do contorno e não interessa aqui.
	brilho_da_peca = UV.y;
}

// A OCLUSÃO DE CONTATO SAIU DAQUI, e vale contar por quê para ninguém
// tentar de novo.
//
// A ideia era escurecer o que está fundo usando a distância do vértice
// até a origem da malha, que é barata e não precisa de mapa. Só que
// depois da fusão cada junta é uma malha com a sua própria origem, e
// essas origens estão em lugares diferentes do corpo: para a canela a
// distância variava de 0 a 0,2 e escurecia meia perna; para o tronco ia
// de 0 a 0,5 e não escurecia quase nada. O resultado eram faixas escuras
// no joelho e no cotovelo que não correspondiam a dobra nenhuma.
//
// O que de fato desenha a dobra é a divisa das bandas passando por cima
// de um relevo — ou seja, geometria mais sombreamento, que é o que esta
// versão faz.

void fragment() {
	vec3 tinta = cor_base.rgb * cor_do_vertice;
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	// A direção da luz vem do mundo e precisa chegar ao espaço da câmera,
	// senão a iluminação gira junto com o passeio da câmera e o lutador
	// parece estar num mundo que balança.
	vec3 l = normalize((VIEW_MATRIX * vec4(normalize(direcao_da_luz), 0.0)).xyz);
	float nl = clamp(dot(n, l), 0.0, 1.0);
	vec3 lr = normalize((VIEW_MATRIX * vec4(normalize(direcao_do_rebatedor), 0.0)).xyz);
	float nr = clamp(dot(n, lr), 0.0, 1.0);

	// AS BANDAS, ESPREMIDAS NA SOMBRA — mas só um pouco.
	//
	// Elevar `nl` antes de degrau-lo empurra as divisas para a parte
	// escura: a luz fica larga e sem listra, e os degraus se concentram
	// onde a forma vira, que é onde eles descrevem alguma coisa. Com
	// 1,9 a conta exagerava para o outro lado — quase o corpo inteiro
	// caía na banda clara e a figura saía LAVADA, sem contraste nenhum,
	// que é o oposto da referência. 1,25 é o meio: luz larga, sombra
	// presente e a divisa passando por cima do relevo.
	float curvado = pow(nl, 1.25);
	float degraus = max(bandas, 1.0);
	float bruto = curvado * degraus;
	float degrau = floor(bruto);
	float sobra = fract(bruto);
	// O `smoothstep` em volta da divisa evita o serrilhado que apareceria
	// numa borda perfeitamente dura em resolução baixa.
	float banda = (degrau + smoothstep(0.40, 0.60, sobra)) / degraus;

	// A sombra puxa para o tom frio em vez de apagar para o cinza.
	vec3 na_sombra = mix(tinta, tom_da_sombra.rgb * tinta * 1.45, profundidade_da_sombra);
	vec3 cor = mix(na_sombra, tinta, banda);

	// O REBATEDOR entra em DOIS degraus, e só onde a luz principal não
	// chega. Em degraus porque um degradê contínuo aqui desmancharia a
	// divisa chapada que o resto do sombreador veio construir.
	float devolvido = smoothstep(0.30, 0.62, nr) * (1.0 - banda);
	cor += cor_do_rebatedor.rgb * tinta * devolvido * forca_do_rebatedor;

	// O BRILHO, RECORTADO.
	//
	// A conta é a de sempre (meio-caminho entre a luz e o olho), mas o
	// resultado passa por um `smoothstep` apertado em vez de entrar
	// direto. É isso que transforma um degradê de reflexo — que lê como
	// plástico — numa mancha de borda definida, que é como um ilustrador
	// desenha um realce.
	vec3 meio = normalize(l + v);
	float duro = pow(clamp(dot(n, meio), 0.0, 1.0), dureza_do_brilho);
	float realce = smoothstep(0.26, 0.40, duro) * brilho_da_peca * forca_do_brilho;
	// Brilho só existe onde a luz bate. Sem esta linha ele aparece na
	// sombra e o corpo perde o volume que ele mesmo veio dar.
	realce *= smoothstep(0.02, 0.30, nl);
	cor = mix(cor, cor_do_brilho.rgb, clamp(realce, 0.0, 1.0));

	// AS DUAS LUZES DE CONTORNO. A escolha pelo lado do normal em vez de
	// duas luzes de verdade: custa uma linha e dá o mesmo recorte. É ela
	// que separa o lutador do fundo escuro e dá o ar de cartaz de jogo de
	// luta — vermelha de um lado, ciano do outro.
	float borda = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), dureza_do_contorno);
	vec3 tom_da_borda = mix(contorno_quente.rgb, contorno_frio.rgb, smoothstep(-0.35, 0.35, n.x));
	cor += tom_da_borda * borda * forca_do_contorno;

	// No soco a figura inteira acende por um instante.
	cor = mix(cor, vec3(1.0), clamp(clarao, 0.0, 1.0) * 0.55);

	ALBEDO = cor;
}
