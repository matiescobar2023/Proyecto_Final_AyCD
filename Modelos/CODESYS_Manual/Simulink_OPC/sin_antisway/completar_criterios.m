function completar_criterios(folder,out)
if nargin<2,R=load(fullfile(folder,'datos_brutos.mat'),'output');out=R.output;end
D=load(fullfile(folder,'datos_derivados.mat'));R=load(fullfile(folder,'datos_brutos.mat'),'q','preflight');
q=R.q;p=R.preflight;t=D.t;S=D.S;
auto=S.sup_modeCode==4;manual=S.sup_modeCode==3;loaded=logical(S.sup_loadedState);
X=interpTS(out.logsout.get('grupo5_Outport_08').Values,t);
Y=S.y_carga_fisica;profile=S.mon_obstacleProfile;
margin=NaN(size(t));
for j=find(auto).'
    columns=find((-30+(0:32)*2.44+2.44)>X(j)-1.22+1e-6 & ...
        (-30+(0:32)*2.44)<X(j)+1.22-1e-6);
    if ~isempty(columns),margin(j)=Y(j)-2.59*double(loaded(j))-max(profile(j,columns));end
end
% Margen geometrico aproximado: huella rectangular horizontal, sin inclinacion.
metodoMargen='y del spreader menos altura contenedor (si cargado) menos maximo de perfil fisico bajo x_carga +/-1.22m. No representa detector dinamico de colision.';
save(fullfile(folder,'datos_derivados.mat'),'margin','metodoMargen','-append');
C=readtable(fullfile(folder,'criterios.csv'),'TextType','string');
requestAuto=hasStage(q,6);effectiveManual=hasStage(q,8);support=hasStage(q,9);delivered=hasStage(q,14)&&q.done;
started=t>=q.events(1,2);
rows={
    'Perfil valido durante maniobra',double(~all(logical(S.mon_profileValid(started)))),0,'Validez de perfil leida del PLC';
    'Toma en modo manual',double(~any(manual & loaded)),0,'Carga confirmada con modo 3';
    'Despegue y solicitud auto',double(~requestAuto),0,'Etapa 6 tras elevacion y estabilizacion del operador';
    'Paso efectivo a manual destino',double(~effectiveManual),0,'Etapa 8';
    'Apoyo final',double(~support),0,'Contacto antes de apertura twistlocks, etapa 9';
    'Masa entregada slot 22',double(~delivered),0,'Entrega requiere apertura, carga fisica ausente y parada confirmada';
    'Sin retorno vacio',double(any(ismember(q.events(:,1),10:13))),0,'No etapas 10 a 13';
    'Slot 22 al finalizar traslado',abs(S.x_carro_fisica(end)-22.46),.5,'Posicion fisica al fin';
    'Fin sin falla',abs(S.sup_faultCode(end)),0,'Ultima muestra dentro de simulacion';
    'Fin sin emergencia',abs(S.n0_emergency(end)),0,'Ultima muestra dentro de simulacion'};
for j=1:size(rows,1)
    result="NO_APROBADO";if rows{j,2}<=rows{j,3},result="APROBADO";end
    C(end+1,:)={string(rows{j,1}),rows{j,2},rows{j,3},result,string(rows{j,4})};
end
if any(auto)
    minMargin=min(margin(auto));result="NO_APROBADO";if minMargin>=0,result="APROBADO";end
    C(end+1,:)={"Margen geometrico durante auto",minMargin,0,result,"Umbral MINIMO 0 m. Aproximacion rectangular sin inclinacion; no sensor de colision"};
end
C(end+1,:)={"Detector dedicado de colision",NaN,NaN,"NO_DISPONIBLE","Indicador del modelo NaN; no se declara ausencia certificada de colisiones"};
writetable(C,fullfile(folder,'criterios.csv'));
metadata=jsondecode(fileread(fullfile(folder,'metadatos.json')));
metadata.finX_m=S.x_carro_fisica(end);metadata.finY_m=S.y_carga_fisica(end);
metadata.masaFisicaCargada_kg=max(S.masa_fisica_suspendida);
metadata.anguloMaximo_rad=max(abs(S.angulo_fisico));
metadata.vswEfectivaMaxima_m_s=max(abs(S.antisway_efectiva));
metadata.diferenciaVcmdVrefMaxima_m_s=max(abs(S.antisway_diferencia));
metadata.maximosPerfilInicial_m=max(p.perfilInicial);
metadata.solicitudAuto_s=q.transitionToAutoY; % corregir con marca temporal real
if isfield(q,'solicitudAutomatico'),metadata.solicitudAuto_s=q.solicitudAutomatico;end
if any(auto),metadata.autoEfectivo_s=t(find(auto,1));end
if isfield(q,'solicitudManual'),metadata.manualSolicitado_s=q.solicitudManual;end
if effectiveManual,metadata.manualEfectivo_s=q.events(find(q.events(:,1)==8,1),2);end
fid=fopen(fullfile(folder,'metadatos.json'),'w');fprintf(fid,'%s',jsonencode(metadata,PrettyPrint=true));fclose(fid);
figs=findall(0,'Type','figure');for j=1:numel(figs),if isappdata(figs(j),'CODESYSCycle'),exportapp(figs(j),fullfile(folder,'hmi_final_con_controles.png'));break;end;end
end
function yes=hasStage(q,stage),yes=any(q.events(:,1)==stage);end
function y=interpTS(ts,t)
a=double(ts.Time(:));b=squeeze(double(ts.Data));if size(b,1)~=numel(a),b=b.';end
[a,idx]=unique(a,'last');y=interp1(a,b(idx,:),t,'linear','extrap');
end
