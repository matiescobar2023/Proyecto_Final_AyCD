function completar_eventos(folder)
R=load(fullfile(folder,'datos_brutos.mat'),'q');q=R.q;
D=load(fullfile(folder,'datos_derivados.mat'),'t','S');t=D.t;S=D.S;
M=readtable(fullfile(folder,'eventos_maniobra.csv'),'TextType','string');
marks={};
k=find(S.masa_fisica_suspendida>15001,1);if ~isempty(k),marks(end+1,:)={k,'Masa fisica cargada confirmada'};end
k=find(S.sup_loadedState & S.y_carga_fisica>2.59+.10,1);if ~isempty(k),marks(end+1,:)={k,'Despegue fisico: spreader 0.10 m sobre altura de toma'};end
k=find(S.sup_modeCode==4 & abs(S.x_carro_fisica-22.46)<.5 & abs(S.v_carro_fisica)<.25,1);
if ~isempty(k),marks(end+1,:)={k,'Llegada horizontal: no implica fin de descenso ni entrega'};end
for j=1:size(marks,1),k=marks{j,1};M(end+1,:)={t(k),-1,S.x_carro_fisica(k),S.y_carga_fisica(k),S.sup_loadedState(k),string(marks{j,2})};end
M=sortrows(M,'tiempo_s');writetable(M,fullfile(folder,'eventos_maniobra.csv'));
T=readtable(fullfile(folder,'metricas_etapas.csv'));
for j=1:height(T)
    next=find(q.events(:,2)>T.inicio_s(j)+1e-8,1);
    if ~isempty(next),T.fin_s(j)=q.events(next,2);else,T.fin_s(j)=t(end);end
    T.duracion_s(j)=T.fin_s(j)-T.inicio_s(j);
end
writetable(T,fullfile(folder,'metricas_etapas.csv'));
end
