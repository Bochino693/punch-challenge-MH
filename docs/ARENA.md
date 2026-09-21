# A arena e o lutador

Esta é a única diferença entre `punch-challenge-animated` e
`punch-challenge`. O resto do jogo — sensor, ponte serial, câmera,
ranking, Central Técnica, exportação — é o mesmo código, e deve continuar
sendo: correção que entra num repositório precisa poder entrar no outro
sem tradução.

## O que mudou na tela do soco

Antes, o meio da tela do soco era um alvo desenhado (na espera) e um
medalhão redondo com o número (no resultado). Os dois ocupavam o mesmo
retângulo escuro que o fundo do jogo já reservava, e os dois eram
desenho 2D plano.

Agora esse retângulo é uma **janela 3D com moldura**: um ringue de
verdade, com câmera, luz e perspectiva, e um lutador dentro dele que
**recua na medida do soco** e vai à lona quando não aguenta mais.

    ┌──────────────────────────────────────┐
    │              PUNCH CHALLENGE         │
    │  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓    │
    │ █┃  ADVERSÁRIO · ABALADO 46%    ┃█   │  ← as colunas de dano
    │ █┃ ┌──────────────────────────┐ ┃█   │
    │ █┃ │                          │ ┃█   │
    │ █┃ │    a arena em 3D         │ ┃█   │  ← o SubViewport
    │ █┃ │                          │ ┃█   │
    │ █┃ └──────────────────────────┘ ┃█   │
    │  ┗━━━━━━━┏━━━━━━━━━━━━┓━━━━━━━━━┛    │
    │          ┃    8420    ┃              │  ← a plaqueta do placar
    │          ┗━━━━━━━━━━━━┛              │
    │              NOCAUTE                 │
    │        DIRETO NO QUEIXO!             │  ← a frase
    │   ┌───────────┐  ┌───────────┐       │
    │   │  SOCO 1   │  │  SOCO 2   │       │
    └──────────────────────────────────────┘

As medidas moram todas em `ArenaQuadro` (`scripts/arena/quadro.gd`),
como constantes públicas, porque três coisas dependem delas: o desenho,
o tamanho da janela 3D (que precisa da mesma proporção, senão a imagem
chega esticada) e os testes.

## As peças

| arquivo | o que faz |
|---|---|
| `scripts/arena/figura.gd` | as formas torneadas, e a fusão das peças paradas |
| `scripts/arena/lutador_nativo.gd` | monta o corpo: proporções, rosto, cores |
| `scripts/arena/lutador_animacao.gd` | as nove ações, em tabelas de ângulos |
| `scripts/arena/arena3d.gd` | o mundo 3D dentro do `SubViewport` |
| `scripts/arena/lutador.gd` | conduz o tocador: reação, dano, queda, volta |
| `scripts/arena/quadro.gd` | a moldura e as colunas de dano, em 2D |
| `scripts/arena/frases.gd` | o que a máquina grita a cada nível |
| `scripts/ranking_celebration.gd` | quatro cerimônias, conforme a colocação |
| `tests/test_arena.gd` | o que não pode voltar a quebrar |

## Como o corpo é feito

Cada membro é uma sequência de **anéis** de raios diferentes, empilhados
ao longo de um eixo e costurados — um torno. A anatomia inteira vira uma
tabela de raios, que é uma coisa que dá para ajustar e comparar, ao
contrário de vértices soltos: um bíceps é um raio maior no meio do
caminho, um antebraço de boxeador é 0,059 m no cotovelo e 0,036 m no
punho.

A normal de cada vértice sai da **inclinação do perfil** naquele ponto,
calculada analiticamente e não pela média dos triângulos vizinhos. É o
que dá superfície contínua de verdade, sem costura e sem faceta — e é a
diferença entre isto e a versão de caixas empilhadas, que nenhuma
iluminação tirava do aspecto de Minecraft.

As medidas que definem o personagem:

| medida | valor |
|---|---|
| altura total | ~1,80 m |
| ombro a ombro | 0,55 m |
| cintura | 0,20 m |
| cabeça | 0,24 m (≈ 7,5 cabeças de altura) |
| luva | 0,066 m de raio, contra um punho de 0,046 m |

O V do tronco sai da razão ombro/cintura. Uma versão anterior tinha 0,50
contra 0,38 — um e pouco para um é a proporção de um barril, e foi o que
manteve a queixa de "parece um gordinho" mesmo depois de trocar a
iluminação. `tests/test_arena.gd` guarda estas razões.

## Onze chamadas de desenho, e não sessenta e três

O corpo tem sessenta e três peças, mas só **onze** se mexem sozinhas —
as que as animações citam. Todo o resto (olhos, cabelo, luvas, botas,
faixas do calção) é costurado dentro da junta que o carrega, na
montagem, com a cor viajando **no vértice**.

Isso importa porque o gargalo de uma TV Box não é triângulo, é chamada
de desenho: dezessete mil triângulos qualquer GPU deste século desenha
sem suar, mas sessenta e três chamadas — cento e vinte e seis com a
passada do contorno — é trabalho de processador, e aparece como engasgo,
não como queda suave de quadros.

A passada do contorno é uma casca invertida, e ela só vale para a
silhueta: cada vértice leva, na primeira coordenada de textura, se a peça
dele entra na casca. Sem isso a casca do olho ficava maior que o olho,
escapava por fora da pele e riscava a cara de preto.

## Premiação e torcida

A colocação escolhe uma receita própria em `RankingCelebration`:

- **1º lugar:** selo de campeão, três canhões, chuva cheia e torcida longa;
- **2º–3º:** cerimônia de pódio, dois canhões e torcida própria;
- **4º–10º:** entrada no Top 10, um canhão e comemoração média;
- **11º–20º:** reconhecimento curto, sem fingir que foi recorde.

Os quatro sons são estéreo e combinam massa vocal, canto de arquibancada,
palmas, assobios e reverberação de ginásio. O confete é atualizado no lugar
e desenhado como uma fita de uma chamada, evitando a alocação e a
triangulação que faziam a chuva engasgar.

Abaixo de **6.000 pontos**, o adversário baixa a guarda, nega com a cabeça
e desdenha, acompanhado por vaias e assobios próprios. Com 6.000 ou mais
ele reconhece o golpe e reage fisicamente; caído na lona, nunca desdenha.

## O dano

Cada soco tira `forca × 0,62` do adversário (`Lutador3D.DANO_POR_GOLPE`),
onde `forca` é a posição da velocidade real dentro da faixa calibrada.
A nota continua usando o expoente competitivo, mas ele não achata a
animação: golpe físico médio parece médio, mesmo com pontuação difícil.
Na prática:

- dois socos perfeitos derrubam;
- um soco leve quase não mexe no medidor (e abaixo de 2% não conta,
  senão o ruído do sensor encheria a barra sozinho ao longo da noite);
- os níveis com *hit-stop* na tabela do `ScoreTier` — NOCAUTE,
  PESO-PESADO, LENDÁRIO e SOCO PERFEITO — derrubam **no primeiro golpe**,
  independentemente do medidor.

Quem cai permanece visível na lona e completa queda/levantamento em cerca
de 5 s, com o medidor voltando a 72%: a
rodada tem dois socos, e o segundo precisa ter para onde ir.

**Cada rodada começa com o adversário inteiro.** Herdar o dano faria a
segunda pessoa da fila derrubar alguém que já estava caindo, e as
colunas laterais mentiriam sobre o que ela fez.

## O custo, que é o que interessa numa TV Box

Esta versão vai para o mesmo aparelho que a original, então a arena foi
construída para custar pouco, não para impressionar em benchmark:

- **uma malha só** para todo o ringue (lona, borda, quatro postes, nove
  cordas, fundo), com cor por vértice — um desenho em vez de trinta;
- **três luzes**, nenhuma com sombra;
- **flashes e silhuetas da plateia em `MultiMesh`** — dois desenhos, com
  reação proporcional à força;
- **dois emissores GPU reutilizados** para faíscas e poeira da lona;
- **sem antisserrilhado, sem brilho, sem TAA**;
- **a janela encolhe** quando o vigia de desempenho aperta
  (`Desempenho.qualidade < 0,55`), mas continua atualizando em todo quadro;
- **a janela só desenha nas telas da rodada.** Liga no 3–2–1, permanece
  até o resultado e desliga na abertura, na tabela e na Central
  (`main.gd::_arena_no_ar`).

Para medir na máquina de destino:

```
godot --path . --script tools/medir_arena.gd
```

Ele roda a mesma tela duas vezes, com e sem a janela 3D, e imprime a
diferença. Não use `--headless`: sem rasterizador o custo do 3D não
aparece. Num PC de desenvolvimento com vídeo por software (llvmpipe), a
arena custou **0,77 ms por quadro** — menos de 4% de um quadro que já
levava 21 ms só com o 2D. Com GPU de verdade a diferença é menor ainda.

## Conferir

```
godot --headless --path . --script tests/test_arena.gd
godot --path . --script tools/capturar_telas.gd   # PNG de cada tela
```

`tests/test_arena.gd` guarda, entre outras coisas, os dois erros que a
arena cometeu de verdade durante a construção:

- **o nocaute afundava o lutador.** A queda baixava o corpo 62 cm além
  de tombá-lo; como o nó raiz fica na altura da lona, o boneco saía por
  baixo do ringue e a moldura mostrava um ringue vazio no momento mais
  importante do jogo;
- **a janela 3D e o buraco da moldura tinham proporções diferentes**, e
  a imagem chegava esticada.

As capturas ficam em `.telas/` (ignorado pelo Git) e são o jeito mais
rápido de conferir a tela inteira sem montar o gabinete.
