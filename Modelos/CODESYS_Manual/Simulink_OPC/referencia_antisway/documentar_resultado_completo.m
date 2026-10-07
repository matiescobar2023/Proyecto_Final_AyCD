function documentar_resultado_completo(folder,out,q)
% Verifica cobertura original; no extrapola ni vuelve a ejecutar la planta.
rows=cell(0,5);
for k=1:out.logsout.numElements
 e=out.logsout.get(k); walk(e.Values,e.Name);
end
T=cell2table(rows,'VariableNames',{'senal','tiempoInicial_s','tiempoFinal_s','muestras','cubreParada'});
T.constanteTiempoInfinito=false(height(T),1);
for k=1:out.logsout.numElements
 e=out.logsout.get(k);
 try
  ts=get_param(e.BlockPath.getBlock(1),'CompiledSampleTime');
  if isnumeric(ts) && isinf(ts(1)),T.constanteTiempoInfinito(strcmp(T.senal,e.Name))=true;end
 catch
 end
end
writetable(T,fullfile(folder,'cobertura_registro.csv'));
meta=jsondecode(fileread(fullfile(folder,'metadatos.json')));
meta.registroNativoCompleto=all(T.cubreParada|T.constanteTiempoInfinito);
meta.hojasDinamicasCompletas=sum(T.cubreParada);
meta.hojasConstantes=sum(T.constanteTiempoInfinito);
meta.coberturaRegistroCSV='cobertura_registro.csv';
meta.pruebaValida=true;meta.entregaCompleta=q.done;
meta.limite180Aplicado=false;
meta.autorizacionDuracion='Usuario autorizo completar la referencia con antisway mas alla de 180 s si continuaba sin fallas.';
telemetria=q.telemetry;
save(fullfile(folder,'telemetria_operador_completa.mat'),'telemetria');
fid=fopen(fullfile(folder,'metadatos.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);
D=load(fullfile(folder,'datos_derivados.mat'),'t','S');t=D.t;S=D.S;
f=figure('Visible','off','Position',[50 50 1200 950]);tiledlayout(4,2,'TileSpacing','compact');
draw(S.x_carro_fisica,S.mon_xRef,'Carro [m]');
draw(S.y_carga_fisica,S.mon_yRef,'Izaje [m]');
draw(S.v_carro_fisica,S.mon_vxRef,'Velocidad carro [m/s]');
draw(S.v_izaje_fisica,S.mon_vyRef,'Velocidad izaje [m/s]');
draw(S.ax,S.mon_axRef,'Aceleracion carro [m/s^2]');
draw(S.ay,S.mon_ayRef,'Aceleracion izaje [m/s^2]');
draw(S.angulo_fisico,S.angulo_referencia,'Angulo [rad]');
draw(S.velocidad_angular_fisica,S.omega_referencia,'Velocidad angular [rad/s]');
sgtitle('SFC con antisway: medio ciclo completo');
exportgraphics(f,fullfile(folder,'dinamica_referencia_antisway.png'),'Resolution',140);close(f);
f=figure('Visible','off','Position',[50 50 1100 1000]);tiledlayout(4,1,'TileSpacing','compact');
draw(S.torque_carro_fisico_motor,S.torque_carro_consigna_controlador,'Torque carro [Nm]');
title('Registro completo: incluye transitorio de inicializacion de la consigna');
nexttile;op=t>=q.events(1,2);plot(t(op),S.torque_carro_fisico_motor(op),t(op),S.torque_carro_consigna_controlador(op));grid on;axis padded;xlim([t(find(op,1)) t(end)]);ylabel('Carro operativo [Nm]');xlabel('Tiempo [s]');legend('Fisico','Consigna','Location','best');
draw(S.torque_izaje_fisico_motor,S.torque_izaje_consigna_controlador,'Torque izaje [Nm]');
nexttile;plot(t,S.v_ref,t,S.v_cmd,t,S.antisway_efectiva);grid on;axis padded;xlim([0 t(end)]);ylabel('Velocidad [m/s]');xlabel('Tiempo [s]');legend('Referencia MC','Comando MC','Antisway efectiva','Location','best');
sgtitle('Actuacion y correccion antisway');exportgraphics(f,fullfile(folder,'torques_referencia_antisway.png'),'Resolution',140);close(f);
fprintf('COBERTURA: %d/%d hojas cubren parada %.2f s.\n',sum(T.cubreParada),height(T),q.lastT);
 function walk(v,n)
  if isa(v,'timeseries') && ~isempty(v.Time)
   rows(end+1,:)={n,v.Time(1),v.Time(end),numel(v.Time),v.Time(end)>=q.lastT-.04};
  elseif isstruct(v)
   fields=fieldnames(v);for j=1:numel(fields),walk(v.(fields{j}),[n '.' fields{j}]);end
  elseif isa(v,'Simulink.SimulationData.Dataset')
   for j=1:v.numElements,e=v.get(j);walk(e.Values,[n '.' e.Name]);end
  end
 end
 function draw(a,b,label)
  nexttile;plot(t,a,t,b);grid on;axis padded;xlim([0 t(end)]);ylabel(label);xlabel('Tiempo [s]');legend('Real / fisica','Referencia / consigna','Location','best');
 end
end
