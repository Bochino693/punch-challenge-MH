class_name LutadorAnimacao
extends RefCounted

## AS NOVE AÇÕES DO LUTADOR, ESCRITAS EM ÂNGULOS.
##
## POR QUE ELAS SAÍRAM DO ARQUIVO. Estavam dentro do `lutador.glb`, que
## era gerado por um script em Python. Um gabinete de salão não pode
## depender de ninguém ter Python instalado para refazer o boneco, e
## animação assada em binário é animação que não entra num `diff`: a
## diferença entre "o soco levado ficou bom" e "ficou ruim" era invisível
## no histórico. Aqui cada gesto é uma tabela de números que dá para ler,
## comparar e ajustar sem sair do Godot.
##
## COMO SE LÊ UMA TABELA DESTAS. Cada papel tem uma duração e uma lista de
## peças. Para cada peça vêm cinco quadros igualmente espaçados dentro da
## duração — começo, ida, extremo, volta, fim — em `rot` (giro, em
## radianos) e `pos` (deslocamento, em metros).
##
## OS NÚMEROS SÃO ACRÉSCIMOS SOBRE A GUARDA, e não poses absolutas: o
## repouso de cada peça é o que `LutadorNativo.POSE` escreveu. É o que
## permite mexer na guarda sem reescrever os nove gestos, e é por isso que
## quase todo quadro começa e termina em zero — o lutador sempre volta
## para onde estava.
##
## CINCO QUADROS BASTAM, E É DE PROPÓSITO. A interpolação entre eles é
## contínua e o motor a calcula de graça; mais quadros só dariam mais
## números para alguém manter errados. O que faz um golpe levado parecer
## bom não é a quantidade de quadros: é o EXTREMO estar no lugar certo e
## a volta ser mais lenta que a ida, que é o que o terceiro e o quarto
## quadro fazem.

const QUADROS := 5

## QUAIS PAPÉIS SE REPETEM. O resto tem começo e fim, e repetir um gesto
## desses seria o tique nervoso que uma máquina de salão não pode ter.
const CONTINUOS := ["idle", "guard"]

const CLIPES := {
	# A RESPIRAÇÃO. Quase nada — e é justamente o quase nada que faz a
	# diferença entre "um boneco parado" e "alguém esperando". Um corpo
	# parado de verdade nunca está imóvel.
	"idle": {
		"duracao": 3.20,
		"pecas": {
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0, 0.018, 0), Vector3(0, 0, 0), Vector3(0, -0.012, 0), Vector3(0, 0, 0)]},
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(-0.025, 0.018, 0), Vector3(0, 0, 0), Vector3(0.022, -0.018, 0), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(0.018, -0.028, 0), Vector3(0, 0, 0), Vector3(-0.015, 0.028, 0), Vector3(0, 0, 0)]},
			"Ombro_E": {"rot": [Vector3(0, 0, 0), Vector3(-0.03, 0, 0.02), Vector3(0, 0, 0), Vector3(0.02, 0, -0.015), Vector3(0, 0, 0)]},
			"Ombro_D": {"rot": [Vector3(0, 0, 0), Vector3(-0.025, 0, -0.02), Vector3(0, 0, 0), Vector3(0.02, 0, 0.015), Vector3(0, 0, 0)]},
		},
	},
	# A GUARDA ATIVA: o mesmo corpo, com o peso passando de um pé ao
	# outro. Mais curta e mais marcada que a respiração — é a postura de
	# quem já viu o soco chegar.
	"guard": {
		"duracao": 1.60,
		"pecas": {
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0.012, -0.014, 0.012), Vector3(0, 0, 0), Vector3(-0.012, 0.014, -0.008), Vector3(0, 0, 0)],
						"rot": [Vector3(0, 0, 0), Vector3(0, 0.05, 0), Vector3(0, 0, 0), Vector3(0, -0.05, 0), Vector3(0, 0, 0)]},
			"Ombro_E": {"rot": [Vector3(0, 0, 0), Vector3(-0.06, 0, 0.035), Vector3(0, 0, 0), Vector3(0.03, 0, -0.025), Vector3(0, 0, 0)]},
			"Ombro_D": {"rot": [Vector3(0, 0, 0), Vector3(-0.05, 0, -0.035), Vector3(0, 0, 0), Vector3(0.03, 0, 0.025), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(0, 0.06, 0.02), Vector3(0, 0, 0), Vector3(0, -0.06, -0.02), Vector3(0, 0, 0)]},
		},
	},
	# O DESDÉM. Ele balança a cabeça, abre a guarda de um lado e convida.
	# É a resposta a um soco fraco, e precisa ler como resposta — não como
	# um golpe pequeno.
	"taunt_weak": {
		"duracao": 1.40,
		"pecas": {
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(0.05, -0.42, -0.11), Vector3(0.07, 0.38, 0.10), Vector3(0.04, -0.30, -0.08), Vector3(0, 0, 0)]},
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(0.04, 0, 0.12), Vector3(0.03, 0, -0.08), Vector3(0.04, 0, 0.09), Vector3(0, 0, 0)]},
			"Ombro_E": {"rot": [Vector3(0, 0, 0), Vector3(0.34, 0, 0.24), Vector3(0.42, 0, 0.28), Vector3(0.30, 0, 0.20), Vector3(0, 0, 0)]},
			"Antebraco_E": {"rot": [Vector3(0, 0, 0), Vector3(0.62, 0, 0.10), Vector3(0.86, 0, 0.14), Vector3(0.56, 0, 0.08), Vector3(0, 0, 0)]},
			"Ombro_D": {"rot": [Vector3(0, 0, 0), Vector3(-0.08, 0, -0.15), Vector3(-0.05, 0, -0.10), Vector3(-0.08, 0, -0.14), Vector3(0, 0, 0)]},
		},
	},
	# ------------------------------------------------------ os socos levados
	#
	# Os três sobem juntos em TUDO: quanto a cabeça vira, quanto o tronco
	# torce, quanto o quadril recua e quanto tempo leva. É essa escada que
	# faz a reação ser coerente com a nota na tela — um soco de 9.000 não
	# pode parecer o mesmo que um de 3.000, e era essa a queixa.
	"hit_light": {
		"duracao": 0.52,
		"pecas": {
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(-0.12, 0.10, 0.05), Vector3(-0.20, -0.10, -0.08), Vector3(-0.06, 0, 0), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(-0.22, 0.34, 0.12), Vector3(-0.10, -0.14, -0.05), Vector3(-0.04, 0, 0), Vector3(0, 0, 0)]},
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0.01, 0, -0.03), Vector3(0, 0, -0.05), Vector3(0, 0, -0.01), Vector3(0, 0, 0)]},
		},
	},
	"hit_medium": {
		"duracao": 0.78,
		"pecas": {
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0.04, 0, -0.08), Vector3(-0.03, 0, -0.14), Vector3(0, 0, -0.05), Vector3(0, 0, 0)]},
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(-0.18, 0.18, 0.10), Vector3(-0.38, -0.18, -0.14), Vector3(-0.12, 0.04, 0), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(-0.32, 0.48, 0.16), Vector3(-0.20, -0.22, -0.10), Vector3(-0.06, 0, 0), Vector3(0, 0, 0)]},
			"Ombro_E": {"rot": [Vector3(0, 0, 0), Vector3(0.18, 0, 0.16), Vector3(0.10, 0, -0.08), Vector3(0, 0, 0), Vector3(0, 0, 0)]},
			"Coxa_D": {"rot": [Vector3(0, 0, 0), Vector3(0.10, 0, 0), Vector3(0.16, 0, 0), Vector3(0.06, 0, 0), Vector3(0, 0, 0)]},
		},
	},
	"hit_heavy": {
		"duracao": 1.02,
		"pecas": {
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0.10, 0, -0.15), Vector3(-0.10, -0.03, -0.30), Vector3(-0.04, 0, -0.12), Vector3(0, 0, 0)]},
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(-0.28, 0.28, 0.18), Vector3(-0.62, -0.22, -0.20), Vector3(-0.20, 0.08, 0.04), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(-0.50, 0.62, 0.24), Vector3(-0.30, -0.34, -0.16), Vector3(-0.10, 0.06, 0), Vector3(0, 0, 0)]},
			"Ombro_D": {"rot": [Vector3(0, 0, 0), Vector3(0.25, 0, -0.24), Vector3(0.15, 0, 0.12), Vector3(0, 0, 0), Vector3(0, 0, 0)]},
			"Coxa_E": {"rot": [Vector3(0, 0, 0), Vector3(-0.14, 0, 0), Vector3(-0.26, 0, 0), Vector3(-0.08, 0, 0), Vector3(0, 0, 0)]},
			"Coxa_D": {"rot": [Vector3(0, 0, 0), Vector3(0.18, 0, 0), Vector3(0.30, 0, 0), Vector3(0.10, 0, 0), Vector3(0, 0, 0)]},
		},
	},
	# O CAMBALEIO: ele perde a base e reencontra. É o único gesto em que
	# as pernas fazem mais que o tronco, porque cambalear É a perna.
	"stagger": {
		"duracao": 1.30,
		"pecas": {
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0.16, -0.03, -0.18), Vector3(-0.22, -0.08, -0.42), Vector3(0.12, -0.03, -0.25), Vector3(0, 0, 0)],
						"rot": [Vector3(0, 0, 0), Vector3(-0.12, 0.10, 0.18), Vector3(-0.32, -0.14, -0.28), Vector3(-0.10, 0.05, 0.10), Vector3(0, 0, 0)]},
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(-0.35, 0.32, 0.24), Vector3(-0.72, -0.30, -0.34), Vector3(-0.22, 0.10, 0.12), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(-0.62, 0.72, 0.28), Vector3(-0.35, -0.44, -0.22), Vector3(-0.14, 0.10, 0.04), Vector3(0, 0, 0)]},
			"Coxa_E": {"rot": [Vector3(0, 0, 0), Vector3(0.18, 0, -0.12), Vector3(-0.32, 0, 0.18), Vector3(0.08, 0, 0), Vector3(0, 0, 0)]},
			"Coxa_D": {"rot": [Vector3(0, 0, 0), Vector3(-0.14, 0, 0.12), Vector3(0.40, 0, -0.18), Vector3(-0.06, 0, 0), Vector3(0, 0, 0)]},
			"Canela_E": {"rot": [Vector3(0, 0, 0), Vector3(-0.10, 0, 0), Vector3(0.35, 0, 0), Vector3(-0.05, 0, 0), Vector3(0, 0, 0)]},
			"Canela_D": {"rot": [Vector3(0, 0, 0), Vector3(0.12, 0, 0), Vector3(-0.30, 0, 0), Vector3(0.04, 0, 0), Vector3(0, 0, 0)]},
		},
	},
	# ------------------------------------------------------------- o nocaute
	#
	# ELE CAI DE VERDADE, E A QUEDA É DESTA TABELA.
	#
	# No modelo antigo a animação de nocaute movia a cabeça quatro
	# centímetros: o lutador se inclinava e voltava, enquanto o jogo
	# tocava som de queda, anunciava NOCAUTE e levava a câmera para a
	# altura da lona — o momento mais importante da partida era a câmera
	# olhando para um pedaço vazio de tapete. Havia um remendo que girava
	# o esqueleto por fora da animação; com o corpo nativo ele deixou de
	# ser preciso, porque a queda cabe aqui, onde deveria estar.
	#
	# E OS BRAÇOS ABREM PARA OS LADOS. Dobrados por cima da cabeça —
	# a primeira versão — eles ficavam escondidos atrás do próprio tronco
	# e, da câmera de nocaute, o lutador aparecia sem braço nenhum. Abertos
	# na lona, são eles que dizem "acabou" antes de qualquer texto.
	#
	# O quadril desce 0,72 m e gira 1,18 rad para trás: a linha do corpo
	# vai de vertical a quase horizontal, apoiada na lona. Os joelhos
	# dobram no meio do caminho porque um corpo que cai dobra — cair de
	# perna esticada é queda de tábua, e lê como bug.
	"knockout": {
		"duracao": 1.38,
		"pecas": {
			"Quadril": {"pos": [Vector3(0, 0, 0), Vector3(0.10, -0.04, -0.18), Vector3(-0.10, -0.34, -0.44), Vector3(-0.20, -0.66, -0.56), Vector3(-0.22, -0.72, -0.55)],
						"rot": [Vector3(0, 0, 0), Vector3(-0.28, 0.16, 0.20), Vector3(-0.62, -0.12, 0.42), Vector3(-1.05, -0.10, 0.66), Vector3(-1.18, -0.08, 0.72)]},
			"Tronco": {"rot": [Vector3(0, 0, 0), Vector3(-0.38, 0.20, 0.12), Vector3(-0.62, -0.20, -0.18), Vector3(-0.30, 0, -0.10), Vector3(-0.18, 0, 0)]},
			"Cabeca": {"rot": [Vector3(0, 0, 0), Vector3(-0.60, 0.44, 0.18), Vector3(-0.82, -0.30, -0.20), Vector3(-0.36, 0, 0), Vector3(-0.22, 0, 0)]},
			"Ombro_E": {"rot": [Vector3(0, 0, 0), Vector3(0.22, 0, 0.55), Vector3(0.44, 0, 1.00), Vector3(0.56, 0, 1.24), Vector3(0.58, 0, 1.28)]},
			"Ombro_D": {"rot": [Vector3(0, 0, 0), Vector3(0.22, 0, -0.55), Vector3(0.44, 0, -1.00), Vector3(0.56, 0, -1.24), Vector3(0.58, 0, -1.28)]},
			"Antebraco_E": {"rot": [Vector3(0, 0, 0), Vector3(0.70, 0, 0), Vector3(1.55, 0, 0), Vector3(2.30, 0, 0), Vector3(2.45, 0, 0)]},
			"Antebraco_D": {"rot": [Vector3(0, 0, 0), Vector3(0.70, 0, 0), Vector3(1.55, 0, 0), Vector3(2.30, 0, 0), Vector3(2.45, 0, 0)]},
			"Coxa_E": {"rot": [Vector3(0, 0, 0), Vector3(-0.20, 0, 0), Vector3(-0.55, 0, 0.10), Vector3(-0.80, 0, 0.14), Vector3(-0.86, 0, 0.14)]},
			"Coxa_D": {"rot": [Vector3(0, 0, 0), Vector3(-0.24, 0, 0), Vector3(-0.60, 0, -0.10), Vector3(-0.88, 0, -0.14), Vector3(-0.94, 0, -0.14)]},
			"Canela_E": {"rot": [Vector3(0, 0, 0), Vector3(0.25, 0, 0), Vector3(0.72, 0, 0), Vector3(1.00, 0, 0), Vector3(1.05, 0, 0)]},
			"Canela_D": {"rot": [Vector3(0, 0, 0), Vector3(0.28, 0, 0), Vector3(0.78, 0, 0), Vector3(1.06, 0, 0), Vector3(1.12, 0, 0)]},
		},
	},
	# E ELE LEVANTA PELO MESMO CAMINHO, ao contrário. O último quadro é
	# zero em tudo: a guarda de volta, sem costura com o clipe seguinte.
	"get_up": {
		"duracao": 1.58,
		"pecas": {
			"Quadril": {"pos": [Vector3(-0.22, -0.72, -0.55), Vector3(-0.20, -0.52, -0.44), Vector3(-0.10, -0.28, -0.28), Vector3(-0.03, -0.08, -0.10), Vector3(0, 0, 0)],
						"rot": [Vector3(-1.18, -0.08, 0.72), Vector3(-0.95, -0.06, 0.56), Vector3(-0.56, 0, 0.32), Vector3(-0.20, 0, 0.11), Vector3(0, 0, 0)]},
			"Tronco": {"rot": [Vector3(-0.18, 0, 0), Vector3(-0.30, 0, -0.08), Vector3(-0.24, 0, -0.06), Vector3(-0.10, 0, 0), Vector3(0, 0, 0)]},
			"Cabeca": {"rot": [Vector3(-0.22, 0, 0), Vector3(-0.18, 0, 0), Vector3(-0.12, 0, 0), Vector3(-0.05, 0, 0), Vector3(0, 0, 0)]},
			"Ombro_E": {"rot": [Vector3(0.58, 0, 1.28), Vector3(0.44, 0, 0.94), Vector3(0.26, 0, 0.52), Vector3(0.09, 0, 0.18), Vector3(0, 0, 0)]},
			"Ombro_D": {"rot": [Vector3(0.58, 0, -1.28), Vector3(0.44, 0, -0.94), Vector3(0.26, 0, -0.52), Vector3(0.09, 0, -0.18), Vector3(0, 0, 0)]},
			"Antebraco_E": {"rot": [Vector3(2.45, 0, 0), Vector3(1.80, 0, 0), Vector3(1.00, 0, 0), Vector3(0.34, 0, 0), Vector3(0, 0, 0)]},
			"Antebraco_D": {"rot": [Vector3(2.45, 0, 0), Vector3(1.80, 0, 0), Vector3(1.00, 0, 0), Vector3(0.34, 0, 0), Vector3(0, 0, 0)]},
			"Coxa_E": {"rot": [Vector3(-0.86, 0, 0.14), Vector3(-0.70, 0, 0.10), Vector3(-0.40, 0, 0.06), Vector3(-0.14, 0, 0.02), Vector3(0, 0, 0)]},
			"Coxa_D": {"rot": [Vector3(-0.94, 0, -0.14), Vector3(-0.76, 0, -0.10), Vector3(-0.44, 0, -0.06), Vector3(-0.15, 0, -0.02), Vector3(0, 0, 0)]},
			"Canela_E": {"rot": [Vector3(1.05, 0, 0), Vector3(0.86, 0, 0), Vector3(0.50, 0, 0), Vector3(0.18, 0, 0), Vector3(0, 0, 0)]},
			"Canela_D": {"rot": [Vector3(1.12, 0, 0), Vector3(0.92, 0, 0), Vector3(0.54, 0, 0), Vector3(0.19, 0, 0), Vector3(0, 0, 0)]},
		},
	},
}

## MONTA O TOCADOR E PENDURA-O NO CORPO.
##
## As faixas são `POSITION_3D` e `ROTATION_3D` — as mesmas que o motor usa
## para osso. São mais baratas do que faixa de propriedade genérica
## (nenhuma busca por nome de propriedade, nenhum `Variant` no caminho) e
## é o que permite trinta peças animadas custarem nada numa TV Box.
static func montar(raiz: Node3D) -> AnimationPlayer:
	var biblioteca := AnimationLibrary.new()
	for papel in CLIPES:
		var anim := _clipe(raiz, CLIPES[papel])
		anim.loop_mode = (
			Animation.LOOP_LINEAR if str(papel) in CONTINUOS else Animation.LOOP_NONE
		)
		biblioteca.add_animation(StringName(papel), anim)
	var tocador := AnimationPlayer.new()
	tocador.name = "AnimationPlayer"
	raiz.add_child(tocador)
	tocador.add_animation_library(&"", biblioteca)
	return tocador

static func _clipe(raiz: Node3D, definicao: Dictionary) -> Animation:
	var anim := Animation.new()
	var duracao := float(definicao["duracao"])
	anim.length = duracao
	var pecas: Dictionary = definicao["pecas"]
	for nome in pecas:
		var no := raiz.find_child(str(nome), true, false)
		if not (no is Node3D):
			continue
		var alvo := raiz.get_path_to(no)
		var repouso := no as Node3D
		var faixas: Dictionary = pecas[nome]
		if faixas.has("rot"):
			# A ROTAÇÃO DE REPOUSO ENTRA AQUI, UMA VEZ. Cada número da
			# tabela é um acréscimo sobre a guarda; somar os ângulos antes
			# de virar quaternião é o que mantém a tabela legível e a
			# guarda num lugar só.
			var base := repouso.rotation
			var t := anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(t, alvo)
			var lista: Array = faixas["rot"]
			for q in range(lista.size()):
				anim.rotation_track_insert_key(
					t, duracao * float(q) / float(QUADROS - 1),
					Quaternion.from_euler(base + (lista[q] as Vector3))
				)
		if faixas.has("pos"):
			var origem := repouso.position
			var t2 := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(t2, alvo)
			var lista2: Array = faixas["pos"]
			for q in range(lista2.size()):
				anim.position_track_insert_key(
					t2, duracao * float(q) / float(QUADROS - 1),
					origem + (lista2[q] as Vector3)
				)
	return anim
