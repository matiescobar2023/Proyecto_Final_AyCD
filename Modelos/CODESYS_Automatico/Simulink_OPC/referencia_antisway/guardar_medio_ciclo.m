function guardar_medio_ciclo(folder)
% Analisis posterior: conserva output sin remuestrear. Las metricas se
% calculan sobre la rejilla de tiempo del operador (40 ms), por tiempo.
if nargin==0,folder=getappdata(0,'MedioCicloCarpeta');end
output=evalin('base','out');
preflight=getappdata(0,'MedioCicloPreflight');
q=getappdata(0,'CODESYSCycleResult');
if isempty(q)
    figs=findall(0,'Type','figure');
    for k=1:numel(figs),if isappdata(figs(k),'CODESYSCycle'),q=getappdata(figs(k),'CODESYSCycle');break;end;end
end
timing=[];safety=[];
if isappdata(0,'CODESYSOPCUATimingEvents'),timing=getappdata(0,'CODESYSOPCUATimingEvents');end
if isappdata(0,'CODESYSOPCUASafetyEvents'),safety=getappdata(0,'CODESYSOPCUASafetyEvents');end
if ~isfile(fullfile(folder,'datos_brutos.mat')), save(fullfile(folder,'datos_brutos.mat'),'output','q','preflight','timing','safety','-v7.3'); end
t=q.telemetry(:,1);S=struct();
names={'x_carro_fisica','v_carro_fisica','y_carga_fisica','v_izaje_fisica', ...
    'angulo_fisico','velocidad_angular_fisica','tension_fisica_cable', ...
    'masa_fisica_suspendida','v_ref','v_cmd','antisway_efectiva', ...
    'torque_carro_consigna_controlador','torque_izaje_consigna_controlador', ...
    'torque_carro_fisico_motor','torque_izaje_fisico_motor','angulo_referencia'};
for k=1:numel(names),signalName=names{k};if strcmp(signalName,'v_ref'),signalName='mc_diag_vref_input';end;e=output.logsout.get(signalName);if isa(e,'Simulink.SimulationData.Dataset'),e=e.get(1);end;S.(names{k})=sample(e.Values,t,'linear');end
monitors={'mon_xRef','mon_yRef','mon_vxRef','mon_vyRef','mon_axRef','mon_ayRef', ...
    'mon_scannedObstacleProfile','mon_profileValid','mon_scanActive','mon_obstacleProfile', ...
    'sup_modeCode','sup_faultCode','sup_alarmCode','sup_loadedState', ...
    'n0_emergency','n0_permitGlobal','n0_permitHoist','n0_permitTrolley', ...
    'n0_brakeTrolleyOpen','n0_brakeHoistOpen','mon_twistlocksClosed'};
for k=1:numel(monitors),S.(monitors{k})=sample(output.get(monitors{k}),t,'previous');end
S.error_x=S.mon_xRef-S.x_carro_fisica;
S.error_y=S.mon_yRef-S.y_carga_fisica;
S.error_vx=S.mon_vxRef-S.v_carro_fisica;
S.error_vy=S.mon_vyRef-S.v_izaje_fisica;
S.ax=gradient(S.v_carro_fisica,t);S.ay=gradient(S.v_izaje_fisica,t);
S.omega_referencia=gradient(S.angulo_referencia,t);
S.antisway_diferencia=S.v_cmd-S.v_ref;
S.saturacion_carro=abs(S.torque_carro_fisico_motor)>=4000*(1-1e-6);
S.saturacion_izaje=abs(S.torque_izaje_fisico_motor)>=20000*(1-1e-6);
S.interlock=~logical(S.n0_permitGlobal)|~logical(S.n0_permitHoist)|~logical(S.n0_permitTrolley);
etapa=zeros(size(t));for k=1:size(q.events,1),etapa(t>=q.events(k,2))=q.events(k,1);end
metodo='Interpolacion por tiempo: lineal para fisicas y consignas internas; previous para monitores discretos. Derivadas gradient sobre rejilla 40 ms. RMS sqrt(mean(z.^2)), sin ponderar; muestreo uniforme.';
save(fullfile(folder,'datos_derivados.mat'),'t','S','etapa','metodo','-v7.3');
idx=[1;find(diff(S.sup_modeCode)~=0)+1];
E=table(t(idx),S.sup_modeCode(idx),'VariableNames',{'tiempo_s','modo_codigo'});
E.descripcion=repmat("Cambio efectivo leido del PLC",height(E),1);writetable(E,fullfile(folder,'eventos_modo.csv'));
labels=struct('e0','Inicializacion y RESET','e1','Solicitud START','e3','Toma manual', ...
    'e4','Solicitud cierre twistlocks','e5','Despegue manual y seleccion slot 22', ...
    'e6','Solicitud automatico','e7','Entrada efectiva automatico','e8','Entrada efectiva manual', ...
    'e9','Apoyo y solicitud apertura twistlocks','e14','Entrega confirmada y STOP');
M=table(q.events(:,2),q.events(:,1),q.events(:,3),q.events(:,4),q.events(:,5), ...
    'VariableNames',{'tiempo_s','etapa_codigo','x_m','y_m','carga'});
M.descripcion=strings(height(M),1);for k=1:height(M),M.descripcion(k)=labels.(['e' num2str(M.etapa_codigo(k))]);end
if isfield(q,'solicitudManual'),M(end+1,:)={q.solicitudManual,7,NaN,NaN,1,"Solicitud manual"};end
M=sortrows(M,'tiempo_s');writetable(M,fullfile(folder,'eventos_maniobra.csv'));
metrics=cell(0,22);
for st=unique(etapa).'
    mask=etapa==st;ii=find(mask); if isempty(ii),continue;end
    residual=S.angulo_fisico(mask);residual=residual(max(1,end-49):end);
    metrics(end+1,:)={st,t(ii(1)),t(ii(end)),t(ii(end))-t(ii(1)), ...
        max(abs(S.error_x(mask))),max(abs(S.error_y(mask))), ...
        max(abs(S.v_carro_fisica(mask))),max(abs(S.v_izaje_fisica(mask))), ...
        max(abs(S.ax(mask))),max(abs(S.ay(mask))),max(abs(S.angulo_fisico(mask))),rmsval(S.angulo_fisico(mask)),rmsval(residual), ...
        max(abs(S.torque_carro_fisico_motor(mask))),rmsval(S.torque_carro_fisico_motor(mask)), ...
        max(abs(S.torque_izaje_fisico_motor(mask))),rmsval(S.torque_izaje_fisico_motor(mask)), ...
        min(S.tension_fisica_cable(mask)),max(S.tension_fisica_cable(mask)), ...
        sum(S.saturacion_carro(mask))*.04,sum(S.saturacion_izaje(mask))*.04,sum(S.interlock(mask))*.04};
end
T=cell2table(metrics,'VariableNames',{'etapa','inicio_s','fin_s','duracion_s','error_x_max_m','error_y_max_m', ...
    'vx_max_m_s','vy_max_m_s','ax_max_m_s2','ay_max_m_s2','angulo_max_rad','angulo_rms_rad','residual_ultimos2s_rms_rad', ...
    'torque_carro_max_Nm','torque_carro_rms_Nm','torque_izaje_max_Nm','torque_izaje_rms_Nm', ...
    'tension_min_N','tension_max_N','saturacion_carro_s','saturacion_izaje_s','interlock_s'});
writetable(T,fullfile(folder,'metricas_etapas.csv'));
operativo=t>=q.events(1,2);auto=S.sup_modeCode==4;
perfilError=max(abs(S.mon_scannedObstacleProfile(1,:).'-preflight.perfilInicial));
loaded=logical(S.sup_loadedState);targetMass=preflight.masaSpreader+preflight.masaContenedorSlot2;
if any(loaded),massError=min(abs(S.masa_fisica_suspendida(loaded)-targetMass));else,massError=Inf;end
criteria={
    'Inicio slot 2',abs(S.x_carro_fisica(1)+26.34),.01;
    'Altura inicial 25 m',abs(S.y_carga_fisica(1)-25),.01;
    'Reposo inicial carro',abs(S.v_carro_fisica(1)),.001;
    'Reposo inicial izaje',abs(S.v_izaje_fisica(1)),.001;
    'Perfil PLC coincide escena',perfilError,1e-9;
    'Sin barrido',max(S.mon_scanActive),0;
    'Masa fisica contenedor tomado',massError,1;
    'Entrada efectiva automatico',double(~any(auto)),0;
    'Entrega confirmada operador',double(~q.done),0;
    'Fallas despues de START',max(abs(S.sup_faultCode(operativo))),0;
    'Emergencias despues de START',max(S.n0_emergency(operativo)),0};
if strcmp(preflight.variante,'sin_antisway')
    criteria(end+1,:)={'Antisway efectiva cero',max(abs(S.antisway_efectiva)),1e-10};
    criteria(end+1,:)={'v_cmd igual v_ref en sumador',max(abs(S.antisway_diferencia)),1e-10};
end
C=cell2table(criteria,'VariableNames',{'criterio','valor_medido','umbral_maximo'});
C.resultado=repmat("NO_APROBADO",height(C),1);C.resultado(C.valor_medido<=C.umbral_maximo)="APROBADO";
C.motivo=repmat("Comprobacion numerica sobre las series guardadas",height(C),1);
writetable(C,fullfile(folder,'criterios.csv'));
meta=preflight;meta.matlab=version;sv=ver('Simulink');meta.simulink=sv.Version;meta.tiempoFinal_s=t(end);
meta.completo=q.done;meta.causaTerminacion=q.abort;if q.done,meta.causaTerminacion='Entrega y parada confirmadas';elseif isempty(q.abort),meta.causaTerminacion='Fin de simulacion sin entrega confirmada';end
meta.modelo=output.SimulationMetadata.ModelInfo.ModelName;
meta.antiswayGain=double(strcmp(preflight.variante,'referencia_antisway'));
meta.noRetorno=~any(ismember(q.events(:,1),10:13));
meta.colision='Sin sensor dedicado; requiere evaluacion geometrica adicional. No se certifica ausencia por indicador NaN.';
fid=fopen(fullfile(folder,'metadatos.json'),'w');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);
figs=findall(0,'Type','figure');for k=1:numel(figs),if isappdata(figs(k),'CODESYSCycle'),exportgraphics(figs(k),fullfile(folder,'hmi_final.png'),'Resolution',140);break;end;end
fprintf('GUARDADO %s completo=%d t=%.2f causa=%s\n',folder,q.done,t(end),meta.causaTerminacion);
end

function data=sample(ts,t,method)
time=double(ts.Time(:));data=double(ts.Data);data=squeeze(data);
if size(data,1)~=numel(time),data=data.';end
[time,i]=unique(time,'last');data=data(i,:);
if numel(time)==1,data=repmat(data,numel(t),1);else,data=interp1(time,data,t,method,'extrap');end
end
function r=rmsval(x),r=sqrt(mean(x.^2));end


