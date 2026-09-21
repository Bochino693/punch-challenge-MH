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

# ------------------------------------------------------------- os perfis
#
# Cada um é a anatomia de um membro escrita como (altura, raio), com a
# altura de 0 (base, junto da junta) a 1 (ponta). O músculo mora aqui: um
# bíceps é só um raio maior no meio do caminho, e um antebraço de
# boxeador é grosso no cotovelo (0,062) e fino no punho (0,038).

const P_BRACO := [
	Vector2(0.00, 0.054), Vector2(0.20, 0.070), Vector2(0.46, 0.072),
	Vector2(0.74, 0.062), Vector2(1.00, 0.050),
]
const P_ANTEBRACO := [
	Vector2(0.00, 0.056), Vector2(0.24, 0.059), Vector2(0.58, 0.046),
	Vector2(1.00, 0.036),
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
const P_CALCAO := [
	Vector2(0.00, 0.101), Vector2(0.55, 0.094), Vector2(1.00, 0.084),
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
const ALTURA_DO_QUADRIL := 0.905

## Monta o lutador inteiro, já de guarda, e devolve a raiz.
static func montar() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Lutador"

	# ------------------------------------------------------------ tronco
	var quadril := _peca(raiz, "Quadril", Vector3(0.0, ALTURA_DO_QUADRIL, 0.0),
		Figura.tubo(0.150, P_QUADRIL, 0.82), CALCAO)
	# O CÓS É BRANCO E GROSSO, e não mais um cinto preto sobre calção
	# preto. No primeiro render o quadril e o calção formavam uma mancha
	# escura única do meio da coxa ao peito: lia como maiô, e não como
	# calção de boxe. Uma faixa clara é o que separa uma coisa da outra e é
	# o que a referência tem.
	_peca(quadril, "Cos", Vector3(0.0, 0.128, 0.0),
		Figura.tubo(0.055, [Vector2(0.0, 0.122), Vector2(1.0, 0.116)], 0.82), BRANCO)
	_peca(quadril, "Cos_Fita", Vector3(0.0, 0.126, 0.0),
		Figura.tubo(0.018, [Vector2(0.0, 0.124), Vector2(1.0, 0.123)], 0.82), FAIXA)

	var tronco := _peca(quadril, "Tronco", Vector3(0.0, 0.128, 0.0),
		Figura.tubo(0.445, P_TRONCO, 0.74), PELE)
	# Peitoral e abdome são VOLUMES por cima do tronco, e não desenhos
	# nele: é o relevo que faz o corpo ler como musculoso num quadro
	# pequeno, onde uma textura de músculo viraria borrão.
	for lado in [-1.0, 1.0]:
		_peca(tronco, "Peito_%s" % _s(lado), Vector3(lado * 0.086, 0.330, 0.062),
			Figura.esfera(0.104, Vector3(1.02, 0.58, 0.50)), PELE_ESC)
	for linha in range(3):
		var y := 0.148 + float(linha) * 0.062
		var r := 0.044 - float(linha) * 0.004
		for lado in [-1.0, 1.0]:
			_peca(tronco, "Abdomen_%d_%s" % [linha, _s(lado)],
				Vector3(lado * 0.040, y, 0.076),
				Figura.esfera(r, Vector3(0.94, 0.74, 0.44)), PELE_ESC)

	# O PESCOÇO PRECISA APARECER. No primeiro render a cabeça descia até
	# dentro dos ombros e o boneco ficava sem pescoço nenhum — é
	# exatamente o que faz uma figura parecer atarracada, mesmo com o
	# tronco certo. Aqui a cabeça sobe até o pescoço sobrar uns três
	# centímetros de pele visível, que é o quanto se lê a três metros.
	var pescoco := _peca(tronco, "Pescoco", Vector3(0.0, 0.408, 0.0),
		Figura.tubo(0.090, P_PESCOCO, 0.92), PELE_ESC)

	# ------------------------------------------------------------- cabeça
	# A CABEÇA ENCOLHEU. Vinte e sete centímetros num corpo de 1,80 m dá
	# seis cabeças e meia de altura — proporção de desenho infantil. O
	# lutador da referência tem quase oito, e é a altura de cabeça que
	# separa "personagem de luta" de "boneco fofo".
	var cabeca := _peca(pescoco, "Cabeca", Vector3(0.0, 0.178, 0.0),
		Figura.esfera(0.112, Vector3(0.86, 1.08, 0.98)), PELE)
	_montar_rosto(cabeca)

	# ------------------------------------------------------------- braços
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		# O OMBRO SUBIU E CRESCEU. Era uma bolinha escondida embaixo da
		# linha do peito, e o braço parecia sair do tronco sem nada no meio.
		# O deltoide é a peça que mais fala "boxeador" numa silhueta, e ele
		# precisa passar POR CIMA da linha do trapézio para existir.
		var ombro := _peca(tronco, "Ombro_" + s, Vector3(lado * 0.222, 0.360, 0.0),
			Figura.esfera(0.104, Vector3(1.06, 0.98, 1.0)), PELE)
		var braco := _peca(ombro, "Braco_" + s, Vector3(0.0, -0.030, 0.0),
			Figura.tubo(0.255, P_BRACO, 0.94, Vector3.ZERO, 0.006, true), PELE)
		var antebraco := _peca(braco, "Antebraco_" + s, Vector3(0.0, -0.255, 0.0),
			Figura.tubo(0.245, P_ANTEBRACO, 0.94, Vector3.ZERO, 0.0, true), PELE)
		_peca(antebraco, "Punho_" + s, Vector3(0.0, -0.238, 0.0),
			Figura.tubo(0.040, [Vector2(0.0, 0.049), Vector2(1.0, 0.046)], 0.94, Vector3.ZERO, 0.0, true),
			BRANCO)
		# A LUVA É PROPORCIONAL AO PUNHO, e não à cabeça. Sessenta e seis
		# milímetros de raio contra um punho de 46: grande como luva de
		# boxe é, sem virar o balão que escondia o rosto inteiro na guarda
		# — e não dá para gostar de um personagem que nunca se vê.
		var luva := _peca(antebraco, "Luva_" + s, Vector3(0.0, -0.295, 0.012),
			Figura.esfera(0.066, Vector3(1.0, 1.04, 1.16)), LUVA)
		_peca(luva, "Costura_" + s, Vector3(0.0, 0.014, 0.060),
			Figura.esfera(0.031, Vector3(1.24, 0.22, 0.30)), LUVA_ESC)
		_peca(luva, "Punheira_" + s, Vector3(0.0, 0.062, -0.004),
			Figura.esfera(0.056, Vector3(1.02, 0.30, 1.02)), BRANCO)

	# ------------------------------------------------------------- pernas
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		var coxa := _peca(quadril, "Coxa_" + s, Vector3(lado * 0.076, -0.014, 0.0),
			Figura.tubo(0.455, P_COXA, 0.90, Vector3.ZERO, 0.010, true), PELE)
		# O CALÇÃO ACABA NO MEIO DA COXA. Descendo até o joelho ele vira
		# bermuda, encurta visualmente a perna e come justamente o pedaço de
		# pele que faz a figura parecer alta.
		_peca(coxa, "Calcao_" + s, Vector3(0.0, -0.070, 0.0),
			Figura.tubo(0.150, P_CALCAO, 0.92, Vector3.ZERO, 0.0, true), CALCAO)
		# As faixas do calção, a marca visual mais reconhecível da
		# referência: vermelho e branco correndo pela lateral da perna.
		_peca(coxa, "Faixa_R_" + s, Vector3(lado * 0.088, -0.130, 0.026),
			Figura.esfera(0.052, Vector3(0.16, 1.55, 0.44)), FAIXA)
		_peca(coxa, "Faixa_B_" + s, Vector3(lado * 0.090, -0.130, -0.024),
			Figura.esfera(0.048, Vector3(0.15, 1.50, 0.36)), BRANCO)
		var canela := _peca(coxa, "Canela_" + s, Vector3(0.0, -0.455, 0.0),
			Figura.tubo(0.445, P_CANELA, 0.92, Vector3.ZERO, 0.0, true), PELE)
		var bota := _peca(canela, "Bota_" + s, Vector3(0.0, -0.430, 0.020),
			Figura.esfera(0.074, Vector3(0.86, 0.82, 1.55)), BOTA)
		_peca(bota, "Sola_" + s, Vector3(0.0, -0.050, 0.006),
			Figura.esfera(0.068, Vector3(0.94, 0.17, 1.52)), BRANCO)
		_peca(canela, "Cano_" + s, Vector3(0.0, -0.330, 0.004),
			Figura.tubo(0.110, [Vector2(0.0, 0.058), Vector2(1.0, 0.050)], 0.94, Vector3.ZERO, 0.0, true),
			BOTA)

	# AS PEÇAS QUE NÃO ANDAM SOZINHAS VIRAM UMA SÓ. Ver `Figura.fundir`:
	# de sessenta e três chamadas de desenho para onze, e de cento e vinte
	# e seis para vinte e duas com o contorno. É a diferença entre o corpo
	# custar caro numa TV Box e custar nada.
	Figura.fundir(raiz, JUNTAS_MOVEIS)
	pousar(raiz)
	return raiz

## A GUARDA APLICADA EM CIMA DO REPOUSO.
##
## É uma função à parte porque o módulo de animação precisa saber de onde
## cada gesto parte: os nove clipes são ACRÉSCIMOS sobre esta pose, e não
## poses absolutas. Escrever o mesmo ângulo nos dois lugares seria a
## garantia de que um dia eles discordariam.
static func pousar(raiz: Node3D) -> void:
	for nome in POSE:
		var no := raiz.find_child(str(nome), true, false)
		if no is Node3D:
			(no as Node3D).rotation = POSE[nome]

## O ROSTO. Olhos, sobrancelhas bravas, nariz, boca e cabelo espetado — as
## cinco coisas sem as quais uma cabeça é um ovo, e "sem boca" foi
## exatamente a queixa que veio do operador sobre o boneco anterior.
static func _montar_rosto(cabeca: Node3D) -> void:
	for lado in [-1.0, 1.0]:
		var s := _s(lado)
		# O OLHO É MAIS LARGO QUE ALTO, e não uma bola. Redondo e grande ele
		# sai como óculos de proteção colados na testa — foi o primeiro
		# render — e é também a diferença entre um rosto de luta e um rosto
		# de desenho infantil. Anime de briga tem olho estreito, com a
		# pálpebra de cima cobrindo um terço da íris.
		var olho := _peca(cabeca, "Olho_" + s, Vector3(lado * 0.048, 0.010, 0.088),
			Figura.esfera(0.030, Vector3(1.16, 0.80, 0.30)), OLHO)
		# A PUPILA FICA NO MEIO DO OLHO. Deslocada para o lado do nariz — o
		# que a primeira versão fazia — os dois olhos convergem e o lutador
		# aparece VESGO, que é o defeito de rosto mais fácil de notar e o
		# mais difícil de perdoar num personagem que deveria intimidar.
		_peca(olho, "Pupila_" + s, Vector3(0.0, -0.002, 0.009),
			Figura.esfera(0.016, Vector3(0.90, 1.02, 0.42)), PUPILA)
		# A pálpebra de cima: uma lasca escura encostada no alto do olho. É
		# ela que estreita o olhar sem precisar de textura.
		_peca(olho, "Palpebra_" + s, Vector3(0.0, 0.019, 0.006),
			Figura.esfera(0.031, Vector3(1.16, 0.34, 0.34)), CABELO)
		# A SOBRANCELHA É O QUE DÁ A CARA BRAVA. Inclinada para dentro e
		# para baixo, ela sozinha muda a expressão inteira — é o truque
		# mais barato e mais eficaz do desenho de personagem, e é o que
		# separa este rosto de um boneco de vitrine.
		# A SOBRANCELHA ENCOLHEU E DESCEU PARA A TESTA. Grande e solta, ela
		# virava uma lasca preta flutuando acima do olho — e do perfil
		# chegava a escapar da silhueta da cabeça. O que dá a cara brava é o
		# ÂNGULO dela, não o tamanho.
		var sob := _peca(cabeca, "Sobrancelha_" + s, Vector3(lado * 0.047, 0.042, 0.086),
			Figura.esfera(0.031, Vector3(1.12, 0.15, 0.22)), CABELO)
		sob.rotate_z(lado * -0.46)
		_peca(cabeca, "Orelha_" + s, Vector3(lado * 0.099, -0.004, -0.012),
			Figura.esfera(0.030, Vector3(0.38, 1.05, 0.70)), PELE_ESC)

	# O NARIZ ENCOLHEU À METADE. No render ele ocupava o meio da cara
	# inteira, entre os dois olhos — um ovo no lugar de um nariz. Num rosto
	# de desenho o nariz é a peça que menos precisa aparecer: basta a
	# sombra de um vulto.
	_peca(cabeca, "Nariz", Vector3(0.0, -0.020, 0.098),
		Figura.esfera(0.017, Vector3(0.82, 1.15, 1.10)), PELE)
	# A BOCA PRECISA DE LÁBIO, senão é um buraco. No render sem ele a
	# abertura escura lia como um furo na cara; o lábio de baixo, claro e
	# logo abaixo, é o que a fecha e a faz ler como boca cerrada de quem
	# está esperando apanhar.
	_peca(cabeca, "Boca", Vector3(0.0, -0.060, 0.084),
		Figura.esfera(0.031, Vector3(1.05, 0.22, 0.36)), BOCA)
	_peca(cabeca, "Labio", Vector3(0.0, -0.072, 0.086),
		Figura.esfera(0.026, Vector3(1.04, 0.19, 0.34)), LABIO)
	# A MANDÍBULA É O QUE DÁ IDADE AO PERSONAGEM. Um queixo redondo lê
	# como criança por mais músculo que o corpo tenha; um queixo quadrado e
	# marcado lê como lutador. É a segunda peça mais barata do rosto,
	# depois da sobrancelha.
	_peca(cabeca, "Queixo", Vector3(0.0, -0.086, 0.040),
		Figura.esfera(0.050, Vector3(0.96, 0.80, 1.00)), PELE)
	# A MANDÍBULA ENCOSTA NA CABEÇA, e não sobra dela. Solta, aparecia como
	# dois caroços na bochecha — o tipo de volume que lê como inchaço, e
	# não como osso.
	for lado in [-1.0, 1.0]:
		_peca(cabeca, "Mandibula_%s" % _s(lado), Vector3(lado * 0.050, -0.054, 0.010),
			Figura.esfera(0.046, Vector3(0.52, 0.86, 1.00)), PELE)

	# O CABELO: uma calota e sete espetos virados para lados diferentes.
	# É o que dá cabelo de anime sem uma malha de cabelo de verdade — e
	# cada espeto custa dezesseis triângulos.
	# O CABELO ACOMPANHA A CABEÇA, e não a engole. Uma calota bem maior que
	# o crânio desce até a altura dos olhos e vira capacete — era o que
	# estava acontecendo, e é por isso que o olhar não aparecia.
	var cabelo := _peca(cabeca, "Cabelo", Vector3(0.0, 0.030, -0.008),
		Figura.esfera(0.104, Vector3(1.05, 0.92, 1.06)), CABELO)
	# OS ESPETOS SOBEM E VÃO PARA TRÁS, e não para os lados e para a
	# frente. Abertos, viravam pontas de chapéu de festa em volta da cara;
	# jogados para trás, viram a crista que a referência tem e ainda
	# alongam a silhueta, que é o que um personagem baixo precisa.
	var espetos := [
		[Vector3(-0.068, 0.058, 0.026), Vector3(0.52, 0.0, 0.46), 0.150],
		[Vector3(-0.030, 0.080, 0.046), Vector3(0.30, 0.0, 0.26), 0.180],
		[Vector3(0.028, 0.082, 0.040), Vector3(0.26, 0.0, -0.18), 0.192],
		[Vector3(0.070, 0.058, 0.018), Vector3(0.50, 0.0, -0.44), 0.150],
		[Vector3(-0.056, 0.058, -0.054), Vector3(0.92, 0.0, 0.30), 0.150],
		[Vector3(0.050, 0.056, -0.058), Vector3(0.96, 0.0, -0.24), 0.155],
		[Vector3(0.000, 0.086, -0.022), Vector3(0.44, 0.0, 0.03), 0.205],
	]
	for i in range(espetos.size()):
		var dados: Array = espetos[i]
		# A PONTA PUXA PARA O MAGENTA. Na referência o cabelo não é preto
		# chapado: ele tem um brilho frio na borda. Alternar a cor da
		# ponta é o jeito mais barato de sugerir isso sem textura.
		var cor: Color = CABELO_LUZ if i % 2 == 1 else CABELO
		var e := _peca(cabelo, "Espeto_%d" % (i + 1), dados[0],
			Figura.espeto(Vector2(0.054, 0.046), dados[2]), cor)
		e.rotation = dados[1]

static func _s(lado: float) -> String:
	return "E" if lado < 0.0 else "D"

## Uma peça: nó, malha, cor declarada e sombra desligada.
static func _peca(pai: Node3D, nome: String, posicao: Vector3, malha: ArrayMesh, cor: Color) -> MeshInstance3D:
	var no := MeshInstance3D.new()
	no.name = nome
	no.mesh = malha
	no.position = posicao
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A COR VIAJA COM A PEÇA. Não há material aqui: `Arena3D` lê este
	# metadado na hora de pintar tudo de desenho, e é por isso que o
	# lutador nativo não carrega uma única textura nem um único
	# `StandardMaterial3D` — menos estado para a TV Box guardar.
	no.set_meta("cor", cor)
	pai.add_child(no)
	return no
