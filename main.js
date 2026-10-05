
//////////// MODIFIQUE AQUI:
const dummyJets=12; // quantidade de jatos aleatórios
const keysJet=false; // modifique para ter um jato controlado pelo teclado
const prologJets=[]; // jatos prolog

// Se quiser adicionar jatos prolog, faça assim:
prologJets.push("Rocinante");
//prologJets.push("Apaga Fogo");

/////////////////////////////////////////////////////////////////////////////
///////////////////////// Não Mexa Daqui Para Baixo /////////////////////////
var windowHeight=$(window).height(), windowWidth=$(window).width(), lastUpdateScore=Date.now(), prologJetIDs=0, timeForUpdatingProlog=200;
const canvas=document.getElementById("myCanvas");
canvas.width=1024;//windowWidth;
canvas.height=768;//windowHeight;
const ctx = canvas.getContext("2d"), background = new Image();
background.src = 'background.jpg'; // gerada com chatGPT e modificada no GIMP
const dummyNames = [ "Boladão", "Rabugento", "Trovão", "Bagunceiro", "Marrento", "Trambiqueiro", "Espertinho", "Sorriso", "Soneca", "Maluco", "Zé Bala", "Trapalhão", "Fofinho", "Dengoso", "Terremoto", "Estabanado", "Cuspidor de Fogo", "Doidivanas", "Trovador", "Curioso", "Esquentadinho", "Pestinha", "Trapaceiro", "Esperto", "Relâmpago", "Roncador", "Surpresa", "Malandrinho", "Borbulhante", "Folgado", "Trovão Azul", "Espião", "Explosivo", "Cabeça de Vento", "Malabarista", "Tristonho", "Saltitante", "Dorminhoco", "Felpudo", "Arrasador", "Espirra-Água", "Trapaceiro", "Esquentado", "Reluzente", "Fofoqueiro", "Torpedo", "Dente de Leão", "Terrível", "Sapeca", "Bate-Papo", "Barulhento", "Faísca", "Linguarudo", "Abobalhado", "Bagunceiro", "Furacão", "Tagarela", "Artilheiro", "Engraçadinho", "Furioso", "Bicudo", "Mágico", "Espanta-Mosquito", "Ziguezague", "Estiloso", "Brincalhão", "Trancado", "Bagunçado", "Sorridente", "Tornado", "Desastrado", "Malabarista", "Mala Sem Alça", "Borbulhante", "Dorminhoco", "Trovão Azul", "Risadinha", "Bagunceiro", "Barulhento", "Fofinho", "Sorriso Largo", "Reluzente", "Esperto", "Arrepiante", "Mexeriqueiro", "Estelar", "Roncador", "Zigzag", "Fanfarrão", "Bate-Papo", "Trapaceiro", "Estourado", "Espirra-Água", "Bagunceiro", "Bagunça", "Trovador", "Saltitante", "Cabeça de Vento", "Veloz" ]; // nomes gerados com chatGPT
const maxSpeed=2, jetW=40, jetH=72, score=100;

const arena = new Arena(canvas.height, canvas.width), _colors = new Colors(0);
var jets = [];
if (keysJet) jets.push(newJet("KEYS"));
for (let i=0;i<prologJets.length;i++) jets.push(newJet("PROLOG"));
for (let i=0;i<dummyJets;i++) jets.push(newJet("DUMMY"));

var allBOOMS = [],
    lastBullet = new Array(jets.length).fill(Date.now());

animate();

// controls: ["DUMMY", "KEYS", "PROLOG"]
function newJet(controls="DUMMY") {
    let pos = getPosition(), name, id=-1;
    switch(controls) {
        case "PROLOG":
            name=prologJets[prologJetIDs];
            id=prologJetIDs++;
            break;
        case "DUMMY":
            name=dummyNames[Math.floor(Math.random()*dummyNames.length)];
            break;
        case "KEYS":
            name="Humano";
            break;
    }
    return new Jet(pos.x, pos.y,
                   jetW, jetH,
                   canvas.height, canvas.width,
                   controls, maxSpeed, _colors.getColor(),
                   score, id, name,
                   timeForUpdatingProlog);
}

function getPosition() {
    let jetAux = Math.max(jetH, jetW),
        x = Math.floor(Math.random()*(canvas.width-jetAux*2)+jetAux),
        y = Math.floor(Math.random()*(canvas.height-jetAux*2)+jetAux);
    return {x:x, y:y};
}

function getScores() {
    let ret = { scores: new Array(jets.length), winner: undefined };
    let alive = 0, lastAlive = -1;
    for (let i = 0; i < jets.length; i++) {
        ret.scores[i] = jets[i].score;
        if (jets[i].score > 0) {
            alive++;
            lastAlive = i;
        }
    }

    if (alive === 1) ret.winner = lastAlive;

    return ret;
}

function updateScoresDiv(scores) {
    let e = $('#id_score');
    e.empty();
    if (scores.winner != undefined) {
        $('#id_winner').text("Vencedor: Jato "+scores.winner+
                             " ("+ jets[scores.winner].name+","+jets[scores.winner].controlType+")");
        $('#id_km').hide();
    }else{
        lastUpdateScore = Date.now();
        for (let i=0;i<scores.scores.length;i++){
            e.append('<label style="color:'+jets[i].color+';">'+jets[i].name+': '+scores.scores[i]+'</label>');
        }
    }
}

$('#kmdiv').toggle();
updateScoresDiv(getScores());
document.addEventListener("keydown",function(event) {
    if (event.key === "s" || event.key === "S") $('#kmdiv').toggle();
});

function updateCanvas(){
    // Removendo misseis desativados
    for (let i=allBOOMS.length-1;i>=0;i--) {
        if (allBOOMS[i].deactivated) allBOOMS.splice(i,1);
    }

    // Atualizando os jatos
    for (let i=0;i<jets.length;i++) {
        const boom=jets[i].update(jets,allBOOMS);
        if (boom[0] && Date.now()-lastBullet[i]>1000) {
            allBOOMS.push(new Boom(boom[1],boom[2],boom[3],Math.max(jetH,jetW)));
            lastBullet[i]=Date.now();
        }
    }

    // Atualizando os misseis
    for (let i=0;i<allBOOMS.length;i++) allBOOMS[i].update(arena.position);
}

function animate(){
    var scores = getScores();
    var runFinished = scores.winner != undefined;

    if ((Date.now() - lastUpdateScore) > 1000) updateScoresDiv(scores);

    updateCanvas();

    ctx.save();
    arena.draw(ctx, background);
    for(let i=0;i<jets.length;i++) jets[i].draw(ctx);
    for (let i=0;i<allBOOMS.length;i++) allBOOMS[i].draw(ctx);
    ctx.restore();

    var newJets = new Array();
    for(let i=0;i<jets.length;i++){
        if (jets[i].score > 0) newJets.push(jets[i]);
    }
    jets = newJets;

    if (runFinished) {
        const finalScores=getScores();
        updateScoresDiv(finalScores);
        updateScoresDiv=function(){};
        $("#kmdiv").show();
    } else {
        requestAnimationFrame(animate);
    }
}
