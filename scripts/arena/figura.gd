class_name Figura
extends RefCounted

## AS FORMAS DO CORPO — TORNEADAS, E NÃO EMPILHADAS.
##
## POR QUE ESTE ARQUIVO EXISTE. As duas versões anteriores do lutador
## erraram pelo mesmo motivo, por caminhos opostos: uma era um `.glb`
## assado no Blender, liso mas com proporção que não dá para corrigir sem
## abrir o Blender de novo; a outra era feita de CAIXAS, com a proporção
## certa e um aspecto de Minecraft que nenhuma iluminação conserta. Caixa
## empilhada é o jeito rápido de montar um boneco e é também o motivo de
## ele parecer gráfico ruim: o olho lê quina viva como "isto é um bloco",
## e nenhuma quantidade de sombreamento desfaz essa leitura.
##
## O QUE UM CORPO É, GEOMETRICAMENTE. Braço, perna, tronco e pescoço são
## todos a mesma coisa: uma sequência de ANÉIS de tamanhos diferentes,
## empilhados ao longo de um eixo e costurados. É assim que um torno
## funciona, e é assim que quase toda malha orgânica de jogo é feita. Com
## o anel certo em cada altura sai bíceps, panturrilha, peitoral e a
## cintura fina — a anatomia inteira vira uma TABELA DE RAIOS, que é uma
## coisa que dá para ajustar e comparar, ao contrário de vértices soltos.
##
## E A NORMAL É O QUE FAZ PARECER LISO. Numa caixa, cada face tem a sua
## normal e o sombreamento muda de repente na quina. Aqui a normal de cada
## vértice é calculada a partir da INCLINAÇÃO do perfil naquele ponto —
## analiticamente, não pela média dos triângulos vizinhos —, e o resultado
## é uma superfície contínua de verdade, sem costura e sem facetamento.
##
## TUDO ISTO EM GDSCRIPT, EM TEMPO DE EXECUÇÃO. Sem `.glb`, sem Blender e
## sem o gerador em Python: o corpo do lutador deixou de ser um arquivo
## que alguém precisa saber regerar e passou a ser código que o jogo lê
## como lê qualquer outro. É também o que permite mexer numa medida e ver
## o resultado sem sair do Godot.

## Quantos lados tem cada anel. Dezesseis é o ponto em que a silhueta de
## um braço deixa de mostrar faceta a um metro da tela; trinta e dois
## seria o dobro do custo para uma diferença que ninguém vê num quadro de
## 576 px de largura.
const LADOS := 16

## ------------------------------------------------------------------
## O PERFIL DE UM MEMBRO, EM PARES (altura, raio).
##
## `altura` vai de 0 (base da peça) a 1 (ponta). `raio` é em metros. O
## músculo mora aqui: um bíceps é só um raio maior no meio do caminho.
## ------------------------------------------------------------------

## Costura uma sequência de anéis num tubo fechado nas duas pontas.
##
## `perfil` é a tabela de (altura, raio). `comprimento` é o tamanho real
## da peça em metros; `achatamento` espreme o anel no eixo Z, que é o que
## transforma um tubo redondo num tronco de peito (mais largo que fundo).
## `para_baixo` cresce a peça no sentido do -Y em vez do +Y.
##
## POR QUE ISTO EXISTE, E POR QUE NÃO É UM `rotate_x(PI)`. Braço,
## antebraço, coxa e canela apontam para BAIXO, e a saída óbvia seria
## montá-los para cima e virar o nó meia volta. Só que meia volta em X
## também inverte o Z — e a pose de guarda e as nove animações são
## escritas em ângulos que contam com o Z apontando para a frente. Virar
## o nó faria a guarda fechar para trás e o joelho dobrar ao contrário, e
## o conserto seria trocar o sinal de cada número à mão, para sempre.
##
## Crescendo a geometria para baixo, o nó fica sem rotação nenhuma e cada
## ângulo de animação quer dizer exatamente o que está escrito nele.
static func tubo(
	comprimento: float, perfil: Array, achatamento := 1.0,
	deslocamento := Vector3.ZERO, curva := 0.0, para_baixo := false
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var indices := PackedInt32Array()
	var sentido := -1.0 if para_baixo else 1.0

	var aneis := perfil.size()
	for a in range(aneis):
		var passo: Vector2 = perfil[a]
		var altura := passo.x * comprimento * sentido
		var raio := passo.y
		# A INCLINAÇÃO DO PERFIL É A NORMAL. Num ponto onde o raio está
		# crescendo, a superfície se inclina para fora; onde está caindo,
		# para dentro. É esta conta — e não a média dos triângulos — que
		# faz o bíceps ter um ombro de luz contínuo em vez de uma faixa.
		var inclinacao := 0.0
		if a > 0 and a < aneis - 1:
			var antes: Vector2 = perfil[a - 1]
			var depois: Vector2 = perfil[a + 1]
			var dh := (depois.x - antes.x) * comprimento * sentido
			if absf(dh) > 0.0001:
				inclinacao = (depois.y - antes.y) / dh
		# A curva lateral (um arco suave ao longo da peça) tira o ar de
		# cano reto de coxa e antebraço.
		var arco := sin(passo.x * PI) * curva
		for i in range(LADOS):
			var ang := TAU * float(i) / float(LADOS)
			var cx := cos(ang)
			var cz := sin(ang) * achatamento
			vertices.push_back(
				Vector3(cx * raio + arco, altura, cz * raio) + deslocamento * passo.x * sentido
			)
			# A normal do tubo: radial, corrigida pela inclinação do perfil.
			var n := Vector3(cx, -inclinacao, sin(ang) / maxf(achatamento, 0.05))
			normais.push_back(n.normalized())

	for a in range(aneis - 1):
		for i in range(LADOS):
			var j := (i + 1) % LADOS
			var b0 := a * LADOS + i
			var b1 := a * LADOS + j
			var b2 := (a + 1) * LADOS + j
			var b3 := (a + 1) * LADOS + i
			indices.append_array([b0, b1, b2, b0, b2, b3])

	# AS TAMPAS SÃO CALOTAS, E NÃO DISCOS. Um disco chapado na ponta de um
	# braço aparece como um corte de salame assim que a peça gira; uma
	# calota fecha o volume e é o que faz a junta parecer articulação.
	_calota(vertices, normais, indices, perfil, comprimento, achatamento, deslocamento, true, sentido)
	_calota(vertices, normais, indices, perfil, comprimento, achatamento, deslocamento, false, sentido)
	# ESPELHAR EM Y INVERTE A MÃO DOS TRIÂNGULOS. Crescer a peça para baixo
	# é um espelhamento, e um triângulo espelhado passa a ser visto por
	# trás: sem esta inversão o braço sumiria da tela, porque o motor
	# descarta as faces que dão as costas para a câmera.
	if para_baixo:
		for t in range(0, indices.size(), 3):
			var meio := indices[t + 1]
			indices[t + 1] = indices[t + 2]
			indices[t + 2] = meio
	return _montar(vertices, normais, indices)

## A calota de uma ponta: meia esfera achatada, com o raio do anel dali.
static func _calota(
	vertices: PackedVector3Array, normais: PackedVector3Array, indices: PackedInt32Array,
	perfil: Array, comprimento: float, achatamento: float,
	deslocamento: Vector3, no_topo: bool, sentido := 1.0
) -> void:
	var passo: Vector2 = perfil[perfil.size() - 1] if no_topo else perfil[0]
	var raio := passo.y
	if raio <= 0.001:
		return
	var base_y := passo.x * comprimento * sentido
	var centro := Vector3(0.0, base_y, 0.0) + deslocamento * passo.x * sentido
	var para_fora := sentido if no_topo else -sentido
	# Três anéis dão uma cúpula redonda o bastante; o quarto não aparece.
	var degraus := 3
	var inicio := vertices.size()
	for d in range(1, degraus + 1):
		var t := float(d) / float(degraus)
		var fi := t * PI * 0.5
		var r := raio * cos(fi)
		var h := raio * sin(fi) * para_fora * 0.82
		for i in range(LADOS):
			var ang := TAU * float(i) / float(LADOS)
			vertices.push_back(centro + Vector3(cos(ang) * r, h, sin(ang) * r * achatamento))
			normais.push_back(
				Vector3(cos(ang) * cos(fi), sin(fi) * para_fora, sin(ang) * cos(fi)).normalized()
			)
	# Costura o primeiro anel da calota ao último anel do tubo.
	var anel_do_tubo := (perfil.size() - 1) * LADOS if no_topo else 0
	for i in range(LADOS):
		var j := (i + 1) % LADOS
		var a0 := anel_do_tubo + i
		var a1 := anel_do_tubo + j
		var c0 := inicio + i
		var c1 := inicio + j
		if no_topo:
			indices.append_array([a0, a1, c1, a0, c1, c0])
		else:
			indices.append_array([a1, a0, c0, a1, c0, c1])
	for d in range(degraus - 1):
		for i in range(LADOS):
			var j := (i + 1) % LADOS
			var b0 := inicio + d * LADOS + i
			var b1 := inicio + d * LADOS + j
			var b2 := inicio + (d + 1) * LADOS + j
			var b3 := inicio + (d + 1) * LADOS + i
			if no_topo:
				indices.append_array([b0, b1, b2, b0, b2, b3])
			else:
				indices.append_array([b1, b0, b3, b1, b3, b2])

## UMA ESFERA ACHATADA NOS TRÊS EIXOS — cabeça, luva, ombro, peitoral.
##
## `escala` deforma a esfera em cada eixo, e é assim que a mesma função
## entrega uma cabeça (quase redonda), uma luva (mais funda que alta) e um
## peitoral (largo e raso).
static func esfera(raio: float, escala := Vector3.ONE, paralelos := 10) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var indices := PackedInt32Array()
	for p in range(paralelos + 1):
		var fi := PI * float(p) / float(paralelos)
		var y := cos(fi)
		var r := sin(fi)
		for i in range(LADOS):
			var ang := TAU * float(i) / float(LADOS)
			var n := Vector3(cos(ang) * r, y, sin(ang) * r)
			vertices.push_back(n * raio * escala)
			# Numa esfera deformada a normal NÃO é a direção do vértice:
			# ela é a direção dividida pela escala. Sem isto o sombreado
			# de uma cabeça achatada mente sobre a forma dela.
			normais.push_back(
				Vector3(n.x / escala.x, n.y / escala.y, n.z / escala.z).normalized()
			)
	for p in range(paralelos):
		for i in range(LADOS):
			var j := (i + 1) % LADOS
			var b0 := p * LADOS + i
			var b1 := p * LADOS + j
			var b2 := (p + 1) * LADOS + j
			var b3 := (p + 1) * LADOS + i
			indices.append_array([b0, b3, b2, b0, b2, b1])
	return _montar(vertices, normais, indices)

## UMA LÂMINA: o espeto do cabelo, a sobrancelha, a listra do calção.
##
## Uma pirâmide de base retangular que afina até quase um fio. É a forma
## que dá cabelo de anime sem uma malha de cabelo de verdade.
static func espeto(base: Vector2, comprimento: float, ponta := 0.12) -> ArrayMesh:
	var perfil := [
		Vector2(0.0, 1.0), Vector2(0.35, 0.86), Vector2(0.72, 0.48), Vector2(1.0, ponta),
	]
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var indices := PackedInt32Array()
	var cantos := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for a in range(perfil.size()):
		var passo: Vector2 = perfil[a]
		for c in range(4):
			var canto: Vector2 = cantos[c]
			vertices.push_back(Vector3(
				canto.x * base.x * 0.5 * passo.y,
				passo.x * comprimento,
				canto.y * base.y * 0.5 * passo.y
			))
			normais.push_back(Vector3(canto.x, 0.45, canto.y).normalized())
	for a in range(perfil.size() - 1):
		for c in range(4):
			var d := (c + 1) % 4
			var b0 := a * 4 + c
			var b1 := a * 4 + d
			var b2 := (a + 1) * 4 + d
			var b3 := (a + 1) * 4 + c
			indices.append_array([b0, b1, b2, b0, b2, b3])
	# A base fechada, para o espeto não ficar oco visto de baixo.
	indices.append_array([0, 2, 1, 0, 3, 2])
	return _montar(vertices, normais, indices)

static func _montar(
	vertices: PackedVector3Array, normais: PackedVector3Array, indices: PackedInt32Array
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normais
	arrays[Mesh.ARRAY_INDEX] = indices
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha

## ------------------------------------------------------------------
## FUNDIR AS PEÇAS QUE NÃO SE MEXEM SOZINHAS.
##
## O PROBLEMA QUE ISTO RESOLVE É DE CHAMADA DE DESENHO, E NÃO DE
## TRIÂNGULO. O corpo montado tem sessenta e três peças. Dezessete mil
## triângulos é pouco para qualquer GPU deste século — mas sessenta e três
## peças viram sessenta e três chamadas de desenho, e cada uma volta a
## cento e vinte e seis por causa da passada do contorno. Chamada de
## desenho é trabalho de PROCESSADOR, é o que uma TV Box tem de pior, e é
## exatamente o tipo de custo que aparece como engasgo e não como queda
## suave de quadros.
##
## E a maioria dessas peças nunca se mexe em relação ao seu dono: o olho
## não anda sem a cabeça, a luva não anda sem o antebraço, a bota não anda
## sem a canela. Só onze nós têm movimento próprio — os que as animações
## citam. Todo o resto pode ser costurado dentro do nó que o carrega, de
## uma vez, na montagem.
##
## A COR PASSA A VIAJAR NO VÉRTICE. Era o que impedia a fusão: cada peça
## tinha a sua cor no material, e material diferente é chamada diferente
## por definição. Pintando a cor em cada vértice, cabeça, cabelo, olhos,
## sobrancelhas, nariz, boca, lábio, queixo e sete espetos cabem numa
## superfície só — e o sombreado de desenho continua igual, porque ele
## multiplica a cor do vértice em vez de ler um uniforme por peça.
##
## Resultado: de 126 chamadas para 22.

## Costura, dentro de cada nó de `juntas`, todas as peças penduradas nele
## que não pertencem a outra junta. As peças fundidas ficam sem malha —
## continuam existindo como nós (nada procura por elas em vão) e não
## custam mais nenhum desenho.
static func fundir(raiz: Node3D, juntas: Array) -> void:
	var conjunto := {}
	for nome in juntas:
		conjunto[str(nome)] = true
	for nome in juntas:
		var no := raiz.find_child(str(nome), true, false)
		if not (no is MeshInstance3D):
			continue
		var vertices := PackedVector3Array()
		var normais := PackedVector3Array()
		var cores := PackedColorArray()
		var traco := PackedVector2Array()
		var indices := PackedInt32Array()
		_colher(no as Node3D, Transform3D.IDENTITY, vertices, normais, cores, traco, indices, conjunto, true)
		if vertices.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normais
		arrays[Mesh.ARRAY_COLOR] = cores
		arrays[Mesh.ARRAY_TEX_UV] = traco
		arrays[Mesh.ARRAY_INDEX] = indices
		var malha := ArrayMesh.new()
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		(no as MeshInstance3D).mesh = malha
		# A cor do material passa a ser branca porque agora ela está no
		# vértice. O traço do contorno é dito à parte: ele é UM por peça
		# fundida, e puxar para a cor dominante da junta é o que ilustrador
		# faz — um preto só, igual para tudo, achata a figura.
		var dominante: Color = no.get_meta("cor", Color(0.9, 0.62, 0.42))
		no.set_meta("cor", Color.WHITE)
		no.set_meta("cor_traco", dominante.darkened(0.86))

## QUAL PEÇA MERECE CONTORNO, EM METROS.
##
## O contorno é uma casca inflada um centímetro e meio, e isso é ótimo
## para a silhueta e péssimo para detalhe pequeno: a casca do olho fica
## maior que o olho, escapa por fora da pele e aparece como um risco
## preto solto no meio da cara. No primeiro render do rosto eram dezenas
## deles — teias pretas em volta do olho, do nariz e da boca. Peça abaixo
## deste tamanho não é silhueta de nada, e já vem contornada pela sombra
## do que está em volta.
const CONTORNO_A_PARTIR_DE := 0.13

static func _colher(
	no: Node3D, ate_aqui: Transform3D,
	vertices: PackedVector3Array, normais: PackedVector3Array,
	cores: PackedColorArray, traco: PackedVector2Array, indices: PackedInt32Array,
	juntas: Dictionary, eh_a_raiz: bool
) -> void:
	if not eh_a_raiz and juntas.has(String(no.name)):
		return
	if no is MeshInstance3D and (no as MeshInstance3D).mesh != null:
		var malha: Mesh = (no as MeshInstance3D).mesh
		var cor: Color = no.get_meta("cor", Color.WHITE)
		# CADA VÉRTICE LEVA DUAS COISAS NA COORDENADA DE TEXTURA:
		#
		#   .x  se a peça dele entra na casca do contorno;
		#   .y  quanto a peça BRILHA.
		#
		# A segunda é a que separa couro de pele. Depois da fusão não
		# existe mais "peça" nenhuma — cabeça, cabelo, olhos e sete
		# espetos são uma superfície só —, então não há material por peça
		# onde guardar isso. No vértice, há. É o que permite a luva
		# vermelha ter o estouro de luz de couro envernizado enquanto a
		# pele ao lado dela tem só um realce macio, na MESMA chamada de
		# desenho.
		var tamanho := malha.get_aabb().size
		var contornar := 1.0 if maxf(tamanho.x, maxf(tamanho.y, tamanho.z)) > CONTORNO_A_PARTIR_DE else 0.0
		var brilho: float = no.get_meta("brilho", 0.3)
		for s in range(malha.get_surface_count()):
			var arrays := malha.surface_get_arrays(s)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var base := vertices.size()
			for i in range(v.size()):
				traco.push_back(Vector2(contornar, brilho))
				vertices.push_back(ate_aqui * v[i])
				# A NORMAL GIRA, MAS NÃO ANDA. Somar a translação junto
				# seria apontar todas as normais para o mesmo canto do
				# ringue, e o corpo inteiro sairia com a luz errada.
				normais.push_back((ate_aqui.basis * n[i]).normalized())
				cores.push_back(cor)
			for i in range(idx.size()):
				indices.push_back(base + idx[i])
		if not eh_a_raiz:
			(no as MeshInstance3D).mesh = null
	for filho in no.get_children():
		if filho is Node3D:
			_colher(
				filho as Node3D, ate_aqui * (filho as Node3D).transform,
				vertices, normais, cores, traco, indices, juntas, false
			)
