extends SceneTree

## A ARENA SOB TESTE.
##
## Tudo aqui nasceu de um erro que a tela de verdade cometeu e que
## nenhum teste antigo pegaria — porque nenhum teste antigo sabia que
## existia um mundo 3D. Os dois piores:
##
##   • o nocaute AFUNDAVA o lutador. A queda baixava o corpo 62 cm além
##     de tombá-lo, e como o nó raiz já fica na altura da lona, o boneco
##     saía por baixo do ringue: a moldura mostrava um ringue vazio no
##     momento mais importante do jogo.
##   • a janela 3D e o buraco da moldura tinham proporções diferentes, e
##     a imagem chegava esticada na tela — o tipo de coisa que ninguém vê
##     olhando o código e que salta aos olhos na máquina.
##
## Os dois viraram teste. Os demais guardam as regras que a arena promete
## ao resto do jogo: dano que só sobe dentro da rodada, frase que não
## troca sozinha, som que existe de verdade no disco.



var falhas := 0

func _ok(condicao: bool, o_que: String) -> void:
	if not condicao:
		falhas += 1
		print("FALHOU: %s" % o_que)

func _perto(a: float, b: float, folga: float, o_que: String) -> void:
	_ok(absf(a - b) <= folga, "%s (%.4f vs %.4f)" % [o_que, a, b])

func _initialize() -> void:
	_test_o_lutador_nasce_completo()
	_test_o_corpo_e_um_atleta()
	_test_o_corpo_custa_pouco_para_desenhar()
	_test_a_janela_tem_a_proporcao_do_buraco()
	_test_as_barras_cabem_na_moldura()
	_test_a_postura_parada_se_repete()
	_test_a_reacao_dura_o_que_a_animacao_dura()
	_test_o_dano_soma_e_nao_passa_de_um()
	_test_cada_forca_tem_reacao_propria()
	_test_desdenho_usa_a_nota_e_respeita_a_lona()
	_test_o_nocaute_derruba_de_verdade()
	_test_o_nocaute_nao_afunda_o_lutador()
	_test_levantar_devolve_o_lutador_para_cima_da_lona()
	_test_preparar_desfaz_a_pose_do_tombo()
	_test_as_frases_cobrem_todos_os_niveis()
	_test_a_frase_nao_troca_sozinha()
	_test_os_sons_da_arena_existem()
	_test_a_arena_so_liga_nas_telas_do_soco()
	if falhas == 0:
		print("ARENA_OK")
	quit(1 if falhas > 0 else 0)

# ------------------------------------------------------------- o lutador
## O LUTADOR NASCE INTEIRO, SEM ARQUIVO NENHUM.
##
## Antes o corpo vinha de `assets/personagem/lutador.glb`, gerado por um
## script em Python. Isso queria dizer duas coisas ruins: o jogo podia
## chegar ao salão sem o boneco dentro, e ajustar uma proporção exigia
## Python e Blender na máquina de quem mexesse. Agora ele é montado em
## GDScript (`LutadorNativo`) e não há arquivo para faltar — mas há um
## contrato novo a guardar: as nove ações precisam existir mesmo assim.
func _test_o_lutador_nasce_completo() -> void:
	var controle := _lutador()
	var animacoes := controle.animacoes_disponiveis()
	for nome in Lutador3D.ALIASES:
		_ok(nome in animacoes, "o lutador precisa da ação %s" % nome)
	_ok(controle.completo(), "o lutador tem de nascer com o contrato inteiro")
	controle.free()

## A SILHUETA É O PERSONAGEM, e ela é conferível em números.
##
## A queixa que originou esta reformulação foi "está parecendo um
## gordinho". O boneco anterior tinha ombro de 0,50 m e cintura de 0,38:
## um e pouco para um, que é a proporção de um barril e nenhuma
## iluminação conserta. Estes números são os que fazem a figura ler como
## atleta a três metros da máquina, e um ajuste que os quebre tem de
## falhar aqui e não no salão.
func _test_o_corpo_e_um_atleta() -> void:
	var corpo := LutadorNativo.montar()
	var ombro_e := corpo.find_child("Ombro_E", true, false) as Node3D
	var ombro_d := corpo.find_child("Ombro_D", true, false) as Node3D
	var largura_do_ombro := absf(ombro_d.position.x - ombro_e.position.x)
	var cintura := 0.0
	for passo in LutadorNativo.P_TRONCO:
		cintura = (passo as Vector2).y if cintura == 0.0 else minf(cintura, (passo as Vector2).y)
	var peito := 0.0
	for passo in LutadorNativo.P_TRONCO:
		peito = maxf(peito, (passo as Vector2).y)
	_ok(peito / cintura > 1.8, "o tronco precisa do V (peito %.3f / cintura %.3f)" % [peito, cintura])
	_ok(largura_do_ombro > peito * 2.0,
		"o ombro precisa passar da caixa torácica (%.3f vs %.3f)" % [largura_do_ombro, peito * 2.0])
	# E O QUADRIL NÃO PODE SER MAIS LARGO QUE O PEITO. Enquanto foi, a
	# silhueta era uma pera por mais músculo que o tronco tivesse — e foi
	# esse o defeito que sobreviveu à primeira reformulação inteira.
	var quadril := 0.0
	for passo in LutadorNativo.P_QUADRIL:
		quadril = maxf(quadril, (passo as Vector2).y)
	_ok(quadril < peito, "o quadril não pode ser mais largo que o peito (%.3f vs %.3f)" % [quadril, peito])
	# A LUVA É PROPORCIONAL AO PUNHO, e não à cabeça: luva do tamanho da
	# cabeça é linguagem de desenho infantil e ainda escondia o rosto
	# inteiro na guarda.
	var luva := corpo.find_child("Luva_D", true, false) as MeshInstance3D
	var cabeca := corpo.find_child("Cabeca", true, false) as MeshInstance3D
	_ok(luva != null and cabeca != null, "luva e cabeça têm de existir")

	# QUANTAS CABEÇAS DE ALTURA — a medida que separa um herói de um
	# boneco de Olinda, que foi a queixa exata que veio do operador.
	#
	# O boneco gigante do carnaval é uma cabeça enorme sobre um corpo
	# pequeno; herói de anime adulto tem oito cabeças ou mais. Duas
	# versões seguidas deste lutador caíram em 6,5 e 7,4, e nas duas a
	# figura saiu infantil por mais músculo que o corpo tivesse. A
	# proporção é a primeira coisa que o olho lê, antes do rosto e antes
	# da pose, e por isso ela é teste e não gosto.
	var alto := _alto_do_corpo(corpo)
	var cabecas := alto / (LutadorNativo.RAIO_DA_CABECA * 2.0 * 1.09)
	_ok(cabecas >= 7.8, "o corpo precisa de 7,8 cabeças ou mais (tem %.1f)" % cabecas)
	_ok(cabecas <= 9.0, "acima de nove cabeças a figura vira caricatura magra (%.1f)" % cabecas)
	corpo.free()

## A altura do ponto mais alto do corpo acima da lona, varrendo as peças.
func _alto_do_corpo(raiz: Node3D) -> float:
	var teto := 0.0
	for malha in _todas_as_malhas(raiz):
		if malha.mesh == null:
			continue
		var caixa := malha.mesh.get_aabb()
		teto = maxf(teto, _onde(raiz, malha).y + caixa.position.y + caixa.size.y)
	return teto

## O CORPO INTEIRO CABE EM POUCAS CHAMADAS DE DESENHO.
##
## Sessenta e três peças soltas seriam sessenta e três chamadas, e cento e
## vinte e seis com a passada do contorno. Chamada de desenho é trabalho
## de processador, é o que uma TV Box tem de pior, e aparece como engasgo
## e não como queda suave de quadros. `Figura.fundir` costura tudo o que
## não se mexe sozinho dentro da junta que o carrega.
func _test_o_corpo_custa_pouco_para_desenhar() -> void:
	var corpo := LutadorNativo.montar()
	var desenhos := 0
	for malha in _todas_as_malhas(corpo):
		if malha.mesh != null:
			desenhos += malha.mesh.get_surface_count()
	_ok(desenhos <= 14, "o corpo não pode passar de 14 chamadas de desenho (são %d)" % desenhos)
	_ok(desenhos >= LutadorNativo.JUNTAS_MOVEIS.size(),
		"cada junta com movimento próprio precisa da sua malha")
	corpo.free()

func _todas_as_malhas(no: Node) -> Array[MeshInstance3D]:
	var achadas: Array[MeshInstance3D] = []
	if no is MeshInstance3D:
		achadas.append(no as MeshInstance3D)
	for filho in no.get_children():
		achadas.append_array(_todas_as_malhas(filho))
	return achadas

# -------------------------------------------------------------- moldura
func _test_a_janela_tem_a_proporcao_do_buraco() -> void:
	var buraco := ArenaQuadro.TELA.size.x / ArenaQuadro.TELA.size.y
	for tamanho in [Arena3D.TAMANHO_CHEIO, Arena3D.TAMANHO_MAGRO]:
		var janela := float(tamanho.x) / float(tamanho.y)
		_perto(janela, buraco, 0.01, "a janela 3D %s tem de ter a proporção do buraco da moldura" % tamanho)

func _test_as_barras_cabem_na_moldura() -> void:
	# As colunas ficam FORA da moldura e DENTRO da tela. Encostar numa
	# coisa ou sair da outra é o tipo de deslize que só aparece quando o
	# gabinete já está montado.
	_ok(ArenaQuadro.BARRA_E.end.x < ArenaQuadro.MOLDURA.position.x, "a coluna esquerda não pode invadir a moldura")
	_ok(ArenaQuadro.BARRA_D.position.x > ArenaQuadro.MOLDURA.end.x, "a coluna direita não pode invadir a moldura")
	_ok(ArenaQuadro.BARRA_E.position.x > 0.0, "a coluna esquerda não pode sair da tela")
	_ok(ArenaQuadro.BARRA_D.end.x < 1080.0, "a coluna direita não pode sair da tela")
	# E o buraco tem de estar inteiro dentro da moldura, senão a imagem
	# vaza por cima da borda.
	_ok(ArenaQuadro.MOLDURA.encloses(ArenaQuadro.TELA), "o buraco tem de caber na moldura")

# ------------------------------------------------------------- o corpo
func _lutador() -> Lutador3D:
	var l := Lutador3D.new()
	l.montar(LutadorNativo.montar())
	l.preparar()
	return l

## O TOCADOR SÓ ANDA SOZINHO DENTRO DA ÁRVORE. Fora dela — que é onde um
## teste vive — `advance` dá exatamente o passo que o motor daria, e é o
## que permite medir a pose de um gesto sem subir a cena inteira.
func _correr(l: Lutador3D, quadros: int) -> void:
	for i in range(quadros):
		l.atualizar(1.0 / 60.0)
		if l._animador != null:
			l._animador.advance(1.0 / 60.0)

## A POSTURA PARADA TEM DE SE REPETIR, E NÃO RECOMEÇAR.
##
## O glTF não guarda modo de repetição, então o importador marca toda
## animação como tocar-uma-vez — inclusive `idle`, de três segundos, e
## `guard`, de dois. Elas acabavam, paravam, e no quadro seguinte o
## controlador via que não estavam mais rodando e mandava tocar de novo
## DO COMEÇO, com 0,2 s de mistura: um solavanco a cada ciclo, para
## sempre, na tela em que o jogador mais olha para o boneco. Era a maior
## parte do "o personagem não se mexe natural".
##
## Este teste é a única defesa possível, porque o defeito não aparece em
## quadro nenhum isolado — só em quem fica olhando alguns segundos.
func _test_a_postura_parada_se_repete() -> void:
	for papel in Lutador3D.PAPEIS_CONTINUOS:
		var l := _lutador()
		var ap: AnimationPlayer = l._animador
		if ap == null or not l._animacoes.has(papel):
			l.free()
			continue
		var anim := ap.get_animation(l._animacoes[papel])
		_ok(anim.loop_mode == Animation.LOOP_LINEAR,
			"a postura %s tem de ser marcada como contínua" % papel)
		l.free()
	# E os gestos são o contrário: repetir um soco levado vira tique.
	var g := _lutador()
	for papel in ["hit_light", "hit_heavy", "stagger", "knockout", "taunt_weak", "get_up"]:
		if not g._animacoes.has(papel):
			continue
		var anim := (g._animador as AnimationPlayer).get_animation(g._animacoes[papel])
		_ok(anim.loop_mode == Animation.LOOP_NONE, "o gesto %s não pode se repetir" % papel)
	g.free()

## A REAÇÃO DURA O QUE A ANIMAÇÃO DURA.
##
## As durações eram uma tabela escrita à mão, e TODAS curtas: `stagger`
## anotado como 1,35 s dura 1,53; `taunt_weak` anotado como 1,18 dura
## 1,40. O relógio acabava antes do gesto e a volta para a guarda
## começava no meio do movimento. E como `bater` toca mais rápido ou mais
## devagar conforme a força, nenhuma tabela fixa poderia ter acertado.
func _test_a_reacao_dura_o_que_a_animacao_dura() -> void:
	var l := _lutador()
	var ap: AnimationPlayer = l._animador
	if ap == null:
		l.free()
		return
	for papel in ["hit_light", "hit_medium", "hit_heavy", "stagger", "taunt_weak"]:
		if not l._animacoes.has(papel):
			continue
		var comprimento := ap.get_animation(l._animacoes[papel]).length
		_perto(l._duracao(papel, 1.0), comprimento, 0.001,
			"a duração de %s tem de sair da animação" % papel)
	# Tocada mais rápido, a reação acaba antes — e o controlador precisa
	# saber disso, senão fica esperando parado no fim do gesto.
	_ok(l._duracao("stagger", 1.10) < l._duracao("stagger", 1.0),
		"a duração tem de acompanhar a velocidade de reprodução")
	# E um papel que não existe no arquivo ainda tem um tempo razoável:
	# um GLB incompleto não pode travar o lutador para sempre.
	var ausente := l._duracao("nao_existe_este_papel", 1.0)
	_ok(ausente > 0.2 and ausente < 3.0, "papel ausente precisa de uma duração de reserva")
	l.free()

func _test_o_dano_soma_e_nao_passa_de_um() -> void:
	var l := _lutador()
	_ok(l.dano == 0.0, "o lutador começa a rodada inteiro")
	l.bater(0.30)
	var depois_de_um := l.dano
	_ok(depois_de_um > 0.0, "um soco de verdade tem de marcar o adversário")
	l.bater(0.30)
	_ok(l.dano > depois_de_um, "o segundo soco soma em cima do primeiro")
	for i in range(10):
		l.bater(1.0)
	_ok(l.dano <= 1.0, "o medidor de dano não pode passar de 100%")
	# Um tapa não conta: sem este piso, o ruído do sensor encheria a barra
	# sozinho ao longo de uma noite.
	l.preparar()
	l.bater(0.005)
	_ok(l.dano == 0.0, "golpe abaixo do mínimo não marca dano")
	l.free()

func _test_cada_forca_tem_reacao_propria() -> void:
	var casos := {
		0.05: "taunt_weak", 0.20: "hit_light", 0.45: "hit_medium",
		0.68: "hit_heavy", 0.90: "stagger",
	}
	for forca in casos:
		_ok(Lutador3D.reacao_para_forca(forca) == casos[forca],
			"força %.2f precisa tocar %s" % [forca, casos[forca]])

func _test_desdenho_usa_a_nota_e_respeita_a_lona() -> void:
	_ok(Lutador3D.reacao_para_pontos(5999, 0.72) == "taunt_weak",
		"abaixo de 6.000 o adversário precisa desdenhar mesmo com força física")
	_ok(Lutador3D.reacao_para_pontos(6000, 0.72) == "hit_heavy",
		"6.000 já usa a reação física normal")
	_ok(Lutador3D.reacao_para_pontos(6000, 0.02) == "hit_light",
		"a partir de 6.000 o adversário não pode desdenhar")
	var l := _lutador()
	var ko := l.bater(1.0, true, 9500)
	_ok(bool(ko["nocaute"]), "golpe forte precisa derrubar")
	var no_chao := l.bater(0.10, false, 2000)
	_ok(not bool(no_chao["desdenhou"]), "quem está na lona não pode desdenhar")
	l.free()

## O NOCAUTE PRECISA DERRUBAR.
##
## Medido osso a osso: durante a animação `knockout` que veio no GLB, a
## cabeça do lutador sai de 1,59 m para 1,63 m e anda doze centímetros
## para trás. Ele não cai — inclina e volta. E o jogo inteiro acreditava:
## tocava o som de queda, anunciava NOCAUTE, gritava a torcida, levava a
## câmera para a altura da lona e esperava 3,35 s "no chão" com o boneco
## em pé o tempo todo.
##
## A queda passou a ser feita no osso-raiz (`Lutador3D._aplicar_queda`).
## Este teste guarda as duas coisas que aquilo precisa cumprir, e nenhuma
## delas dá para ver num quadro isolado.
func _test_o_nocaute_derruba_de_verdade() -> void:
	var l := _lutador()
	var corpo := l.get_child(0) as Node3D
	var cabeca := corpo.find_child("Cabeca", true, false) as Node3D
	var em_pe := _altura(corpo, cabeca)
	l.bater(1.0, true, 9600)
	_correr(l, 130)
	_ok(l.queda > 0.9, "depois do nocaute o lutador tem de estar no chão")
	var deitado := _altura(corpo, cabeca)
	# A CABEÇA TEM DE CHEGAR PERTO DA LONA. Não basta inclinar: o boneco
	# antigo movia a cabeça quatro centímetros e voltava, enquanto o jogo
	# tocava som de queda, anunciava NOCAUTE e levava a câmera para a
	# altura do tapete — o momento mais importante da partida era a
	# câmera olhando para um pedaço vazio de lona.
	_ok(deitado < 0.55,
		"a cabeça tem de ir ao chão (de %.2f m para %.2f m)" % [em_pe, deitado])
	_ok(deitado > 0.02, "e não pode atravessar a lona (%.2f m)" % deitado)

	# E A POSE NÃO PODE SE ACUMULAR.
	#
	# A primeira versão lia a pose e multiplicava o giro nela a cada
	# quadro. Enquanto a animação toca ela reescreve a pose antes de cada
	# acréscimo e nada aparece; mas a animação de nocaute dura 1,93 s e
	# NÃO SE REPETE, e quando ela acaba ninguém mais reescreve a pose: o
	# mesmo giro passa a ser multiplicado sessenta vezes por segundo em
	# cima de si mesmo. O lutador dava voltas e sumia do ringue em meio
	# segundo.
	#
	# Aqui a queda é fixada e a função chamada duzentas vezes seguidas,
	# sem o resto do quadro no meio: com a pose escrita de forma absoluta
	# a partir da pose guardada, chamar uma vez ou duzentas dá no mesmo.
	# Com a versão que acumulava, isto gira mais de mil graus.
	l.queda = 1.0
	l._aplicar_queda()
	var uma_vez := _altura(corpo, cabeca)
	for i in range(200):
		l.queda = 1.0
		l._aplicar_queda()
	_perto(_altura(corpo, cabeca), uma_vez, 0.001,
		"a pose da queda tem de ser absoluta, e não somar a cada chamada")
	l.free()

## A altura de uma peça acima da lona, somando as juntas até a raiz — o
## `global_position` não serve, porque o corpo de teste não está na
## árvore da cena.
func _altura(raiz: Node3D, no: Node3D) -> float:
	var t := Transform3D.IDENTITY
	var atual := no
	while atual != null and atual != raiz:
		t = atual.transform * t
		atual = atual.get_parent() as Node3D
	return (raiz.transform * t).origin.y

func _test_o_nocaute_nao_afunda_o_lutador() -> void:
	var l := _lutador()
	var reacao := l.bater(1.0, true)
	_ok(bool(reacao["nocaute"]), "um nível que derruba tem de derrubar no primeiro soco")
	_correr(l, 130)
	_ok(l.queda > 0.9, "depois de dois segundos ele tem de estar na lona")
	var corpo := l.get_child(0) as Node3D
	# ESTA É A LINHA QUE O ERRO ORIGINAL QUEBRAVA. O corpo caído tem de
	# continuar POR CIMA da lona e dentro do enquadramento da câmera — não
	# debaixo do ringue, que foi onde ele foi parar.
	for nome in ["Cabeca", "Quadril", "Luva_E", "Luva_D"]:
		var peca := corpo.find_child(str(nome), true, false) as Node3D
		if peca == null:
			continue
		var onde := _onde(corpo, peca)
		_ok(onde.y > -0.10, "%s não pode afundar na lona (y=%.2f)" % [nome, onde.y])
		_ok(absf(onde.x) < 1.2, "%s não pode sair de lado do quadro (x=%.2f)" % [nome, onde.x])
		_ok(onde.z > -1.6, "%s não pode ir para trás das cordas (z=%.2f)" % [nome, onde.z])
	l.free()

func _onde(raiz: Node3D, no: Node3D) -> Vector3:
	var t := Transform3D.IDENTITY
	var atual := no
	while atual != null and atual != raiz:
		t = atual.transform * t
		atual = atual.get_parent() as Node3D
	return (raiz.transform * t).origin

func _test_levantar_devolve_o_lutador_para_cima_da_lona() -> void:
	var l := _lutador()
	var corpo := l.get_child(0) as Node3D
	var cabeca := corpo.find_child("Cabeca", true, false) as Node3D
	var em_pe := _altura(corpo, cabeca)
	l.bater(1.0, true)
	# Queda, contagem e volta: seis segundos cobrem o ciclo inteiro.
	_correr(l, 400)
	_ok(l.queda <= 0.001, "ele tem de levantar sozinho para o próximo soco")
	_ok(l.dano < 1.0, "quem levanta volta com fôlego para levar o segundo soco")
	_perto(_altura(corpo, cabeca), em_pe, 0.06, "de pé, a cabeça volta à altura de antes")
	l.free()

## E A RODADA SEGUINTE COMEÇA COM O CORPO INTEIRO NO LUGAR.
##
## Uma rodada pode ACABAR com o adversário no chão, e as faixas de
## `knockout` deixam joelho e cotovelo dobrados na última pose. O clipe
## `idle` não tem faixa de perna nenhuma: sem devolver a pose de
## nascimento, o jogador seguinte encontraria um lutador de pé com as
## pernas ainda dobradas do tombo anterior — e assim a noite inteira.
func _test_preparar_desfaz_a_pose_do_tombo() -> void:
	var l := _lutador()
	var corpo := l.get_child(0) as Node3D
	var joelho := corpo.find_child("Canela_D", true, false) as Node3D
	var antes := joelho.rotation
	l.bater(1.0, true)
	_correr(l, 80)
	_ok(joelho.rotation.distance_to(antes) > 0.2, "o tombo tem de dobrar o joelho")
	l.preparar()
	_perto(joelho.rotation.distance_to(antes), 0.0, 0.001,
		"a rodada seguinte começa com o corpo no lugar")
	l.free()

# ------------------------------------------------------------- frases
func _test_as_frases_cobrem_todos_os_niveis() -> void:
	for nivel in ScoreTier.NIVEIS:
		var id := str(nivel["id"])
		_ok(ArenaFrases.GOLPES.has(id), "o nível %s precisa das frases dele" % id)
		var lista: Array = ArenaFrases.GOLPES.get(id, [])
		# Uma frase por nível vira rótulo; duas ou mais viram narrador.
		_ok(lista.size() >= 2, "o nível %s precisa de mais de uma frase" % id)
		for i in range(6):
			_ok(not ArenaFrases.de_golpe(id, i).is_empty(), "frase vazia no nível %s" % id)
	_ok(ArenaFrases.de_dano(0.0) == "INTEIRO", "sem dano, o adversário está inteiro")
	_ok(ArenaFrases.de_dano(1.0) == "POR UM FIO", "no talo, o adversário está por um fio")

func _test_a_frase_nao_troca_sozinha() -> void:
	# `_draw` roda sessenta vezes por segundo: a mesma semente TEM de
	# devolver a mesma frase, senão o texto pisca trocando de palavra
	# enquanto a pessoa lê.
	var primeira := ArenaFrases.de_golpe("NOCAUTE", 3)
	for i in range(20):
		_ok(ArenaFrases.de_golpe("NOCAUTE", 3) == primeira, "a frase não pode mudar com a mesma semente")

# --------------------------------------------------------------- som
func _test_os_sons_da_arena_existem() -> void:
	const Catalogo = preload("res://scripts/audio/audio_catalog.gd")
	for cue in [
		"arena_corpo", "arena_queda", "arena_publico",
		"torcida_desdenho",
		"torcida_recorde", "torcida_podio", "torcida_top10", "torcida_top20",
	]:
		_ok(cue in Catalogo.EXTRA, "%s tem de estar no catálogo" % cue)
		var caminho: String = Catalogo.path_for(cue)
		_ok(ResourceLoader.exists(caminho) or FileAccess.file_exists(caminho),
			"o arquivo de %s tem de existir" % cue)
	# O baque do corpo divide o barramento do soco: se ele caísse em SFX,
	# o controle de volume dos efeitos o abafaria junto com os bipes.
	_ok(Catalogo.bus_for("arena_corpo") == "Impact", "o baque do corpo é som de impacto")
	_ok(Catalogo.bus_for("arena_queda") == "Impact", "a queda é som de impacto")

# ------------------------------------------------------------ ligação
func _test_a_arena_so_liga_nas_telas_do_soco() -> void:
	var jogo := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	get_root().add_child(jogo)
	jogo.intro_active = false
	jogo.central_aberta = false
	var esperado := {
		GameDef.State.IDLE: false,
		GameDef.State.COUNTDOWN: true,
		GameDef.State.ARMED: true,
		GameDef.State.MEASURING: true,
		GameDef.State.RESULT: true,
	}
	for estado in esperado:
		jogo.state = estado
		jogo.verdict_time = -1.0
		_ok(jogo._arena_no_ar() == esperado[estado], "arena ligada no estado %d" % estado)
	# Na tabela de recordes a moldura já saiu da tela: manter o mundo 3D
	# desenhando ali é gastar uma TV Box por nada.
	#
	# A TABELA É O FIM DA RODADA, e não um relógio solto: quem ainda tem
	# soco a dar continua vendo a arena. Enquanto a revelação começava no
	# mesmo instante em que o segundo soco era armado, os dois casos
	# davam no mesmo e ninguém precisou escolher; encurtar a revelação
	# separou os relógios. Ver `_tabela_no_ar`.
	jogo.state = GameDef.State.RESULT
	jogo.verdict_time = 3.0
	jogo.socos = [{"pontos": 5000, "velocidade": 3.0, "pico_g": 0.0, "duracao_ms": 9.0, "simulado": true}]
	_ok(jogo._arena_no_ar(), "no meio da rodada a arena continua no ar")
	jogo.rodada_encerrada_antecipadamente = true
	_ok(not jogo._arena_no_ar(), "a arena desliga quando a tabela de recordes entra")
	jogo.socos = []
	jogo.rodada_encerrada_antecipadamente = false
	jogo.verdict_time = -1.0
	jogo.central_aberta = true
	jogo.state = GameDef.State.ARMED
	_ok(not jogo._arena_no_ar(), "a arena desliga com a Central aberta")
	jogo.queue_free()
