function report=analizar_desempeno_variadores(folder,visible,memoryData,referenceData)
% ANALIZAR_DESEMPENO Datos nativos, figuras editables e informe de una corrida.
% No simula, no modifica el SLX ni los MAT de entrada.
if nargin<2,visible=true;end
folder=char(folder);
if nargin<3
    d=load(fullfile(folder,'senales_nativas.mat'),'signals','q','result');
else
    d=memoryData;
end
s=d.signals;q=d.q;r=d.result;
p=leerParametros(fullfile(folder,'codigo_ensayado'));
out=fullfile(folder,'analisis_desempeno');
if ~isfolder(out),mkdir(out);end
% Unificar tiempos repetidos solo en memoria, conservando la ultima muestra.
fields=fieldnames(s);
for k=1:numel(fields)
    z=s.(fields{k});
    if size(z.v,1)~=numel(z.t) && size(z.v,2)==numel(z.t),z.v=z.v.';end
    assert(size(z.v,1)==numel(z.t),'Formato temporal inesperado: %s',fields{k});
    [tt,ix]=unique(z.t,'last');s.(fields{k}).t=tt;s.(fields{k}).v=z.v(ix,:);
end
t=(0:.02:r.duration_s)';
recordedFields=fields;
origins=cell(0,3);
% Compatibilidad con la corrida anterior, que no registro F_contacto directamente.
if ~isfield(s,'carga_aceleracion_vertical_fisica')
    s.carga_aceleracion_vertical_fisica=s.(r.alias.load_acc2);
    origins(end+1,:)={'carga_aceleracion_vertical_fisica','Registrada','Alias del Divide1 de la dinamica vertical'};
end
if ~isfield(s,'carga_velocidad_vertical_fisica')
    s.carga_velocidad_vertical_fisica=s.mon_vH;
    origins(end+1,:)={'carga_velocidad_vertical_fisica','Registrada con decimacion','mon_vH proviene de v_ly; conserva sus tiempos propios'};
end
if ~isfield(s,'fuerza_contacto_vertical')
    az=s.carga_aceleracion_vertical_fisica;ta=az.t;
    m=at(s.masa_total_fisica,ta);ft=at(s.planta_tension_cable,ta);theta=at(s.planta_angulo_real,ta);
    s.fuerza_contacto_vertical=struct('t',ta,'v',m.*(az.v+p.g)-2*ft.*cos(theta));
    origins(end+1,:)={'fuerza_contacto_vertical','Reconstruida','F_cy = m*(a_y+g) - 2*F_hw*cos(theta), balance de la planta'};
end
if ~isfield(s,'penetracion_geometrica_contacto')
    surface=s.yc_xl;ts=surface.t;m=at(s.masa_total_fisica,ts);
    s.penetracion_geometrica_contacto=struct('t',ts,'v',surface.v+p.H_c*double(m>p.M_s+1)-at(s.planta_posicion_carga_y,ts));
    origins(end+1,:)={'penetracion_geometrica_contacto','Reconstruida','y_superficie + altura fisica de carga - y_carga'};
end
fields=fieldnames(s);
keys={'sup_modeCode','sup_loadedState','mon_xT','diag_xref_input','carro_velocidad_real', ...
 'diag_vref_input','diag_vcmd','diag_aref_input','diag_acmd','diag_acmd_applied', ...
 'carro_aceleracion_fisica','diag_integral','diag_p','diag_i', ...
 'aw_delta_a_limite_memoria','aw_delta_a_torque','aw_delta_a_total','aw_delta_torque_Nm', ...
 'diag_torque_unsat','torque_carro_entrada_planta','torque_carro_limitado','torque_carro_fisico_motor', ...
 'diag_vdrum','mon_yH','mon_yRef','mon_vH','mon_vyRef','mon_ayRef','mon_aHoistMeasured', ...
 'carga_velocidad_vertical_fisica','carga_aceleracion_vertical_fisica','planta_posicion_carga_y', ...
 'fuerza_contacto_vertical','penetracion_geometrica_contacto','mon_contact4', ...
 'torque_izaje_consigna_controlador','torque_izaje_entrada_planta','torque_izaje_fisico_motor', ...
 'Thm_sat','T_hmMax','freno_operacion_izaje_torque','tambor_izaje_velocidad_angular', ...
 'n0_brakeHoistOpen','n0_brakeTrolleyOpen','diag_brake_torque', ...
 'mon_theta','angulo_referencia','antisway_correccion_aplicada','sw_feedback_comun', ...
 'sw_anticipacion_comun','mon_swayEnable','mando_manual_izaje','masa_total_fisica', ...
 'masa_contenedor_estimada','masa_estimada_valida','planta_tension_cable','transferencia_antisway'};
g=struct;
for k=1:numel(keys),g.(keys{k})=at(s.(keys{k}),t);end
% Posiciones continuas: mismo muestreo lineal que el protocolo de validacion.
% Los modos, banderas y restantes mandos conservan retencion de muestra.
positionKeys={'mon_xT','diag_xref_input','mon_yH','mon_yRef','planta_posicion_carga_y'};
for k=1:numel(positionKeys)
    z=s.(positionKeys{k});g.(positionKeys{k})=interp1(z.t,z.v,t,'linear','extrap');
end
mode=g.sup_modeCode;loaded=g.sup_loadedState>.5;
ex=g.mon_xT-g.diag_xref_input;ey=g.mon_yH-g.mon_yRef;
power=g.torque_izaje_fisico_motor.*g.tambor_izaje_velocidad_angular*p.i_h/1000;
report=struct('modelo',r.model,'duracion_s',r.duration_s,'termino',q.done, ...
 'aborto',q.abort,'numero_senales',numel(recordedFields),'parametros',p,'carpeta',folder);
report.origenSenales=cell2table(origins,'VariableNames',{'senal','tipo','metodo'});
report.maniobra='manual anterior';
if isfield(q,'slowConfig'),report.maniobra='descenso lento';end
if nargin<3
    rr=load(fullfile(folder,'resultado_ensayo.mat'),'report');
else
    rr=struct('report',d.protocol);
end
report.datosEnMemoria=nargin>=3;
report.criterios=rr.report.checks;
report.resumenProtocolo=rr.report;report.aprobado=all(report.criterios.cumple);
report.grilla_figuras_s=.02;
report.metodo='Picos nativos sin filtrar; posiciones interpoladas linealmente en rejilla de 20 ms como el protocolo; restantes senales con retencion; duraciones de exceso con retencion de muestra nativa.';
spec={ ...
 'carro_aceleracion_fisica','Aceleracion fisica carro','m/s^2',p.a_tmax,1; ...
 'carga_aceleracion_vertical_fisica','Aceleracion vertical fisica carga','m/s^2',p.a_hmax,1; ...
 'carro_velocidad_real','Velocidad fisica carro','m/s',p.v_tmax,1; ...
 'carga_velocidad_vertical_fisica','Velocidad vertical fisica carga','m/s',p.v_hmax,1; ...
 'diag_acmd_applied','Aceleracion de mando carro','m/s^2',p.a_tmax,1; ...
 'diag_torque_unsat','Torque pedido carro','Nm',p.T_tmMax,1; ...
 'torque_carro_fisico_motor','Torque motor carro','Nm',p.T_tmMax,1; ...
 'torque_izaje_consigna_controlador','Torque pedido izaje','Nm',p.T_hmMax,1; ...
 'torque_izaje_fisico_motor','Torque motor izaje','Nm',p.T_hmMax,1; ...
 'fuerza_contacto_vertical','Fuerza de contacto vertical','N',NaN,1; ...
 'freno_operacion_izaje_torque','Torque freno izaje','Nm',p.T_hbMax,1; ...
 'planta_tension_cable','Tension cable','N',NaN,1; ...
 'diag_integral','Estado integral carro','m',p.a_tmax/p.Ki,1; ...
 'mon_theta','Angulo de balanceo','grados',NaN,180/pi};
rows=cell(size(spec,1),9);
for k=1:size(spec,1)
    z=s.(spec{k,1});v=z.v*spec{k,5};[pk,ix]=max(abs(v));tm=z.t(ix);
    lim=spec{k,4};over=NaN;if isfinite(lim),over=duracion(z.t,abs(v)>lim);end
    rows(k,:)={spec{k,2},spec{k,3},pk,v(ix),tm,at(s.sup_modeCode,tm), ...
        at(s.sup_loadedState,tm),lim,over};
end
report.picos=cell2table(rows,'VariableNames',{'senal','unidad','max_abs','valor','tiempo_s', ...
    'modo','cargado','limite_referencia','tiempo_exceso_s'});
groups=cell(0,10);
for code=unique(mode)'
    for loadFlag=0:1
        mask=mode==code & loaded==logical(loadFlag);if ~any(mask),continue;end
        groups(end+1,:)={code,loadFlag,sum(mask)*.02,max(abs(ex(mask))),sqrt(mean(ex(mask).^2)), ...
            max(abs(ey(mask))),sqrt(mean(ey(mask).^2)),max(abs(rad2deg(g.mon_theta(mask)))), ...
            max(abs(g.carro_velocidad_real(mask))),max(abs(g.carga_velocidad_vertical_fisica(mask)))}; %#ok<AGROW>
    end
end
report.porModo=cell2table(groups,'VariableNames',{'modo','cargado','duracion_aprox_s','errorX_max_m', ...
 'errorX_rms_m','errorY_max_m','errorY_rms_m','angulo_max_deg','vCarro_max_mps','vCarga_max_mps'});
md=s.sup_modeCode;ix=[1;find(diff(md.v)~=0)+1];
report.modos=table(md.t(ix),md.v(ix),'VariableNames',{'tiempo_s','modo_codigo'});
stageNames={'Arranque','Barrido','Aproximacion manual vacio','Toma y cierre twistlocks', ...
 'Elevacion manual cargada','Pedido automatico cargado','Automatico cargado','Descenso manual cargado', ...
 'Entrega y apertura twistlocks','Elevacion manual vacia','Pedido automatico vacio','Automatico vacio','Parada normal'};
e=q.events;finish=[e(2:end,2);r.duration_s];
report.etapas=table(e(:,1),string(stageNames(e(:,1)))',e(:,2),finish,finish-e(:,2), ...
 'VariableNames',{'etapa','nombre','inicio_s','fin_s','duracion_s'});
report.contactos=medirContactos(s,q);
valid=s.masa_estimada_valida;iv=find(valid.v>.5,1);
report.pesaje=struct('valido_s',valid.t(iv), ...
 'contacto_al_validar_N',at(s.fuerza_contacto_vertical,valid.t(iv)), ...
 'masa_estimada_auto_kg',rr.report.masaEstimadaTotalCargada_kg, ...
 'masa_fisica_auto_kg',rr.report.masaFisicaTotalCargada_kg, ...
 'vFinalConMasaCorrecta_mps',0.20*min(3,max(1.5,97500/rr.report.masaFisicaTotalCargada_kg)));
report.maxSW_E0=max(abs(g.antisway_correccion_aplicada(g.mon_swayEnable<.5)));
report.maxAWTorque=max(abs(s.aw_delta_torque_Nm.v));
report.maxAWAceleracion=max(abs(s.aw_delta_a_limite.v));
report.torqueSaturado_s=duracion(s.aw_delta_torque_Nm.t,abs(s.aw_delta_torque_Nm.v)>1e-9);
report.mandoSaturado_s=duracion(s.aw_delta_a_limite.t,abs(s.aw_delta_a_limite.v)>1e-9);
report.maxPotenciaIzaje_kW=max(abs(power));
report.errorSumaAW=max(abs(g.aw_delta_a_total-g.aw_delta_a_limite_memoria-g.aw_delta_a_torque));
report.maxErrorYAuto_m=max(abs(ey(mode==4)));
report.maxErrorXAuto_m=max(abs(ex(mode==4)));
z=s.mon_aHoistMeasured;nativeMode=at(s.sup_modeCode,z.t);
report.maxAceleracionIzajeEstimadaAuto=max(abs(z.v(nativeMode==4)));
assert(nargin>=4,'Se requiere la referencia R2 en RAM. Para ver las figuras guardadas use ejemplo_analisis.');
report.comparisonKind='ff_limitado';
report.analysisLabel='MC FF limitado | estimadores Tustin 1 ms';
comparisonNames={'magnitud','Bloques_FF','MC_FF'};
baseline=referenceData.result.model;
report.comparisonSource=baseline;
bd=struct('report',referenceData.protocol);
old=bd.report;
report.comparacion=table( ...
 ["Duracion [s]";"Error relativo masa [%]";"Aceleracion izaje estimada AUTO [m/s^2]"; ...
 "Error vertical AUTO [m]";"Torque motor izaje AUTO [Nm]";"Angulo AUTO [grados]"], ...
 [old.duration_s;100*old.errorEstimacionMasa_relativo;old.maxAceleracionIzajeAuto_mps2; ...
 old.maxErrorYAuto_m;old.maxTorqueIzajeFisico_Nm;old.maxAnguloAuto_deg], ...
 [rr.report.duration_s;100*rr.report.errorEstimacionMasa_relativo;rr.report.maxAceleracionIzajeAuto_mps2; ...
 rr.report.maxErrorYAuto_m;rr.report.maxTorqueIzajeFisico_Nm;rr.report.maxAnguloAuto_deg], ...
 'VariableNames',comparisonNames);
writetable(report.picos,fullfile(out,'picos_nativos.csv'));
writetable(report.porModo,fullfile(out,'desempeno_por_modo.csv'));
writetable(report.contactos,fullfile(out,'contactos.csv'));
writetable(report.etapas,fullfile(out,'duraciones_etapas.csv'));
writetable(report.modos,fullfile(out,'eventos_modo.csv'));
writetable(report.comparacion,fullfile(out,'comparacion_anterior.csv'));
writetable(report.criterios,fullfile(out,'criterios.csv'));
writetable(report.origenSenales,fullfile(out,'origen_senales_complementarias.csv'));
if isfield(q,'slowApproach')
    writetable(array2table(q.slowApproach,'VariableNames',{'tiempo_s','etapa','fase','altura_apoyo_m','distancia_m','joystick'}), ...
        fullfile(out,'consignas_descenso_lento.csv'));
end
inventory=cell(numel(fields),3);
for k=1:numel(fields),z=s.(fields{k});inventory(k,:)={fields{k},numel(z.t),size(z.v,2)};end
writetable(cell2table(inventory,'VariableNames',{'senal','muestras','canales'}),fullfile(out,'inventario_senales.csv'));
% Figuras de conjunto: rejilla de presentacion de 20 ms.
f=newFig('01_cronologia',2,1);nexttile;stairs(t,mode,'LineWidth',1.4);yticks(0:9);
yticklabels({'Apagado','Arranque','Listo','Manual','Auto','Parada','Falla','A manual','A auto','Barrido'});
ylabel('Modo efectivo');grid on;
nexttile;stairs(t,loaded,'DisplayName','Carga colgada');hold on;
stairs(t,g.mon_contact4,'DisplayName','Contacto');stairs(t,g.mon_swayEnable,'DisplayName','Anti-sway E');
legend('Location','eastoutside');ylabel('Estado');grid on;exportFig(f);
f=newFig('02_seguimiento',3,1);
panel({'mon_xT','diag_xref_input'},{'Carro real','xRef'},'x [m]');
panel({'mon_yH','mon_yRef','planta_posicion_carga_y'},{'Altura observada','yRef','Carga fisica'},'y [m]');
nexttile;plot(t,ex,'DisplayName','Error X');hold on;plot(t,ey,'DisplayName','Error Y');
legend('Location','eastoutside');ylabel('Error [m]');grid on;exportFig(f);
f=newFig('03_cinematica_carro',3,1);
panel({'carro_velocidad_real','diag_vref_input','diag_vcmd'}, ...
 {'Velocidad fisica','vRef nominal','v objetivo con correcciones'},'v [m/s]');
panel({'diag_aref_input','diag_acmd_applied','carro_aceleracion_fisica'}, ...
 {'aRef','a_cmd','Aceleracion fisica'},'a [m/s^2]');yline(p.a_tmax,'r--');yline(-p.a_tmax,'r--');
panel({'diag_aref_input','diag_p','diag_i'},{'FF aRef','P','I'},'Contribucion [m/s^2]');exportFig(f);
f=newFig('04_cinematica_izaje',3,1);
panel({'mando_manual_izaje','mon_vyRef','mon_vH','carga_velocidad_vertical_fisica'}, ...
 {'Objetivo manual','vRef','Velocidad observada','Velocidad fisica carga'},'v [m/s]');
panel({'mon_ayRef','mon_aHoistMeasured','carga_aceleracion_vertical_fisica'}, ...
 {'aRef','Aceleracion estimada','Aceleracion fisica carga'},'a [m/s^2]');yline(p.a_hmax,'r--');yline(-p.a_hmax,'r--');
panel({'penetracion_geometrica_contacto'},{'Positiva: penetracion; negativa: separacion'},'Penetracion [m]');exportFig(f);
f=newFig('05_balanceo_antisway',3,1);
nexttile;plot(t,rad2deg(g.mon_theta),'DisplayName','Angulo real');hold on;
plot(t,rad2deg(g.angulo_referencia),'DisplayName','Angulo referencia');ylabel('Angulo [grados]');grid on;legend('Location','eastoutside');
panel({'sw_feedback_comun','sw_anticipacion_comun','antisway_correccion_aplicada'}, ...
 {'Amortiguacion','Anticipacion','Correccion aplicada'},'v_sw [m/s]');
panel({'mon_swayEnable','transferencia_antisway'},{'E','Transferencia en la referencia'},'Estado / m/s');exportFig(f);
f=newFig('06_torque_carro_AW',4,1);
panel({'diag_torque_unsat','torque_carro_entrada_planta','torque_carro_limitado','torque_carro_fisico_motor'}, ...
 {'Pedido N2','Entrada planta','Limitado drive','Motor fisico'},'Torque [Nm]');yline(p.T_tmMax,'r--');yline(-p.T_tmMax,'r--');
panel({'aw_delta_torque_Nm'},{'Limitado - entrada drive'},'Recorte [Nm]');
panel({'aw_delta_a_limite_memoria','aw_delta_a_torque','aw_delta_a_total'}, ...
 {'Por aceleracion','Por torque','Total AW'},'Correccion [m/s^2]');
panel({'diag_integral'},{'Estado integral'},'I [m]');yline(p.a_tmax/p.Ki,'r--');yline(-p.a_tmax/p.Ki,'r--');exportFig(f);
f=newFig('07_torque_izaje',3,1);
panel({'torque_izaje_consigna_controlador','torque_izaje_entrada_planta','Thm_sat','torque_izaje_fisico_motor'}, ...
 {'Pedido N2','Entrada planta','Limitado drive','Motor fisico'},'Torque [Nm]');
plot(t,g.T_hmMax,'k--','DisplayName','Limite drive positivo');plot(t,-g.T_hmMax,'k:','DisplayName','Limite drive negativo');
nexttile;plot(t,power);ylabel('Potencia motor [kW]');grid on;
panel({'planta_tension_cable','fuerza_contacto_vertical'},{'Tension cable','Contacto reconstruido'},'Fuerza [N]');exportFig(f);
f=newFig('08_frenos',3,1);
panel({'n0_brakeHoistOpen','n0_brakeTrolleyOpen'},{'Permiso apertura N0 izaje','Permiso apertura N0 carro'},'Permiso N0');
panel({'freno_operacion_izaje_torque','diag_brake_torque'},{'Freno izaje','Freno carro'},'Torque freno [Nm]');
panel({'mon_vH','carga_velocidad_vertical_fisica'},{'Velocidad observada izaje','Velocidad fisica carga'},'v [m/s]');exportFig(f);
for ci=1:height(report.contactos)
    tc=report.contactos.contacto_s(ci);tw=[tc-8 tc+4];
    f=newFig(sprintf('%02d_contacto_%d',8+ci,ci),4,1);
    nativePanel({'carga_velocidad_vertical_fisica','mon_vH','mon_vyRef'}, ...
        {'Carga fisica','Observada','Referencia'},'v [m/s]',tw);
    nativePanel({'carga_aceleracion_vertical_fisica','mon_aHoistMeasured'}, ...
        {'Carga fisica','Estimada desde motor'},'a [m/s^2]',tw);yline(p.a_hmax,'r--');yline(-p.a_hmax,'r--');
    nativePanel({'fuerza_contacto_vertical','planta_tension_cable'}, ...
        {'Contacto reconstruido','Tension cable'},'Fuerza [N]',tw);
    nativePanel({'torque_izaje_fisico_motor','freno_operacion_izaje_torque'}, ...
        {'Motor fisico','Freno operacion'},'Torque [Nm]',tw);
    ax=findall(f,'Type','axes');for ai=1:numel(ax),xline(ax(ai),tc,'k--','Primer contacto >1 kN','HandleVisibility','off');end
    exportFig(f);
end
f=newFig('11_transiciones',3,2);
trans=[q.autoRequests(1,1),q.events(q.events(:,1)==13,2)];
for ci=1:numel(trans)
    tw=[trans(ci)-2 trans(ci)+4];
    nexttile(ci);plot(t,g.diag_vcmd,'DisplayName','Objetivo corregido');hold on;
    plot(t,g.carro_velocidad_real,'DisplayName','Fisica');ylabel('v carro [m/s]');grid on;legend;xlim(tw);xline(trans(ci),'k--');
    nexttile(ci+2);plot(t,g.diag_acmd_applied,'DisplayName','a_cmd');hold on;
    plot(t,g.carro_aceleracion_fisica,'DisplayName','Fisica');ylabel('a carro [m/s^2]');grid on;legend;xlim(tw);xline(trans(ci),'k--');
    nexttile(ci+4);plot(t,g.diag_integral,'DisplayName','Integrador');hold on;
    plot(t,g.antisway_correccion_aplicada,'DisplayName','v_sw');plot(t,g.transferencia_antisway,'DisplayName','Transferencia');
    ylabel('I [m] / v [m/s]');grid on;legend;xlim(tw);xline(trans(ci),'k--');
end
exportFig(f);
f=newFig('12_perfil_relevado',1,1);nexttile;
xc=p.xmin+((1:numel(q.initialProfile))'-.5)*p.slotWidth;
stairs(xc,q.initialProfile,'DisplayName','Inicial');hold on;stairs(xc,q.scannedProfile,'DisplayName','Relevado');
stairs(xc,q.finalProfile,'DisplayName','Final');xlabel('x [m]');ylabel('Superficie [m]');grid on;legend;exportFig(f);
f=newFig('13_estimacion_masa',3,1);nexttile;
plot(t,g.masa_total_fisica/1000,'DisplayName','Masa total fisica');hold on;
plot(t,(15000+g.masa_contenedor_estimada)/1000,'DisplayName','Masa total estimada');
ylabel('Masa [t]');grid on;legend('Location','eastoutside','AutoUpdate','off');
nexttile;plot(t,g.planta_tension_cable/1000,'DisplayName','Tension cable');hold on;
plot(t,g.fuerza_contacto_vertical/1000,'DisplayName','Apoyo reconstruido');
ylabel('Fuerza [kN]');grid on;legend('Location','eastoutside','AutoUpdate','off');
nexttile;stairs(t,g.masa_estimada_valida,'DisplayName','Estimacion valida');hold on;
plot(t,g.mon_vH,'DisplayName','Velocidad observada');plot(t,g.carga_velocidad_vertical_fisica,'DisplayName','Velocidad fisica carga');
ylabel('Estado / m/s');grid on;legend('Location','eastoutside','AutoUpdate','off');
ax=findall(f,'Type','axes');
for ai=1:numel(ax)
    xlim(ax(ai),[report.contactos.contacto_s(1)-1 report.contactos.contacto_s(1)+10]);
    xline(ax(ai),report.pesaje.valido_s,'k--','Masa declarada valida','HandleVisibility','off');
end
exportFig(f);
save(fullfile(out,'desempeno.mat'),'report','-v7.3');
fid=fopen(fullfile(out,'desempeno.json'),'w');assert(fid>=0);fprintf(fid,'%s',jsonencode(report,PrettyPrint=true));fclose(fid);
escribir_informe_desempeno_mc_r2(report,out,q);
fprintf('ANALISIS: %.3f s, %d/%d criterios, %d senales.\n',r.duration_s, ...
 sum(report.criterios.cumple),height(report.criterios),numel(recordedFields));
disp(report.contactos);disp(report.comparacion);
    function f=newFig(name,nrows,ncols)
        displayName=[report.analysisLabel ' | ' strrep(name,'_',' ')];
        candidates=findall(groot,'Type','figure','Name',displayName);f=[];
        for fi=1:numel(candidates)
            if isappdata(candidates(fi),'AnalysisExportName'),f=candidates(fi);break;end
        end
        if isempty(f),f=figure;else,clf(f);end
        set(f,'Visible','off','WindowStyle','normal','Color','w','Name',displayName,'NumberTitle','off','Position',[40 40 1450 1100]);
        setappdata(f,'AnalysisExportName',name);
        setappdata(f,'AnalysisSourceFolder',folder);
        figure(f);set(f,'Visible','off');
        tiledlayout(f,nrows,ncols,'TileSpacing','compact','Padding','loose');sgtitle(displayName,'Interpreter','none');
    end
    function panel(names,labels,unit)
        nexttile;hold on;
        for j=1:numel(names),plot(t,g.(names{j}),'DisplayName',labels{j},'LineWidth',1);end
        ylabel(unit);grid on;legend('Location','eastoutside','Interpreter','none','AutoUpdate','off');xlim([0 r.duration_s]);
    end
    function nativePanel(names,labels,unit,tw)
        nexttile;hold on;
        scale=1;
        if strcmp(unit,'Fuerza [N]'),scale=1e-3;unit='Fuerza [kN]';end
        if strcmp(unit,'Torque [Nm]'),scale=1e-3;unit='Torque [kNm]';end
        for j=1:numel(names),zz=s.(names{j});mask=zz.t>=tw(1)&zz.t<=tw(2);plot(zz.t(mask),scale*zz.v(mask),'DisplayName',labels{j});end
        ylabel(unit);grid on;legend('Location','eastoutside','Interpreter','none','AutoUpdate','off');xlim(tw);
    end
    function exportFig(f)
        axs=findall(f,'Type','axes');
        for j=1:numel(axs),xlabel(axs(j),'Tiempo [s]');end
        if strcmp(getappdata(f,'AnalysisExportName'),'12_perfil_relevado'),xlabel(axs,'x [m]');end
        name=getappdata(f,'AnalysisExportName');
        drawnow;
        exportgraphics(f,fullfile(out,[name '.png']),'Resolution',150);
        % Guardar visible para que openfig no herede el estado oculto.
        set(f,'Visible','on');savefig(f,fullfile(out,[name '.fig']));
        if visible,set(f,'WindowStyle','docked');drawnow;else,close(f);end
    end
end
function p=leerParametros(codeFolder)
% Ejecutar solo la copia de parametros del ensayo en este espacio local.
run(fullfile(codeFolder,'parametros_ganancias_cascada_29072026.m'));
p=struct('Ts',T_s,'a_tmax',dv_tmax,'a_hmax',dv_hmax,'v_tmax',v_tmax, ...
 'v_hmax',v_hmaxUnloaded,'T_tmMax',T_tmMax,'T_hmMax',T_hmMax, ...
 'T_hbMax',T_hbMax,'Ki',K_iv_cas,'i_h',i_h,'i_t',i_t, ...
 'r_td',r_td,'M_EQt',M_EQt,'xmin',x_tmin,'slotWidth',W_c,'g',g,'M_s',M_s,'H_c',H_c);
if exist('T_SW_on','var'),p.T_SW_on=T_SW_on;end
end
function v=at(z,t)
v=interp1(z.t,z.v,t,'previous','extrap');
end
function seconds=duracion(t,mask)
seconds=sum(diff(t).*double(mask(1:end-1)));
end
function rows=medirContactos(s,q)
out=cell(2,13);
phase=q.approachEvents(q.approachEvents(:,1)==4,2);
starts=[phase(end);q.events(q.events(:,1)==8,2)];
ends=[q.events(q.events(:,1)==4,2);q.events(q.events(:,1)==9,2)];
fc=s.fuerza_contacto_vertical;vy=s.carga_velocidad_vertical_fisica;
ay=s.carga_aceleracion_vertical_fisica;tm=s.torque_izaje_fisico_motor;br=s.freno_operacion_izaje_torque;
for k=1:2
    idx=find(fc.t>=starts(k)&fc.t<=ends(k)&fc.v>1000,1);assert(~isempty(idx),'No se detecto contacto %d',k);
    tc=fc.t(idx);prev=find(vy.t<tc,1,'last');
    wm=fc.t>=tc-.5&fc.t<=tc+3;am=ay.t>=tc-.5&ay.t<=tc+3;
    mm=tm.t>=tc-.5&tm.t<=tc+3;bm=br.t>=tc-.5&br.t<=tc+3;
    tail=vy.t>=tc-5 & vy.t<tc;
    command=at(s.mando_manual_izaje,tc-.2);
    slowDuration=0;
    if isfield(q,'slowApproach')
        joy=q.slowApproach(:,6);jt=q.slowApproach(:,1);slowmask=jt>=starts(k)&jt<tc & abs(joy)<=q.slowConfig.joyFinal+1e-10;
        slowDuration=sum(slowmask)*.2;
    end
    out(k,:)={k,starts(k),tc,tc-starts(k),vy.v(prev),mean(abs(vy.v(tail))),command, ...
     max(fc.v(wm)),max(abs(ay.v(am))),max(abs(tm.v(mm))),max(abs(br.v(bm))), ...
     slowDuration,at(s.n0_brakeHoistOpen,tc)};
end
rows=cell2table(out,'VariableNames',{'contacto','inicio_descenso_s','contacto_s','duracion_descenso_s', ...
 'vCarga_precontacto_mps','vCarga_media_ultimos5s_mps','objetivoManual_precontacto_mps', ...
 'fuerza_max_N','aCarga_max_mps2','torqueMotor_max_Nm','torqueFreno_max_Nm','tramo_lento_aprox_s','permiso_N0_apertura_contacto'});
end

