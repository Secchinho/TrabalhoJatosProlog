% Jato 0
:- module(jato0, [obter_controles/4]).

%% Explicacao:
% Informacao:
%   X: posição horizontal do jato
%   Y: posiçao vertical do jato
%   ANGLE: angulo de inclinacao do jato: 0 para virado para frente até PI*2 (~6.28)
%   SCORE: inteiro com a "vida" do jato. Em zero, ele perdeu
%   SPEED: velocidade do jato
% Adversarios:
%   vetor com a posicao de todos os adversarios, [ [X1,Y1], [X2,Y2], ... ]
% Misseis:
%   vetor com a posicao de todos os misseis, [ [X1,Y1], [X2,Y2], ... ]
% Controles:
%   FORWARD: 1 para acelerar e 0 para continuar a velocidade atual
%   REVERSE: 1 para desacelerar e 0 para continuar a velocidade atual
%   LEFT: 1 para ir pra esquerda e 0 para não ir
%   RIGHT: 1 para ir pra direita e 0 para não ir
%   BOOM: 1 para tentar disparar (BOOM). Obs.: ele só pode disparar uma bala a cada segundo
%   MSG: mensagem para DEBUG

%%% Faça seu codigo a partir daqui, sendo necessario sempre ter o predicado:
%%%% obter_controles([X,Y,ANGLE,SCORE,SPEED], ADVERSARIOS, MISSEIS, [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG]) :- ...

troca(0, 1).
troca(1, 0).

distanciaEuclidiana([X, Y], [X1, Y1], D) :- Dx is X - X1, Dy is Y - Y1, D is Dx * Dx + Dy * Dy.

alvoMaisProximo(_, [A|[]], A).
alvoMaisProximo(J, [A|R], A) :- alvoMaisProximo(J, R, B), distanciaEuclidiana(J, A, D1), distanciaEuclidiana(J, B, D2),
                                D1 =< D2.
alvoMaisProximo(J, [A|R], B) :- alvoMaisProximo(J, R, B), distanciaEuclidiana(J, A, D1), distanciaEuclidiana(J, B, D2),
                                D1 > D2.

missilMaisProximo(_, [M|[]], M).
missilMaisProximo(J, [M|R], M) :- missilMaisProximo(J, R, B), distanciaEuclidiana(J, M, D1), distanciaEuclidiana(J, B, D2),
                                    D1 =< D2.
missilMaisProximo(J, [M|R], B) :- missilMaisProximo(J, R, B), distanciaEuclidiana(J, M, D1), distanciaEuclidiana(J, B, D2),
                                    D1 > D2.

%Dica do Claude, estive tendo problemas de voltas muito longas, a LLM sugeriu ao invés de imaginar um círculo eu imaginar um
%semi-círculo, subtraindo de 2Pi.
normaliza(D, D) :- D >= -pi, D =< pi.
normaliza(D, D2) :- D > pi, D2 is D - 2*pi.
normaliza(D, D2) :- D < -pi, D2 is D + 2*pi.

evasao([X,Y], Angulo, [Mx,My], 1, 0, 1) :- A is atan2(X - Mx, Y - My) - Angulo, normaliza(A, A1), A1 > 0.
evasao([X,Y], Angulo, [Mx,My], 1, 1, 0) :- A is atan2(X - Mx, Y - My) - Angulo, normaliza(A, A1), A1 < 0.

direcao(AnguloJato, AnguloAlvo, 1, 0) :- A is AnguloAlvo - AnguloJato, normaliza(A, A2), abs(A2) > 0.1, A2 > 0.
direcao(AnguloJato, AnguloAlvo, 0, 1) :- A is AnguloAlvo - AnguloJato, normaliza(A, A2), abs(A2) > 0.1, A2 < 0.
direcao(AnguloJato, AnguloAlvo, 0, 0) :- A is AnguloAlvo - AnguloJato, normaliza(A, A2), abs(A2) =< 0.1.

fugir([X, Y, ANGLE, _, _], MISSEIS, [FORWARD, 0, LEFT, RIGHT, 1, "Socorro!!!"]) :- missilMaisProximo([X, Y], MISSEIS, Missil), 
                                                                distanciaEuclidiana([X, Y], Missil, D), D =< 8100,
                                                                evasao([X,Y], ANGLE, Missil, FORWARD, LEFT, RIGHT).

ataqueOportunidade([X, Y], [Ax, Ay], 1, AnguloJato, AnguloAlvo) :- distanciaEuclidiana([X, Y], [Ax, Ay], D), D =< 250000,
                        direcao(AnguloJato, AnguloAlvo, _, _) :- A is AnguloAlvo - AnguloJato, normaliza(A, A2), abs(A2) =< 0.1.

ataqueOportunidade([X, Y], [Ax, Ay], 0) :- distanciaEuclidiana([X, Y], [Ax, Ay], D), D > 250000, 
direcao(AnguloJato, AnguloAlvo, 0, 0) :- A is AnguloAlvo - AnguloJato, normaliza(A, A2), abs(A2) =< 0.1..

freia([X, Y], [Ax, Ay], 1) :- distanciaEuclidiana([X, Y], [Ax, Ay], D), D =< 4900.
freia([X, Y], [Ax, Ay], 0) :- distanciaEuclidiana([X, Y], [Ax, Ay], D), D > 4900.

%Limit Breaker é uma referência de um jogo que gosto, Final Fantasy VII
batalha([X, Y, ANGLE, _, _], ADVERSARIOS, [1, REVERSE, LEFT, RIGHT, BOOM, "Limit Breaker"]) :- alvoMaisProximo([X, Y], ADVERSARIOS, [Ax, Ay]),
                                                                                direcao(ANGLE, atan2(X - Ax, Y - Ay), LEFT, RIGHT),
                                                                                freia([X, Y], [Ax, Ay], REVERSE),
                                                                                ataqueOportunidade([X, Y], [Ax, Ay], BOOM).               
%[FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG]
obter_controles(INFORMACAO, ADVERSARIOS, _, CONTROLES) :-
    INFORMACAO = [_, _, _, SCORE, _],
    SCORE > 20,
    batalha(INFORMACAO, ADVERSARIOS, CONTROLES).

obter_controles(INFORMACAO, _, MISSEIS, CONTROLES) :-
    INFORMACAO = [_, _, _, SCORE, _],
    SCORE =< 20,
    fugir(INFORMACAO, MISSEIS, CONTROLES).

obter_controles(INFORMACAO, ADVERSARIOS, MISSEIS, CONTROLES) :-
    INFORMACAO = [_, _, _, SCORE, _],
    SCORE =< 20,
    \+ fugir(INFORMACAO, MISSEIS, CONTROLES),
    batalha(INFORMACAO, ADVERSARIOS, CONTROLES).

% Para evitar erros, o jato para:
obter_controles(_, _, _, [0,0,0,0,0,"nenhuma regra aplicada"]).

% Dica:
% Você pode transformar um vetor com qualquer coisa para string assim:
% term_string(VETOR, MSG).
% Assim, MSG passa a ser uma string do seu vetor
% Ex.:
% ?- term_string([1,2,"teste",oi], MSG.
% MSG = "[1,2,\"teste\",oi]".
