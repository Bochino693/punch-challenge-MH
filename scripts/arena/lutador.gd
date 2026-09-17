class_name Lutador3D
extends Node3D

## Controlador do adversário humanoide. O contrato preferido é um GLB com
## Skeleton3D, skin e AnimationPlayer; a pose procedural existe somente como
## fallback para um asset externo incompleto.
##
## ------------------------------------------------------------------
## AS DUAS COISAS QUE FAZIAM O BONECO PARECER ARTIFICIAL.
##
## 1. NENHUMA ANIMAÇÃO DO GLB TINHA LOOP. O glTF não guarda essa
##    informação, e o Godot importa tudo como tocar-uma-vez. `idle` dura
##    três segundos: ele tocava, PARAVA, e no quadro seguinte
##    `_tocar("idle")` via que não estava mais rodando e mandava tocar de
##    novo — do começo, com meio quarto de segundo de mistura entre a
##    última pose e a primeira. Ou seja: a cada três segundos o lutador
##    dava um solavanco parado no lugar, para sempre, na tela em que o
##    jogador passa mais tempo olhando para ele. `_ajustar_loops` resolve
##    dizendo quais papéis são contínuos.
##
## 2. AS DURAÇÕES DAS REAÇÕES ERAM CHUTADAS À MÃO, e todas curtas demais.
##    `taunt_weak` foi anotado como 1,18 s e dura 1,40; `stagger`, 1,35
##    contra 1,53. O relógio acabava antes do gesto, a volta para a
##    guarda começava no meio do movimento, e o resultado é um boneco que
##    nunca termina o que começou. Pior: `bater` toca com velocidade
##    entre 0,92× e 1,12× conforme a força, o que muda a duração REAL e
##    nenhuma tabela à mão poderia acompanhar. Agora a duração é medida
##    da própria animação e dividida pela velocidade em que ela vai ser
##    tocada. A tabela sobrou só para o caso de o papel não existir no
##    arquivo.

const DANO_POR_GOLPE := 0.62
const DANO_MINIMO := 0.02
const TEMPO_NA_LONA := 3.35
## Só o padrão: quando o GLB traz `get_up`, vale o comprimento dela.
const TEMPO_LEVANTAR_PADRAO := 1.65

## OS PAPÉIS QUE SE REPETEM ENQUANTO NADA ACONTECE. Todo o resto é um
## gesto com começo e fim, e repetir um gesto desses seria o tique
## nervoso que uma máquina de salão não pode ter.
const PAPEIS_CONTINUOS := ["idle", "guard"]

## Quanto dura cada reação QUANDO A ANIMAÇÃO NÃO EXISTE no arquivo. Com
## ela, manda o comprimento medido. Ver o cabeçalho.
const DURACAO_PADRAO := {
	"taunt_weak": 1.18, "stagger": 1.35, "hit_heavy": 1.05,
	"hit_medium": 0.82, "hit_light": 0.58,
}

const JUNTAS := [
	"Quadril", "Tronco", "Cabeca", "Pescoco", "Ombro_E", "Ombro_D",
	"Antebraco_E", "Antebraco_D", "Luva_E", "Luva_D", "Coxa_E", "Coxa_D",
	"Canela_E", "Canela_D",
]

const ALIASES := {
	"idle": ["idle", "breathing_idle", "boxer_idle"],
	"guard": ["guard", "boxing_guard", "fighting_idle"],
	"taunt_weak": ["taunt_weak", "taunt", "mock", "disdain"],
	"hit_light": ["hit_light", "light_hit", "hit_reaction_1"],
	"hit_medium": ["hit_medium", "medium_hit", "hit_reaction_2"],
	"hit_heavy": ["hit_heavy", "heavy_hit", "hit_reaction_3"],
	"stagger": ["stagger", "stumble", "impact_heavy"],
	"knockout": ["knockout", "ko", "fall_back", "knock_down"],
	"get_up": ["get_up", "stand_up", "recover"],
}

## A CABEÇA DE DESENHO.
##
## O modelo veio com proporção realista: cabeça pequena, ombros largos,
## luvas enormes. Em pé na guarda, as duas luvas cobrem a cabeça inteira e
## o jogador nunca vê um rosto — e é impossível gostar de um personagem
## cujo rosto nunca aparece. Toda linguagem de desenho resolve isso do
## mesmo jeito, e é o mais barato que existe: cabeça maior.
##
## Um terço a mais basta. Acima disso o pescoço aparece fino demais e o
## boneco vira caricatura de si mesmo.
## A ESCULTURA: PROPORÇÃO DE ATLETA EM CIMA DO MODELO QUE EXISTE.
##
## A queixa foi "parece um gordinho". O modelo não tem gordura nenhuma —
## tem as PROPORÇÕES erradas para o personagem que a referência pede, e
## são três, cada uma bastando sozinha:
##
##   LUVA DO TAMANHO DA CABEÇA. É a mais forte de todas. Luva enorme é
##   linguagem de desenho infantil, e ainda escondia o rosto inteiro na
##   guarda — não dá para gostar de um personagem que nunca se vê.
##   CINTURA DA LARGURA DO PEITO. Sem o V do tronco, o corpo lê como um
##   retângulo, e retângulo lê como corpo mole por mais músculo que
##   tenha desenhado em cima.
##   CABEÇA PEQUENA. Proporção realista num boneco estilizado dá aquele
##   ar de action figure genérico.
##
## Regravar a malha exigiria Blender; reescalar OSSO não exige nada. E
## como a escala de um osso desce para os filhos, o V sai de duas linhas:
## afina a coluna (que leva o peito e os braços junto) e devolve a largura
## só nos OMBROS. Cintura fina, ombro largo, e nenhum vértice movido à mão.
##
## Tudo isto é aplicado DEPOIS da animação, todo quadro — ver
## `_esculpir`. O tocador reescreve a pose de cada osso a cada quadro, e
## um ajuste feito uma vez na montagem seria apagado no primeiro
## movimento.
const ESCALA_DA_CABECA := 1.16
const OSSO_DA_CABECA := "head"

## Cada entrada é `osso: escala`. Uniforme onde a peça inteira muda de
## tamanho; por eixo onde o que muda é a forma.
const ESCULTURA := {
	# As luvas encolhem um terço. A mais importante das três.
	"glove_l": Vector3(0.66, 0.66, 0.66),
	"glove_r": Vector3(0.66, 0.66, 0.66),
	# A cintura afina — e leva peito, braços e cabeça junto, porque escala
	# de osso desce para os filhos.
	"spine": Vector3(0.82, 1.05, 0.86),
	# …e os ombros devolvem a largura, só aí. É isto, e só isto, que
	# desenha o V.
	"shoulder_l": Vector3(1.26, 1.0, 1.16),
	"shoulder_r": Vector3(1.26, 1.0, 1.16),
	# O antebraço afina um pouco: braço de boxeador é grosso em cima e
	# fino embaixo, e era reto dos dois lados.
	"forearm_l": Vector3(0.92, 1.0, 0.92),
	"forearm_r": Vector3(0.92, 1.0, 0.92),
}

var _osso_cabeca := -1
var _escultura_indices: Dictionary = {}
var _juntas: Dictionary = {}
var _repouso: Dictionary = {}
var _raiz: Node3D = null
var _animador: AnimationPlayer = null
var _esqueleto: Skeleton3D = null
var _animacoes: Dictionary = {}
var _relogio := 0.0
var _recuo := 0.0
var _forca_do_recuo := 0.0
var _lado := 1.0
var _tempo_reacao := 0.0
var _tempo_na_lona := 0.0
var _tempo_levantar := TEMPO_LEVANTAR_PADRAO
var _levantando := false
var queda := 0.0
var _caindo := false
var dano := 0.0
var em_guarda := false

func montar(corpo: Node3D) -> void:
	_raiz = corpo
	add_child(corpo)
	_animador = _achar_animador(corpo)
	_esqueleto = _achar_esqueleto(corpo)
	_indexar_animacoes()
	_ajustar_loops()
	_osso_cabeca = _esqueleto.find_bone(OSSO_DA_CABECA) if _esqueleto != null else -1
	_dar_uma_boca()
	# Os índices são procurados UMA vez: `find_bone` percorre a lista de
	# ossos por nome, e isto roda em todo quadro.
	_escultura_indices.clear()
	if _esqueleto != null:
		for nome in ESCULTURA:
			var osso := _esqueleto.find_bone(str(nome))
			if osso >= 0:
				_escultura_indices[str(nome)] = osso
	_osso_raiz = _esqueleto.find_bone(OSSO_RAIZ) if _esqueleto != null else -1
	for nome in JUNTAS:
		var no := corpo.find_child(nome, true, false)
		if no is Node3D:
			_juntas[nome] = no
			_repouso[nome] = (no as Node3D).transform
	_repouso["__raiz__"] = corpo.transform

## A BOCA QUE O MODELO NUNCA TEVE.
##
## "Sem boca" foi a queixa, e é literal: o GLB traz olhos e sobrancelhas
## e para aí. Uma cabeça com dois olhos e mais nada não é um rosto — é um
## ovo —, e nenhuma quantidade de sombreamento conserta isso.
##
## Ela é pendurada no OSSO DA CABEÇA, com um `BoneAttachment3D`: assim
## acompanha cada virada de cabeça das nove animações sem que nenhuma
## delas precise saber que ela existe. E é geometria nova, criada aqui —
## não depende de o arquivo do boneco ter sido regravado, então continua
## valendo se alguém trocar o `lutador.glb` por outro com os mesmos ossos.
##
## O desenho é o mínimo que lê a três metros: uma boca escura e um lábio
## de baixo. Boca fina demais some dentro do contorno preto do desenho, e
## foi por isso que a primeira tentativa não apareceu na tela.
## MEDIDO NA TELA, E NÃO ESTIMADO. A primeira posição pôs a boca DENTRO
## da cabeça: apareciam dois risquinhos escuros nas bordas e mais nada. A
## cabeça deste modelo é um volume arredondado de uns 19 cm de raio, então
## a superfície do rosto na altura da boca fica perto de 17 cm à frente do
## osso — não 11.
const BOCA_LOCAL := Vector3(0.0, 0.046, 0.170)
const BOCA_TAMANHO := Vector3(0.072, 0.019, 0.050)

func _dar_uma_boca() -> void:
	if _esqueleto == null or _osso_cabeca < 0:
		return
	var suporte := BoneAttachment3D.new()
	suporte.name = "SuporteDaBoca"
	suporte.bone_idx = _osso_cabeca
	_esqueleto.add_child(suporte)

	var boca := MeshInstance3D.new()
	boca.name = "Boca"
	var caixa := BoxMesh.new()
	caixa.size = BOCA_TAMANHO
	boca.mesh = caixa
	boca.position = BOCA_LOCAL
	boca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	suporte.add_child(boca)

	var labio := MeshInstance3D.new()
	labio.name = "Labio"
	var caixa2 := BoxMesh.new()
	caixa2.size = Vector3(BOCA_TAMANHO.x * 0.86, 0.010, BOCA_TAMANHO.z * 0.94)
	labio.mesh = caixa2
	labio.position = BOCA_LOCAL + Vector3(0.0, -0.013, 0.001)
	labio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	suporte.add_child(labio)

	_pecas_do_rosto = [boca, labio]
	_cores_do_rosto = [Color(0.13, 0.02, 0.03), Color(0.62, 0.22, 0.20)]

## As peças criadas aqui precisam receber a mesma pintura do resto do
## corpo; `Arena3D` as encontra pela varredura de malhas.
var _pecas_do_rosto: Array[MeshInstance3D] = []
var _cores_do_rosto: Array[Color] = []

## A cor com que cada peça do rosto deve ser pintada. `Arena3D` pergunta.
func cor_da_peca(malha: MeshInstance3D) -> Variant:
	var i := _pecas_do_rosto.find(malha)
	return _cores_do_rosto[i] if i >= 0 else null

func tem_esqueleto() -> bool:
	return _esqueleto != null and _esqueleto.get_bone_count() >= 15

func animacoes_disponiveis() -> PackedStringArray:
	var nomes := PackedStringArray()
	for nome in _animacoes:
		nomes.append(str(nome))
	return nomes

func _achar_animador(no: Node) -> AnimationPlayer:
	if no is AnimationPlayer:
		return no
	for filho in no.get_children():
		var achado := _achar_animador(filho)
		if achado != null:
			return achado
	return null

func _achar_esqueleto(no: Node) -> Skeleton3D:
	if no is Skeleton3D:
		return no
	for filho in no.get_children():
		var achado := _achar_esqueleto(filho)
		if achado != null:
			return achado
	return null

func _normalizar(nome: String) -> String:
	var n := nome.to_lower().replace(" ", "_").replace("-", "_")
	for separador in ["|", "/", ":"]:
		if separador in n:
			n = n.get_slice(separador, n.get_slice_count(separador) - 1)
	return n

func _indexar_animacoes() -> void:
	_animacoes.clear()
	if _animador == null:
		return
	var existentes := _animador.get_animation_list()
	for papel in ALIASES:
		for real in existentes:
			var normal := _normalizar(str(real))
			for alias in ALIASES[papel]:
				if normal == alias or normal.ends_with("_" + alias) or alias in normal:
					_animacoes[papel] = real
					break
			if _animacoes.has(papel):
				break

## QUAIS ANIMAÇÕES SE REPETEM — dito uma vez, no arranque.
##
## O glTF não carrega essa informação, então o importador marca tudo como
## tocar-uma-vez e cabe a quem usa o arquivo dizer o que é postura e o
## que é gesto. Sem isto, a postura parada do lutador reiniciava com
## mistura a cada ciclo, para sempre. Ver o cabeçalho.
func _ajustar_loops() -> void:
	if _animador == null:
		return
	for papel in _animacoes:
		var anim := _animador.get_animation(_animacoes[papel])
		if anim == null:
			continue
		anim.loop_mode = (
			Animation.LOOP_LINEAR if str(papel) in PAPEIS_CONTINUOS else Animation.LOOP_NONE
		)

## QUANTO TEMPO UM PAPEL OCUPA DE VERDADE, na velocidade em que vai ser
## tocado. É isto, e não uma tabela, que diz quando o lutador pode voltar
## à guarda sem cortar o próprio gesto.
func _duracao(papel: String, velocidade := 1.0) -> float:
	var padrao := float(DURACAO_PADRAO.get(papel, 1.25))
	if _animador == null or not _animacoes.has(papel):
		return padrao
	var anim := _animador.get_animation(_animacoes[papel])
	if anim == null or anim.length <= 0.0:
		return padrao
	return anim.length / maxf(velocidade, 0.01)

func _tocar(papel: String, mistura := 0.16, velocidade := 1.0) -> bool:
	if _animador == null or not _animacoes.has(papel):
		return false
	var real: StringName = _animacoes[papel]
	if _animador.current_animation == str(real) and _animador.is_playing():
		return true
	_animador.play(real, mistura, velocidade)
	return true

func preparar() -> void:
	dano = 0.0
	queda = 0.0
	_caindo = false
	_levantando = false
	_recuo = 0.0
	_tempo_reacao = 0.0
	_tempo_na_lona = 0.0
	em_guarda = false
	if _raiz != null and _repouso.has("__raiz__"):
		_raiz.transform = _repouso["__raiz__"]
	_tocar("idle", 0.05)

func guardar(ativo: bool) -> void:
	em_guarda = ativo
	if _caindo:
		return
	if ativo:
		if not _tocar("guard", 0.22):
			_tocar("idle", 0.22)
	else:
		_tocar("idle", 0.22)

func bater(forca: float, derruba := false, pontos := -1) -> Dictionary:
	var f := clampf(forca, 0.0, 1.0)
	_recuo = 1.0
	_forca_do_recuo = f
	# Alternar o lado mantém variedade sem depender de aleatoriedade: duas
	# máquinas com o mesmo golpe exibem a mesma intensidade e duração.
	_lado *= -1.0
	var antes := dano
	if f > DANO_MINIMO:
		dano = clampf(dano + f * DANO_POR_GOLPE, 0.0, 1.0)
	var nocaute := not _caindo and (derruba or (dano >= 1.0 and antes < 1.0))
	var papel := ""
	var desdenhou := false
	var ritmo_da_queda := lerpf(0.92, 1.12, f)
	if nocaute:
		papel = "knockout"
		_caindo = true
		_levantando = false
		_tempo_na_lona = 0.0
		_tempo_levantar = _duracao("get_up", 1.0)
		_tempo_reacao = TEMPO_NA_LONA + _tempo_levantar
		# A pose de onde o tombo parte, guardada uma vez. Ver `_aplicar_queda`.
		if _esqueleto != null and _osso_raiz >= 0:
			_raiz_antes_do_tombo = Transform3D(
				Basis(_esqueleto.get_bone_pose_rotation(_osso_raiz)),
				_esqueleto.get_bone_pose_position(_osso_raiz)
			)
		_tocar("knockout", 0.08, ritmo_da_queda)
	elif not _caindo:
		# A nota é a linguagem do jogador. Abaixo de 6.000 o adversário
		# entende que o golpe foi fraco e desdenha, mesmo que a calibração
		# física da máquina tenha registrado algum movimento. Na lona ele
		# nunca executa esta resposta: um nocaute não pode virar deboche.
		papel = reacao_para_pontos(pontos, f)
		desdenhou = papel == "taunt_weak" and pontos >= 0 and pontos < 6000
		# A DURAÇÃO SAI DA ANIMAÇÃO, e já dividida pela velocidade em que
		# ela será tocada. Uma tabela à mão não teria como acompanhar
		# essa velocidade — e era por isso que todo gesto era cortado no
		# meio para voltar à guarda. Ver o cabeçalho.
		var ritmo := lerpf(0.92, 1.10, f)
		_tempo_reacao = _duracao(papel, ritmo)
		_tocar(papel, 0.06, ritmo)
	return {"nocaute": nocaute, "dano": dano, "reacao": papel, "desdenhou": desdenhou}

static func reacao_para_pontos(pontos: int, forca: float) -> String:
	if pontos >= 0 and pontos < 6000:
		return "taunt_weak"
	var reacao := reacao_para_forca(forca)
	# Depois do corte competitivo, no mínimo reconhece o golpe. Isso evita
	# que uma calibração de velocidade conservadora contradiga os pontos.
	if pontos >= 6000 and reacao == "taunt_weak":
		return "hit_light"
	return reacao

static func reacao_para_forca(forca: float) -> String:
	var f := clampf(forca, 0.0, 1.0)
	if f >= 0.82:
		return "stagger"
	if f >= 0.62:
		return "hit_heavy"
	if f >= 0.38:
		return "hit_medium"
	if f >= 0.18:
		return "hit_light"
	return "taunt_weak"

func atualizar(delta: float) -> void:
	_relogio += delta
	_recuo = maxf(0.0, _recuo - delta * 2.1)
	_tempo_reacao = maxf(0.0, _tempo_reacao - delta)
	if _caindo:
		_tempo_na_lona += delta
		queda = minf(1.0, queda + delta * 2.8)
		if _tempo_na_lona >= TEMPO_NA_LONA and not _levantando:
			_levantando = true
			_tempo_levantar = _duracao("get_up", 1.0)
			_tocar("get_up", 0.12)
		if _levantando:
			# A CÂMERA SOBE NO MESMO COMPASSO EM QUE ELE LEVANTA. Com o
			# tempo chutado, ela chegava em pé antes ou depois dele.
			queda = maxf(0.0, 1.0 - (_tempo_na_lona - TEMPO_NA_LONA) / _tempo_levantar)
		if _tempo_na_lona >= TEMPO_NA_LONA + _tempo_levantar:
			_caindo = false
			_levantando = false
			queda = 0.0
			dano = minf(dano, 0.72)
			_tocar("guard" if em_guarda else "idle", 0.20)
	elif _tempo_reacao <= 0.0:
		_tocar("guard" if em_guarda else "idle", 0.20)

	_agrandar_a_cabeca()
	if _animador == null or _animacoes.is_empty():
		_pose_fallback()
	# A QUEDA É A ÚLTIMA COISA, e vale nos dois caminhos: ela multiplica
	# por cima da pose que a animação (ou o `_pose_fallback`) acabou de
	# escrever, em vez de disputar com ela.
	_aplicar_queda()

## O NOCAUTE PRECISOU SER FEITO AQUI, PORQUE A ANIMAÇÃO NÃO O FAZ.
##
## Medido, osso a osso: durante a animação chamada `knockout`, a cabeça do
## lutador sai de 1,59 m para 1,63 m de altura e anda DOZE CENTÍMETROS
## para trás. Ele não cai. Ele se inclina um pouco e volta.
##
## E o resto do jogo acreditava na promessa: tocava o som de queda,
## anunciava NOCAUTE, gritava a torcida, jogava a câmera para a altura da
## lona e esperava 3,35 s "no chão" antes de mandar levantar — com o
## boneco em pé o tempo todo. Da plateia, o momento mais importante do
## jogo era o adversário balançando de leve enquanto a câmera olhava para
## um pedaço vazio de tapete.
##
## Não dá para regravar a animação daqui, e não precisa: o tombo é uma
## rotação do corpo inteiro em torno dos pés, que é fisicamente o que um
## nocaute é. O esqueleto continua tocando a animação de queda por cima —
## braços abrindo, cabeça virando —, e o corpo vai ao chão de verdade.
##
## O giro é em torno da ORIGEM do nó raiz, que fica nos pés: 78° para trás
## levam a cabeça de 1,64 m de altura para 0,34 m, a um metro e meio atrás
## dos calcanhares. É uma queda de costas, que é como se cai quando se
## leva um soco de frente.
## O TOMBO É NO OSSO-RAIZ, E NÃO NO NÓ.
##
## A primeira versão girava o nó do personagem, que é o caminho óbvio e
## está errado: o corpo é uma malha COM ESQUELETO, e girar o nó por fora
## do esqueleto fez onze das treze superfícies simplesmente sumirem da
## tela — sobravam as duas botas. Medido e confirmado nos dois sentidos:
## sem o giro, o corpo inteiro desenha; com ele, só as botas.
##
## Girando o OSSO-RAIZ, que é o pai de todos os outros, o tombo passa a
## ser uma pose de esqueleto como qualquer outra — exatamente o que o
## motor espera de uma malha com pele, e o mesmo caminho que as animações
## já usam. O corpo inteiro vai ao chão e continua desenhando.
const ANGULO_DA_QUEDA_GRAUS := 78.0
const OSSO_RAIZ := "root"

## O CORPO DEITADO PRECISA SUBIR, NÃO DESCER.
##
## Girar em torno dos pés põe a LINHA DO ESQUELETO rente à lona — e o
## esqueleto é o meio do corpo, não a parte de baixo dele. Com os ossos a
## doze centímetros do chão e um tronco de vinte de espessura, metade do
## lutador ficaria DENTRO do tapete. Dezoito centímetros é meia espessura
## de corpo, e é o que o faz deitar SOBRE a lona.
const SUBIDA_DA_QUEDA := 0.18

var _osso_raiz := -1
## A pose do osso-raiz no instante em que o nocaute começou.
var _raiz_antes_do_tombo := Transform3D()

## A POSE DO TOMBO É ABSOLUTA, E NÃO UM ACRÉSCIMO A CADA QUADRO.
##
## A primeira tentativa lia a pose atual e multiplicava o giro nela. Isso
## funciona enquanto a animação está tocando — ela reescreve a pose antes
## de cada acréscimo. Mas a animação de nocaute dura 1,93 s e NÃO SE
## REPETE: quando ela acaba, ninguém mais reescreve a pose, e o mesmo
## giro passa a ser multiplicado sessenta vezes por segundo em cima de si
## mesmo. O lutador dava voltas e desaparecia do ringue em meio segundo.
##
## Guardando a pose de quando o golpe caiu e escrevendo sempre
## `tombo(t) × guardada`, o resultado depende só de `t` — pode ser
## chamado uma vez ou mil, dá no mesmo.
func _aplicar_queda() -> void:
	if _esqueleto == null or _osso_raiz < 0 or queda <= 0.001:
		return
	# `ease(…, 0.55)` sai depressa e assenta: um corpo que cai ganha
	# velocidade e para de uma vez quando encontra a lona.
	var t := ease(clampf(queda, 0.0, 1.0), 0.55)
	var tombo := Quaternion(Vector3.RIGHT, -deg_to_rad(ANGULO_DA_QUEDA_GRAUS) * t) \
		* Quaternion(Vector3.FORWARD, _lado * 0.20 * t)
	_esqueleto.set_bone_pose_rotation(
		_osso_raiz, tombo * _raiz_antes_do_tombo.basis.get_rotation_quaternion()
	)
	_esqueleto.set_bone_pose_position(
		_osso_raiz, _raiz_antes_do_tombo.origin + Vector3(0.0, SUBIDA_DA_QUEDA * t, 0.0)
	)



## A CABEÇA É REDIMENSIONADA DEPOIS DA ANIMAÇÃO, todo quadro.
##
## E tem de ser depois: o tocador de animação escreve a pose de cada osso
## a cada quadro, então um ajuste feito uma vez na montagem seria apagado
## no primeiro quadro em que o boneco se mexesse. Fazendo aqui, no fim de
## `atualizar` e portanto depois de o tocador ter escrito, a escala vale
## em todas as nove animações sem precisar tocar em nenhuma delas.
func _agrandar_a_cabeca() -> void:
	if _esqueleto == null:
		return
	if _osso_cabeca >= 0:
		_esqueleto.set_bone_pose_scale(_osso_cabeca, Vector3.ONE * ESCALA_DA_CABECA)
	for nome in _escultura_indices:
		_esqueleto.set_bone_pose_scale(_escultura_indices[nome], ESCULTURA[nome])

func _pose_fallback() -> void:
	if _raiz == null:
		return
	# O TOMBO SAIU DAQUI. Ele é de `_aplicar_queda`, que roda logo depois
	# e vale para os dois caminhos — com animação e sem. Dois lugares
	# girando o mesmo corpo é como a queda saía com o dobro do ângulo no
	# modelo sem esqueleto e nenhum no modelo com.
	var raiz: Transform3D = _repouso.get("__raiz__", _raiz.transform)
	var impacto := ease(_recuo, 0.35)
	raiz.origin.z -= impacto * (0.08 + _forca_do_recuo * 0.26)
	raiz.origin.x += _lado * impacto * 0.06
	_raiz.transform = raiz
	_junta("Tronco", Vector3(-impacto * (0.12 + _forca_do_recuo * 0.40), _lado * impacto * 0.16, 0.0))
	_junta("Cabeca", Vector3(-impacto * (0.22 + _forca_do_recuo * 0.60), _lado * impacto * 0.30, 0.0))

func _junta(nome: String, giro: Vector3) -> void:
	var no: Node3D = _juntas.get(nome)
	if no == null:
		return
	var base: Transform3D = _repouso[nome]
	no.transform = Transform3D(base.basis * Basis.from_euler(giro), base.origin)
