class_name LutadorNativo
extends RefCounted

## O LUTADOR, MONTADO PELO JOGO — SEM ARQUIVO, SEM BLENDER, SEM PYTHON.
##
## POR QUE ELE DEIXOU DE SER UM `.glb`. O boneco era gerado por um script
## em Python e assado num arquivo que o jogo carregava. Isso custava três
## coisas ao mesmo tempo: uma dependência de linguagem que não pode
## existir num gabinete de salão, um arquivo binário que ninguém consegue
## revisar num `diff`, e — a pior delas — um ciclo de ajuste que passava
## por abrir o Blender. Cada milímetro de proporção era uma viagem de ida
## e volta por fora do Godot.
##
## Aqui o corpo é CÓDIGO. Mudar o V do tronco é mudar um número nesta
## página e rodar o jogo. E some junto com o Python o `GERAR_PERSONAGEM.bat`
## e o risco de alguém receber a máquina sem o modelo dentro.
##
## AS PROPORÇÕES SÃO METADE DO TRABALHO. A referência que o operador
## mandou é um boxeador de anime, e o que o define não é o desenho do
## rosto: é a SILHUETA. Ombro largo, cintura fina, perna comprida,
## músculo marcado e luva proporcional ao punho. As versões anteriores
## erravam as quatro ao mesmo tempo, e por isso saía "gordinho" por mais
## que a iluminação melhorasse.
##
##   ombro a ombro     0,53 m      cintura           0,21 m
##   altura total      1,85 m      cabeça            0,27 m
##   perna (quadril    0,96 m      braço (ombro      0,55 m
##     ao chão)                      à luva)
##
## O V do tronco sai da razão 0,53 / 0,21 — dois e meio para um, que é a
## proporção de atleta de desenho. O modelo anterior era 0,50 / 0,38, e um
## e pouco para um é a proporção de um barril.
##
## A OUTRA METADE É A SUPERFÍCIE. Ver `Figura`: cada peça é torneada a
## partir de uma tabela de raios, com a normal calculada pela inclinação
## do perfil. É isso que dá bíceps, panturrilha e peitoral com luz
## contínua, em vez de blocos com quina — e quina viva era o motivo de o
## boneco de caixas parecer gráfico ruim por mais luz que levasse.
##
## POR QUE HIERARQUIA DE NÓS E NÃO MALHA COM PELE. Malha com pele exige
## deformar cada vértice a cada quadro, e o destino é uma TV Box. Peças
## articuladas são trinta matrizes e nada mais. A junta não aparece
## porque cada peça termina em calota e a seguinte começa dentro dela — a
## mesma solução que boneco articulado de verdade usa.
##
## OS NOMES SÃO CONTRATO. `Lutador3D.JUNTAS` e as nove animações procuram
## as peças por nome; renomear aqui é renomear lá.

# ------------------------------------------------------------------ tinta
#
# A PALETA VEM DA REFERÊNCIA: cabelo preto espetado com brilho magenta,
# luva vermelha, calção preto com faixa vermelha e branca na lateral.
const PELE := Color(0.95, 0.72, 0.52)
## O RELEVO DO CORPO É QUASE DA COR DA PELE, DE PROPÓSITO.
##
## A primeira versão pintou peitoral e abdome de um marrom bem mais
## escuro, e no render eles não leram como músculo: leram como SUJEIRA —
## manchas redondas num corpo claro. Quem desenha personagem resolve isso
## ao contrário do que parece intuitivo: o volume é GEOMETRIA, e a divisa
## das bandas de luz é que o revela. A cor só precisa acompanhar de leve.
const PELE_ESC := Color(0.90, 0.66, 0.47)
const CALCAO := Color(0.09, 0.09, 0.13)
const COS := Color(0.06, 0.06, 0.09)
const FAIXA := Color(0.88, 0.09, 0.17)
const BRANCO := Color(0.96, 0.95, 0.93)
const LUVA := Color(0.90, 0.08, 0.15)
const LUVA_ESC := Color(0.46, 0.03, 0.07)
const BOTA := Color(0.10, 0.10, 0.14)
const CABELO := Color(0.09, 0.08, 0.12)
## O brilho magenta da referência, e não uma mecha magenta: o cabelo
## continua preto, só que com uma ponta fria. Colorir o espeto inteiro
## deu chapéu de festa.
const CABELO_LUZ := Color(0.22, 0.07, 0.18)
const OLHO := Color(0.97, 0.97, 0.97)
const PUPILA := Color(0.20, 0.04, 0.06)
const BOCA := Color(0.16, 0.03, 0.05)
const LABIO := Color(0.62, 0.24, 0.24)

## ------------------------------------------------------- quanto brilha
##
## A queixa foi "parece 2D", e metade da culpa era desta tabela não
## existir. Na referência que o operador mandou, o que diz que aquilo é
## um corpo e não um desenho chapado é o ESTOURO DE LUZ: a luva de couro
## envernizado tem um realce branco duro, a pele tem um realce macio no
## alto de cada músculo, o calção de cetim tem uma faixa longa de luz.
## Três materiais, três comportamentos — e antes todos refletiam igual,
## ou seja, nenhum refletia.
const BRILHO_DA_PELE := 0.26
const BRILHO_DO_COURO := 1.00
const BRILHO_DO_CETIM := 0.82
const BRILHO_DO_CABELO := 0.26
const BRILHO_DO_OLHO := 1.00
const BRILHO_FOSCO := 0.16

# ------------------------------------------------------------- os perfis
#
# Cada um é a anatomia de um membro escrita como (altura, raio), com a
# altura de 0 (base, junto da junta) a 1 (ponta). O músculo mora aqui: um
# bíceps é só um raio maior no meio do caminho, e um antebraço de
# boxeador é grosso no cotovelo (0,062) e fino no punho (0,038).

## O BRAÇO ENGROSSOU. Comparado com a referência, o anterior era magro:
## 0,072 m de raio no meio do bíceps contra um tronco de 0,202. Braço de
## boxeador é grosso — e num personagem de guarda alta ele ocupa boa
## parte da silhueta, então é ele que diz se a figura é forte ou não.
const P_BRACO := [
	Vector2(0.00, 0.058), Vector2(0.20, 0.078), Vector2(0.46, 0.082),
	Vector2(0.74, 0.070), Vector2(1.00, 0.056),
]
const P_ANTEBRACO := [
	Vector2(0.00, 0.064), Vector2(0.24, 0.068), Vector2(0.58, 0.052),
	Vector2(1.00, 0.038),
]
const P_COXA := [
	Vector2(0.00, 0.098), Vector2(0.24, 0.092), Vector2(0.58, 0.079),
	Vector2(1.00, 0.062),
]
const P_CANELA := [
	Vector2(0.00, 0.062), Vector2(0.26, 0.073), Vector2(0.64, 0.050),
	Vector2(1.00, 0.039),
]
## O TRONCO É O PERSONAGEM. Da cintura (0,105) ao peito (0,178) são setenta
## por cento de ganho em trinta centímetros: é o V, e é o que se lê de
## longe antes de qualquer outra coisa.
## E A ÚLTIMA MEDIDA DELE É A MAIS IMPORTANTE, por um motivo que só
## apareceu no render: a ponta de cada peça torneada é fechada por uma
## CALOTA, e uma calota tem a altura do raio. Com o tronco terminando
## largo (0,150 m), a tampa virava uma cúpula de doze centímetros que
## subia por cima do queixo — o lutador parecia ter a cabeça deitada
## sobre o próprio peito, sem pescoço e sem mandíbula. Terminando estreito
## (0,088 m), a mesma tampa vira o trapézio, que é o que deveria estar
## ali.
const P_TRONCO := [
	Vector2(0.00, 0.118), Vector2(0.20, 0.100), Vector2(0.50, 0.168),
	Vector2(0.78, 0.202), Vector2(0.92, 0.170), Vector2(1.00, 0.088),
]
## O QUADRIL ESTREITOU. No primeiro render o calção era mais LARGO que o
## peito, e um corpo mais largo em baixo que em cima é uma pera, não um
## atleta — foi o que fez a silhueta continuar parecendo "gordinho"
## mesmo com o tronco já em V.
const P_QUADRIL := [
	Vector2(0.00, 0.112), Vector2(0.50, 0.121), Vector2(1.00, 0.108),
]
const P_PESCOCO := [
	Vector2(0.00, 0.064), Vector2(1.00, 0.055),
]
## A BARRA DO CALÇÃO TERMINA FINA. Terminando grossa, a calota que fecha
## o tubo virava uma aba saliente em volta da coxa — lia como bainha de
## fralda, e ainda abria uma fresta escura entre o pano e a perna.
const P_CALCAO := [
	Vector2(0.00, 0.104), Vector2(0.55, 0.096), Vector2(0.88, 0.086),
	Vector2(1.00, 0.072),
]

## A POSE DE GUARDA — DE ONDE O BONECO NASCE, e de onde as nove animações
## partem como acréscimos.
##
## Um lutador de braços caídos é um boneco de vitrine: não promete soco
## nenhum. A guarda alta — cotovelos dobrados e para a frente, luvas na
## altura do queixo, base aberta com um pé adiantado — é o que faz a tela
## dizer "ele está esperando o seu soco" antes de qualquer texto aparecer.
##
## O COTOVELO DOBRA EM X, NÃO EM Z. Dobrando em Z o antebraço abre para o
## LADO e a luva vai parar na altura do quadril, de braços abertos. A
## dobra de um cotovelo de boxe acontece no plano de frente: o antebraço
## sobe e vem para a frente, e é isso que põe a luva junto do queixo.
##
## E O SINAL DO Z ABRE OU FECHA A BASE. A coxa esquerda fica em x
## negativo; girá-la em +Z empurra o joelho PARA DENTRO, as duas pernas se
## cruzam e, de frente, o lutador aparece com uma perna só.
const POSE := {
	"Ombro_E": Vector3(-0.35, 0.0, 0.30),
	"Ombro_D": Vector3(-0.35, 0.0, -0.30),
	"Antebraco_E": Vector3(-2.70, 0.0, -0.22),
	"Antebraco_D": Vector3(-2.70, 0.0, 0.22),
	"Coxa_E": Vector3(0.24, 0.0, -0.15),
	"Coxa_D": Vector3(-0.22, 0.0, 0.14),
	"Canela_E": Vector3(-0.22, 0.0, 0.0),
	"Canela_D": Vector3(0.26, 0.0, 0.0),
	"Quadril": Vector3(0.0, 0.17, 0.0),
	"Cabeca": Vector3(0.06, -0.10, 0.0),
}

## OS NÓS QUE TÊM MOVIMENTO PRÓPRIO — e só eles.
##
## É a lista que as nove animações citam. Tudo o mais que o corpo tem é
## geometria pendurada num destes, e por isso pode ser costurada dentro
## dele na montagem (ver `Figura.fundir`). `Braco` e `Pescoco` ficam de
## fora de propósito: eles não giram por conta própria, então a sua
## geometria entra no ombro e no tronco — os nós continuam existindo,
## vazios, só para segurar o antebraço e a cabeça no lugar certo.
const JUNTAS_MOVEIS := [
	"Quadril", "Tronco", "Cabeca", "Ombro_E", "Ombro_D",
	"Antebraco_E", "Antebraco_D", "Coxa_E", "Coxa_D", "Canela_E", "Canela_D",
]

## A ALTURA DO QUADRIL COM A BASE ABERTA.
##
## Não é a soma dos ossos: com o joelho dobrado como a guarda pede, o
## corpo desce. Este número foi medido no render e é o que põe a sola em
## cima da lona em vez de dentro dela.
const ALTURA_DO_QUADRIL := 0.917

## Monta o lutador inteiro, já de guarda, e devolve a raiz.
## A CABEÇA, EM METROS DE RAIO — e por que ela encolheu de novo.
##
## A queixa depois do render anterior foi "boneco de Olinda", e é a
## descrição exata do que uma cabeça grande faz com uma figura: o boneco
## gigante do carnaval é justamente uma cabeça enorme sobre um corpo
## pequeno. Medido no modelo anterior, a figura tinha 7,4 cabeças de
## altura — proporção de desenho infantil. A referência que o operador
## mandou tem oito e pouco, que é a de herói de anime adulto, e é o que
## este número entrega: 0,22 m de cabeça num corpo de 1,84.
##
## Todas as medidas do rosto saem daqui, como fração do raio. Mexer neste
## número move o rosto inteiro junto, em vez de deixar o nariz para trás.
const RAIO_DA_CABECA := 0.101

## Monta o lutador inteiro, já de guarda, e devolve a raiz.
static func montar() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Lutador"

	# ------------------------------------------------------------ tronco
	var quadril := _peca(raiz, "Quadril", Vector3(0.0, ALTURA_DO_QUADRIL, 0.0),
		Figura.tubo(0.150, P_QUADRIL, 0.82), CALCAO, BRILHO_DO_CETIM)
	# O CÓS É BRANCO E GROSSO, e não um cinto preto sobre calção preto. No
	# primeiro render o quadril e o calção formavam uma mancha escura
	# única do meio da coxa ao peito: lia como maiô, e não como calção de
	# boxe. Uma faixa clara separa uma coisa da outra, e é o que a
	# referência tem.
	_peca(quadril, "Cos", Vector3(0.0, 0.128, 0.0),
		Figura.tubo(0.055, [Vector2(0.0, 0.122), Vector2(1.0, 0.116)], 0.82), BRANCO, BRILHO_DO_CETIM)
	_peca(quadril, "Cos_Fita", Vector3(0.0, 0.126, 0.0),
		Figura.tubo(0.018, [Vector2(0.0, 0.124), Vector2(1.0, 0.123)], 0.82), FAIXA, BRILHO_DO_CETIM)

	var tronco := _peca(quadril, "Tronco", Vector3(0.0, 0.128, 0.0),
		Figura.tubo(0.445, P_TRONCO, 0.74), PELE)
	_musculos_do_tronco(tronco)

	# O PESCOÇO PRECISA APARECER. Num render anterior a cabeça descia até
	# dentro dos ombros e o boneco ficava sem pescoço nenhum — é
	# exatamente o que faz uma figura parecer atarracada, mesmo com o
	# tronco certo.
	var pescoco := _peca(tronco, "Pescoco", Vector3(0.0, 0.408, 0.0),
		Figura.tubo(0.095, P_PESCOCO, 0.92), PELE_ESC)
	# O ESTERNOCLEIDOMASTÓIDEO, que é o músculo que faz um pescoço parecer
	# pescoço de atleta e não um cano: duas cordas descendo da orelha até
	# a base da garganta.
	for lado in [-1.0, 1.0]:
		var corda := _peca(pescoco, "Corda_%s" % _s(lado), Vector3(lado * 0.030, 0.038, 0.030),
			Figura.esfera(0.028, Vector3(0.52, 1.55, 0.60)), PELE)
		corda.rotate_z(lado * 0.20)

	# ------------------------------------------------------------- cabeça
	var cabeca := _peca(pescoco, "Cabeca", Vector3(0.0, 0.175, 0.0),
		Figura.esfera(RAIO_DA_CABECA, Vector3(0.88, 1.09, 0.97)), PELE)
	_montar_rosto(cabeca)

	# ------------------------------------------------------------- braços
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		# O DELTOIDE TEM TRÊS CABEÇAS, e é por isso que um ombro de
		# boxeador não é uma bola. A da frente, a do meio e a de trás se
		# encontram numa quina — e é essa quina, pegando a luz de um lado
		# só, que diz ao olho que ali tem músculo e não um balão.
		var ombro := _peca(tronco, "Ombro_" + s, Vector3(lado * 0.212, 0.356, 0.0),
			Figura.esfera(0.106, Vector3(1.04, 1.00, 0.96)), PELE)
		_peca(ombro, "Deltoide_F_" + s, Vector3(lado * -0.006, -0.012, 0.042),
			Figura.esfera(0.070, Vector3(0.96, 1.06, 0.66)), PELE)
		_peca(ombro, "Deltoide_T_" + s, Vector3(lado * -0.004, -0.010, -0.044),
			Figura.esfera(0.066, Vector3(0.94, 1.02, 0.64)), PELE)
		_peca(ombro, "Deltoide_L_" + s, Vector3(lado * 0.038, -0.030, 0.0),
			Figura.esfera(0.064, Vector3(0.82, 1.22, 0.98)), PELE)

		var braco := _peca(ombro, "Braco_" + s, Vector3(0.0, -0.030, 0.0),
			Figura.tubo(0.255, P_BRACO, 0.94, Vector3.ZERO, 0.006, true), PELE)
		# O bíceps é um pico na FRENTE e o tríceps uma massa atrás: os
		# dois juntos dão ao braço uma seção que não é redonda, e seção
		# não-redonda é o que a luz precisa para contar a forma.
		_peca(braco, "Biceps_" + s, Vector3(0.0, -0.098, 0.038),
			Figura.esfera(0.056, Vector3(0.96, 1.62, 0.76)), PELE)
		_peca(braco, "Triceps_" + s, Vector3(0.0, -0.116, -0.040),
			Figura.esfera(0.052, Vector3(1.04, 1.56, 0.70)), PELE)

		var antebraco := _peca(braco, "Antebraco_" + s, Vector3(0.0, -0.255, 0.0),
			Figura.tubo(0.245, P_ANTEBRACO, 0.94, Vector3.ZERO, 0.0, true), PELE)
		# O braquiorradial: a massa logo abaixo do cotovelo, do lado de
		# fora. É o que faz o antebraço afinar de um jeito e engrossar de
		# outro em vez de ser um cone.
		_peca(antebraco, "Braquial_" + s, Vector3(lado * 0.014, -0.068, 0.010),
			Figura.esfera(0.040, Vector3(0.78, 1.55, 0.84)), PELE)
		_peca(antebraco, "Punho_" + s, Vector3(0.0, -0.238, 0.0),
			Figura.tubo(0.040, [Vector2(0.0, 0.049), Vector2(1.0, 0.046)], 0.94, Vector3.ZERO, 0.0, true),
			BRANCO, BRILHO_DO_CETIM)
		# A LUVA É DE COURO ENVERNIZADO, e é a peça que mais brilha do
		# corpo inteiro. Na referência é ela que carrega o estouro branco
		# que diz "isto é 3D" antes de qualquer outra coisa. Sessenta e
		# seis milímetros de raio contra um punho de 46: grande como luva
		# de boxe é, sem virar o balão que escondia o rosto na guarda.
		var luva := _peca(antebraco, "Luva_" + s, Vector3(0.0, -0.295, 0.012),
			Figura.esfera(0.068, Vector3(1.0, 1.04, 1.16)), LUVA, BRILHO_DO_COURO)
		# Os gomos do couro: a costura que separa os dedos e a dobra do
		# polegar. São eles que quebram o estouro de luz em pedaços, e um
		# estouro quebrado lê como couro — um estouro inteiro lê como
		# bola de plástico.
		_peca(luva, "Costura_" + s, Vector3(0.0, 0.014, 0.062),
			Figura.esfera(0.031, Vector3(1.26, 0.20, 0.30)), LUVA_ESC, BRILHO_DO_COURO)
		_peca(luva, "Gomo_" + s, Vector3(0.0, -0.030, 0.030),
			Figura.esfera(0.028, Vector3(1.30, 0.18, 0.60)), LUVA_ESC, BRILHO_DO_COURO)
		_peca(luva, "Polegar_" + s, Vector3(lado * -0.052, -0.014, 0.030),
			Figura.esfera(0.034, Vector3(0.72, 0.92, 1.20)), LUVA, BRILHO_DO_COURO)
		_peca(luva, "Punheira_" + s, Vector3(0.0, 0.066, -0.004),
			Figura.esfera(0.058, Vector3(1.02, 0.34, 1.02)), BRANCO, BRILHO_DO_CETIM)

	# ------------------------------------------------------------- pernas
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		var coxa := _peca(quadril, "Coxa_" + s, Vector3(lado * 0.076, -0.014, 0.0),
			Figura.tubo(0.455, P_COXA, 0.90, Vector3.ZERO, 0.010, true), PELE)
		# O vasto lateral: a gota de músculo que desce pela parte de fora
		# da coxa e termina logo acima do joelho.
		_peca(coxa, "Vasto_" + s, Vector3(lado * 0.038, -0.300, 0.010),
			Figura.esfera(0.050, Vector3(0.74, 1.70, 0.88)), PELE)
		_peca(coxa, "Reto_" + s, Vector3(0.0, -0.250, 0.044),
			Figura.esfera(0.054, Vector3(1.10, 1.55, 0.52)), PELE)
		# O CALÇÃO ACABA NO MEIO DA COXA. Descendo até o joelho ele vira
		# bermuda, encurta visualmente a perna e come justamente o pedaço
		# de pele que faz a figura parecer alta.
		_peca(coxa, "Calcao_" + s, Vector3(0.0, -0.070, 0.0),
			Figura.tubo(0.150, P_CALCAO, 0.92, Vector3.ZERO, 0.0, true), CALCAO, BRILHO_DO_CETIM)
		# As faixas do calção: a marca visual mais reconhecível da
		# referência, vermelho e branco correndo pela lateral da perna.
		_peca(coxa, "Faixa_R_" + s, Vector3(lado * 0.088, -0.130, 0.026),
			Figura.esfera(0.052, Vector3(0.16, 1.55, 0.44)), FAIXA, BRILHO_DO_CETIM)
		_peca(coxa, "Faixa_B_" + s, Vector3(lado * 0.090, -0.130, -0.024),
			Figura.esfera(0.048, Vector3(0.15, 1.50, 0.36)), BRANCO, BRILHO_DO_CETIM)

		var canela := _peca(coxa, "Canela_" + s, Vector3(0.0, -0.455, 0.0),
			Figura.tubo(0.445, P_CANELA, 0.92, Vector3.ZERO, 0.0, true), PELE)
		# A PANTURRILHA TEM DUAS CABEÇAS, e uma é mais baixa que a outra.
		# É o detalhe mais barato que existe para uma perna parecer
		# treinada: duas gotas ligeiramente desencontradas, atrás.
		_peca(canela, "Gemeo_I_" + s, Vector3(lado * -0.020, -0.110, -0.024),
			Figura.esfera(0.044, Vector3(0.82, 1.45, 0.86)), PELE)
		_peca(canela, "Gemeo_E_" + s, Vector3(lado * 0.020, -0.132, -0.022),
			Figura.esfera(0.040, Vector3(0.80, 1.40, 0.84)), PELE)
		var bota := _peca(canela, "Bota_" + s, Vector3(0.0, -0.430, 0.020),
			Figura.esfera(0.074, Vector3(0.86, 0.82, 1.55)), BOTA, BRILHO_DO_COURO)
		_peca(bota, "Sola_" + s, Vector3(0.0, -0.050, 0.006),
			Figura.esfera(0.068, Vector3(0.94, 0.17, 1.52)), BRANCO, BRILHO_FOSCO)
		_peca(canela, "Cano_" + s, Vector3(0.0, -0.330, 0.004),
			Figura.tubo(0.110, [Vector2(0.0, 0.058), Vector2(1.0, 0.050)], 0.94, Vector3.ZERO, 0.0, true),
			BOTA, BRILHO_DO_COURO)

	# AS PEÇAS QUE NÃO ANDAM SOZINHAS VIRAM UMA SÓ. Ver `Figura.fundir`:
	# de dezenas de chamadas de desenho para onze, e o dobro disso com o
	# contorno. É a diferença entre o corpo custar caro numa TV Box e
	# custar nada — e é o que permite ter todo este músculo modelado sem
	# pagar por ele.
	Figura.fundir(raiz, JUNTAS_MOVEIS)
	pousar(raiz)
	return raiz

## O RELEVO DO TRONCO — a metade da queixa "parece 2D".
##
## A outra metade era o sombreador (ver `lutador_toon.gdshader`); esta é
## a geometria. Um tronco torneado é um volume liso: a luz cai nele de um
## jeito só e não há nada que quebre a passagem da luz para a sombra. O
## que faz um peito ler como peito é a SEQUÊNCIA de volumes — peitoral,
## serrátil, oblíquo, dorsal — cada um com a sua divisa, cada um pegando
## a luz num ângulo diferente.
##
## Tudo aqui é volume POR CIMA do tronco, e não desenho nele: numa tela
## de gabinete, textura de músculo vira borrão a dois metros, enquanto um
## relevo de verdade continua funcionando porque é a luz que o revela.
static func _musculos_do_tronco(tronco: Node3D) -> void:
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		# O PEITORAL. Largo, raso e encostado no do outro lado: o vale
		# que sobra entre os dois é o esterno, e ele aparece sozinho
		# porque a oclusão de contato do sombreador escurece o fundo da
		# fresta.
		# CHATO, ALTO E INCLINADO — e nenhuma das três é opcional.
		#
		# Redondo e fundo, o peitoral lê como SEIO, e foi o que dois
		# renders seguidos entregaram. O peitoral de um homem treinado é
		# uma PLACA: larga, rasa, com a massa em cima e a borda de baixo
		# cortando reto. E ela é inclinada, porque a fibra do músculo
		# corre do esterno para o ombro, subindo — é essa diagonal que o
		# olho reconhece como peito e não como volume redondo qualquer.
		#
		# A profundidade é o número que mais importa: 0,34 de achatamento
		# contra 0,46 é a diferença entre uma placa encostada nas
		# costelas e uma cúpula pendurada nelas.
		var peito := _peca(tronco, "Peito_" + s, Vector3(lado * 0.080, 0.344, 0.077),
			Figura.esfera(0.116, Vector3(1.24, 0.32, 0.27)), PELE)
		peito.rotate_z(lado * -0.20)
		# O DORSAL. A asa que sai debaixo da axila e afina até a cintura:
		# é ele, e não o peito, que desenha o V visto de frente.
		var dorsal := _peca(tronco, "Dorsal_" + s, Vector3(lado * 0.134, 0.268, -0.012),
			Figura.esfera(0.080, Vector3(0.60, 1.70, 0.84)), PELE)
		dorsal.rotate_z(lado * 0.26)
		# O SERRÁTIL: os três dentes que aparecem na lateral das costelas,
		# logo abaixo da axila, em quem tem pouca gordura. Em desenho ele
		# é quase uma assinatura de "atleta".
		for i in range(3):
			_peca(tronco, "Serra_%d_%s" % [i, s],
				Vector3(lado * (0.104 - float(i) * 0.008), 0.232 - float(i) * 0.036, 0.030),
				Figura.esfera(0.028, Vector3(0.68, 0.44, 0.76)), PELE)
		# O OBLÍQUO: a faixa que desce da costela até o cós e fecha o V
		# por baixo.
		var obliquo := _peca(tronco, "Obliquo_" + s, Vector3(lado * 0.064, 0.108, 0.040),
			Figura.esfera(0.060, Vector3(0.56, 1.30, 0.58)), PELE)
		obliquo.rotate_z(lado * 0.32)
		# O TRAPÉZIO, que liga o pescoço ao ombro. Sem ele o pescoço nasce
		# de um degrau, e degrau é o que denuncia peça encaixada em peça.
		var trapezio := _peca(tronco, "Trapezio_" + s, Vector3(lado * 0.076, 0.398, -0.014),
			Figura.esfera(0.062, Vector3(1.16, 0.44, 0.62)), PELE)
		trapezio.rotate_z(lado * -0.30)

	# O ABDOME: três fileiras de dois, subindo de tamanho e afundando de
	# relevo conforme descem. A fileira de baixo é menor e mais junta, que
	# é como um abdome de verdade se organiza — e é o que impede que os
	# seis pareçam seis bolinhas iguais coladas.
	for linha in range(3):
		var y := 0.150 + float(linha) * 0.060
		var r := 0.044 - float(linha) * 0.004
		var afastamento := 0.034 + float(linha) * 0.005
		for lado in [-1.0, 1.0]:
			_peca(tronco, "Abdomen_%d_%s" % [linha, _s(lado)],
				Vector3(lado * afastamento, y, 0.072),
				Figura.esfera(r, Vector3(0.94, 0.72, 0.30)), PELE)
	# E a linha alba: o sulco vertical no meio. É um volume FINO e
	# recuado, e o que ele faz é dar à oclusão de contato uma fresta para
	# escurecer bem no meio da barriga.
	_peca(tronco, "Linha_Alba", Vector3(0.0, 0.208, 0.074),
		Figura.esfera(0.018, Vector3(0.34, 3.40, 0.40)), PELE)

## garantia de que um dia eles discordariam.
static func pousar(raiz: Node3D) -> void:
	for nome in POSE:
		var no := raiz.find_child(str(nome), true, false)
		if no is Node3D:
			(no as Node3D).rotation = POSE[nome]

## O ROSTO — todas as medidas como fração do raio da cabeça.
##
## Escrito assim de propósito: a cabeça já encolheu duas vezes por causa
## de proporção, e nas duas o rosto ficou para trás — o nariz continuava
## do tamanho antigo no meio de uma cara menor. Com as medidas em fração,
## mexer em `RAIO_DA_CABECA` move o rosto inteiro junto.
static func _montar_rosto(cabeca: Node3D) -> void:
	var r := RAIO_DA_CABECA
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		# O OLHO É MAIS LARGO QUE ALTO, e não uma bola. Redondo e grande
		# ele sai como óculos de proteção colados na testa, e é também a
		# diferença entre um rosto de luta e um rosto de desenho
		# infantil: anime de briga tem olho estreito, com a pálpebra de
		# cima cobrindo um terço da íris.
		var olho := _peca(cabeca, "Olho_" + s, Vector3(lado * 0.43 * r, 0.09 * r, 0.79 * r),
			Figura.esfera(0.27 * r, Vector3(1.16, 0.80, 0.30)), OLHO, BRILHO_DO_OLHO)
		_peca(olho, "Pupila_" + s, Vector3(0.0, -0.02 * r, 0.08 * r),
			Figura.esfera(0.145 * r, Vector3(0.90, 1.02, 0.42)), PUPILA, BRILHO_DO_OLHO)
		# A pálpebra de cima: uma lasca escura encostada no alto do olho.
		# É ela que estreita o olhar sem precisar de textura.
		_peca(olho, "Palpebra_" + s, Vector3(0.0, 0.17 * r, 0.05 * r),
			Figura.esfera(0.28 * r, Vector3(1.16, 0.34, 0.34)), CABELO, BRILHO_DO_CABELO)
		# A SOBRANCELHA É O QUE DÁ A CARA BRAVA. O que manda é o ÂNGULO
		# dela, não o tamanho: inclinada para dentro e para baixo, ela
		# sozinha muda a expressão inteira. É o truque mais barato e mais
		# eficaz do desenho de personagem.
		var sob := _peca(cabeca, "Sobrancelha_" + s, Vector3(lado * 0.42 * r, 0.38 * r, 0.77 * r),
			Figura.esfera(0.26 * r, Vector3(1.16, 0.11, 0.18)), CABELO, BRILHO_DO_CABELO)
		sob.rotate_z(lado * -0.50)
		# O arco da órbita e a maçã do rosto. AFUNDADOS DE PROPÓSITO: na
		# primeira tentativa eles ficaram para fora da silhueta da cabeça
		# e apareceram como duas salsichas rosadas em cima da
		# sobrancelha. Relevo de rosto tem de ser um INCHAÇO da pele, não
		# uma peça pousada sobre ela — o que desenha a forma é a divisa
		# das bandas de luz passando por cima dele, e para isso basta
		# meio milímetro de saliência.
		_peca(cabeca, "Arcada_" + s, Vector3(lado * 0.34 * r, 0.46 * r, 0.56 * r),
			Figura.esfera(0.30 * r, Vector3(1.00, 0.24, 0.30)), PELE)
		_peca(cabeca, "Malar_" + s, Vector3(lado * 0.46 * r, -0.12 * r, 0.44 * r),
			Figura.esfera(0.26 * r, Vector3(0.74, 0.48, 0.58)), PELE)
		_peca(cabeca, "Orelha_" + s, Vector3(lado * 0.88 * r, -0.04 * r, -0.11 * r),
			Figura.esfera(0.27 * r, Vector3(0.38, 1.05, 0.70)), PELE_ESC)

	# O NARIZ É A PEÇA QUE MENOS PRECISA APARECER num rosto de desenho:
	# basta a sombra de um vulto. Num render anterior ele ocupava o meio
	# da cara inteira, entre os dois olhos — um ovo no lugar de um nariz.
	_peca(cabeca, "Nariz", Vector3(0.0, -0.18 * r, 0.87 * r),
		Figura.esfera(0.15 * r, Vector3(0.82, 1.15, 1.10)), PELE)
	# A BOCA PRECISA DE LÁBIO, senão é um buraco. A abertura escura
	# sozinha lia como um furo na cara; o lábio de baixo, claro e logo
	# abaixo, é o que a fecha e a faz ler como boca cerrada de quem está
	# esperando apanhar.
	_peca(cabeca, "Boca", Vector3(0.0, -0.53 * r, 0.75 * r),
		Figura.esfera(0.28 * r, Vector3(1.05, 0.22, 0.36)), BOCA, BRILHO_FOSCO)
	_peca(cabeca, "Labio", Vector3(0.0, -0.64 * r, 0.77 * r),
		Figura.esfera(0.23 * r, Vector3(1.04, 0.19, 0.34)), LABIO, 0.55)
	# A MANDÍBULA É O QUE DÁ IDADE AO PERSONAGEM. Um queixo redondo lê
	# como criança por mais músculo que o corpo tenha; um queixo quadrado
	# e marcado lê como lutador. É a segunda peça mais barata do rosto,
	# depois da sobrancelha.
	_peca(cabeca, "Queixo", Vector3(0.0, -0.77 * r, 0.36 * r),
		Figura.esfera(0.45 * r, Vector3(0.96, 0.78, 0.98)), PELE)
	for lado in [-1.0, 1.0]:
		_peca(cabeca, "Mandibula_%s" % _s(lado), Vector3(lado * 0.45 * r, -0.48 * r, 0.09 * r),
			Figura.esfera(0.41 * r, Vector3(0.52, 0.86, 1.00)), PELE)

	# O CABELO: uma calota e sete espetos virados para lados diferentes.
	# É o que dá cabelo de anime sem uma malha de cabelo de verdade — e
	# cada espeto custa dezesseis triângulos. Os espetos sobem e vão para
	# TRÁS: abertos, viravam pontas de chapéu de festa em volta da cara;
	# jogados para trás, viram a crista da referência e ainda alongam a
	# silhueta, que é o que um personagem baixo precisa.
	var cabelo := _peca(cabeca, "Cabelo", Vector3(0.0, 0.27 * r, -0.07 * r),
		Figura.esfera(0.93 * r, Vector3(1.05, 0.92, 1.06)), CABELO, BRILHO_DO_CABELO)
	var espetos := [
		[Vector3(-0.67, 0.55, 0.25), Vector3(0.52, 0.0, 0.46), 1.38],
		[Vector3(-0.29, 0.76, 0.44), Vector3(0.30, 0.0, 0.26), 1.62],
		[Vector3(0.27, 0.78, 0.38), Vector3(0.26, 0.0, -0.18), 1.72],
		[Vector3(0.68, 0.55, 0.17), Vector3(0.50, 0.0, -0.44), 1.38],
		[Vector3(-0.55, 0.55, -0.52), Vector3(0.92, 0.0, 0.30), 1.34],
		[Vector3(0.49, 0.53, -0.56), Vector3(0.96, 0.0, -0.24), 1.38],
		[Vector3(0.00, 0.82, -0.21), Vector3(0.44, 0.0, 0.03), 1.84],
	]
	for i in range(espetos.size()):
		var dados: Array = espetos[i]
		# A PONTA PUXA PARA O FRIO. Na referência o cabelo não é preto
		# chapado: ele tem um brilho de borda que o recorta contra o
		# fundo. Alternar a ponta é o jeito mais barato de sugerir isso
		# sem textura — e agora a luz de contorno do sombreador faz o
		# resto sozinha.
		var cor: Color = CABELO_LUZ if i % 2 == 1 else CABELO
		var e := _peca(cabelo, "Espeto_%d" % (i + 1), (dados[0] as Vector3) * r,
			Figura.espeto(Vector2(0.50 * r, 0.43 * r), float(dados[2]) * r),
			cor, BRILHO_DO_CABELO)
		e.rotation = dados[1]
static func _s(lado: float) -> String:
	return "E" if lado < 0.0 else "D"

## Uma peça: nó, malha, cor declarada e sombra desligada.
## Uma peça: nó, malha, cor, brilho e sombra desligada.
##
## `brilho` é o quanto a superfície estoura de luz — 0,3 para pele, 1,0
## para couro envernizado. Ele viaja no VÉRTICE (ver `Figura.fundir`) e
## não num material, porque depois da fusão não existe mais peça: a
## cabeça, o cabelo, os olhos e os sete espetos são uma superfície só. É
## isso que permite a luva ter o estouro de couro e a pele ao lado dela
## ter só um realce macio, na mesma chamada de desenho.
static func _peca(
	pai: Node3D, nome: String, posicao: Vector3, malha: ArrayMesh,
	cor: Color, brilho := BRILHO_DA_PELE
) -> MeshInstance3D:
	var no := MeshInstance3D.new()
	no.name = nome
	no.mesh = malha
	no.position = posicao
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A COR VIAJA COM A PEÇA. Não há material aqui: `Arena3D` lê estes
	# metadados na hora de pintar tudo de desenho, e é por isso que o
	# lutador nativo não carrega uma única textura nem um único
	# `StandardMaterial3D` — menos estado para a TV Box guardar.
	no.set_meta("cor", cor)
	no.set_meta("brilho", brilho)
	pai.add_child(no)
	return no
