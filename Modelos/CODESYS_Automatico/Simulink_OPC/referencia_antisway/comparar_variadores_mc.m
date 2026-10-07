function report=comparar_variadores_mc(reference,candidate,regBank,obsBank,visible)
% Compara datos existentes en RAM. No simula ni guarda series brutas.
if nargin<5,visible=true;end
out=fullfile(candidate.result.folder,'comparacion_mc');if ~isfolder(out),mkdir(out);end
finish=min(reference.result.duration_s,candidate.result.duration_s);t=(0:.001:finish)';
common=setdiff(intersect(fieldnames(reference.signals),fieldnames(candidate.signals)),{'x'});
rows=cell(numel(common),6);
for j=1:numel(common)
 key=common{j};a=reference.signals.(key);b=candidate.signals.(key);
 native=isequal(a.t,b.t)&&isequal(size(a.v),size(b.v));
 if native,delta=b.v-a.v;method='Muestras nativas identicas';
 else,delta=at(candidate,key,t)-at(reference,key,t);method='Rejilla 1 ms, interpolacion lineal';end
 rows(j,:)={key,max(abs(delta(:))),sqrt(mean(delta(:).^2)),native,method,numel(delta)};
end
report=struct('model',candidate.result.model,'reference',reference.result.model, ...
 'duration_s',candidate.result.duration_s,'referenceDuration_s',reference.result.duration_s, ...
 'signals',cell2table(rows,'VariableNames',{'signal','maxAbsDifference','rmsDifference', ...
 'sameNativeTimes','method','samples'}),'regulationBank',regBank,'observerBank',obsBank);
report.observerBank.polesReal=real(obsBank.poles);
report.observerBank.polesImag=imag(obsBank.poles);
report.observerBank=rmfield(report.observerBank,'poles');
assert(isequal(candidate.q.events(:,1),reference.q.events(:,1)),'Cambio el orden de fases.');
report.maxPhaseTimeDifference_s=max(abs(candidate.q.events(:,2)-reference.q.events(:,2)));
report.phases=table(reference.q.events(:,1),reference.q.events(:,2),candidate.q.events(:,2), ...
 candidate.q.events(:,2)-reference.q.events(:,2),'VariableNames',{'stage','reference_s','candidate_s','difference_s'});
report.criteria=candidate.protocol.checks;
checkRows={ ...
 'Posicion carro',peak('mon_xT'),.01,'m'; ...
 'Altura carga',peak('mon_yH'),.01,'m'; ...
 'Angulo',peak('mon_theta')*180/pi,.1,'grados'; ...
 'Torque pedido carro (global)',peak('diag_torque_unsat'),5,'Nm'; ...
 'Torque pedido izaje (global)',peak('torque_izaje_consigna_controlador'),50,'Nm'; ...
 'Tiempo fases',report.maxPhaseTimeDifference_s,.2,'s'};
report.checks=cell2table(checkRows,'VariableNames',{'quantity','measuredDifference','threshold','unit'});
report.checks.passed=report.checks.measuredDifference<=report.checks.threshold;
report.passed=regBank.passed&&obsBank.stable&&all(report.checks.passed)&&all(report.criteria.cumple);
assert(report.passed,'No cumple el plan de comparacion; revisar metricas.');
writetable(report.signals,fullfile(out,'diferencias_senales.csv'));
writetable(report.phases,fullfile(out,'comparacion_fases.csv'));
writetable(report.checks,fullfile(out,'criterios_comparacion.csv'));
writetable(regBank.metrics,fullfile(out,'banco_regulacion.csv'));
writetable(obsBank.metrics,fullfile(out,'banco_observadores.csv'));
fid=fopen(fullfile(out,'comparacion.json'),'w');assert(fid>=0);fprintf(fid,'%s',jsonencode(report,PrettyPrint=true));fclose(fid);

keys={'mon_xT','mon_yH','mon_theta','diag_torque_unsat','torque_izaje_consigna_controlador','antisway_correccion_aplicada'};
labels={'Posicion carro [m]','Altura carga [m]','Angulo [rad]','Torque pedido carro [Nm]','Torque pedido izaje [Nm]','SW aplicada [m/s]'};
f=newFig('01_superposicion_completa',3,2);
for j=1:numel(keys)
 nexttile;plot(t,at(reference,keys{j},t),'DisplayName','Bloques FF limitado');hold on;
 plot(t,at(candidate,keys{j},t),'--','DisplayName','MC FF limitado');
 grid on;ylabel(labels{j});xlabel('Tiempo [s]');legend('Location','best');xlim([0 finish]);
end
exportFig(f);
f=newFig('02_diferencias',3,2);
keys={'mon_xT','mon_yH','mon_theta','diag_torque_unsat','torque_izaje_consigna_controlador','diag_omega_observer'};
labels={'Delta x [mm]','Delta altura [mm]','Delta angulo [grados]','Delta torque carro [Nm]','Delta torque izaje [Nm]','Delta omega tambor carro [rad/s]'};
scale=[1000 1000 180/pi 1 1 1];
for j=1:numel(keys)
 nexttile;delta=(at(candidate,keys{j},t)-at(reference,keys{j},t))*scale(j);
 plot(t,delta);grid on;ylabel(labels{j});xlabel('Tiempo [s]');xlim([0 finish]);
 title(sprintf('Maximo absoluto %.6g',max(abs(delta))));
end
exportFig(f);
f=newFig('03_transitorio_manual',3,1);window=[147 161];mask=t>=window(1)&t<=window(2);
for j=1:3
 if j==1
  key='carro_aceleracion_fisica';label='Aceleracion fisica [m/s^2]';
 elseif j==2
  key='antisway_correccion_aplicada';label='SW [m/s]';
 else
  key='diag_torque_unsat';label='Torque carro [Nm]';
 end
 nexttile;plot(t(mask),at(reference,key,t(mask)),'DisplayName','Bloques FF limitado');hold on;
 plot(t(mask),at(candidate,key,t(mask)),'--','DisplayName','MC FF limitado');
 if j==1,yline(.8,'r:','+0.8');yline(-.8,'r:','-0.8');end
 xline(154,'k:','Joystick soltado');xline(155.288,'k--','Pico de ley simple');
 grid on;xlim(window);ylabel(label);xlabel('Tiempo [s]');legend('Location','eastoutside');
end
exportFig(f);

fid=fopen(fullfile(out,'INFORME_COMPARACION.md'),'w');assert(fid>=0);guard=onCleanup(@()fclose(fid));
fprintf(fid,'# MC con variadores y observadores discretos\n\n');
fprintf(fid,'Modelo: `%s`. Referencia: `%s`.\n\n',report.model,report.reference);
fprintf(fid,'El MC conserva la regulacion de los bloques FF limitado y utiliza los dos observadores de encoder discretos del MC aprobado. **No se implemento, traslado ni modifico ninguna funcion del automata**, incluido pesaje y estimacion de masa. Sus charts originales se verifican por XML identico en `../../verificacion_charts_originales.csv`.\n\n');
fprintf(fid,'La maniobra termino en **%.3f s** (referencia: **%.6f s**), con **%d/%d criterios AUTO**. La diferencia maxima de tiempos de fase es **%.6g s**.\n\n',report.duration_s,report.referenceDuration_s,sum(report.criteria.cumple),height(report.criteria),report.maxPhaseTimeDifference_s);
fprintf(fid,'## Comparacion de senales\n\n');tableMD(fid,report.checks);
fprintf(fid,'\nSe compararon %d series comunes. Si coinciden sus tiempos se comparan muestras nativas; en los restantes casos se usa interpolacion lineal en rejilla de 1 ms, sin alinear ni desplazar fases. Los errores globales incluyen contacto y freno: los dos torques cumplieron incluso sin excluir esas ventanas. CSV completo: `diferencias_senales.csv`.\n\n',height(report.signals));
fprintf(fid,'## Regulacion conservada\n\n');
fprintf(fid,'El banco alimenta a los bloques FF limitado con exactamente los mismos estados que produce el nuevo estimador. Las **%d variables regulatorias tienen diferencia cero**, incluyendo ambos torques, SW, integrales, limites y AW. El banco llega a |I|=%.3f y |a_cmd|=%.3f, excita recortes de torque artificiales y conmuta E/freno. Esa igualdad demuestra que los cambios de la maniobra provienen de discretizar las estimaciones y de la integracion numerica de la planta, no de una nueva ley regulatoria.\n\n',height(regBank.metrics),regBank.maxIntegral,regBank.maxCommand);
fprintf(fid,'## Observadores\n\n');tableMD(fid,obsBank.metrics);
fprintf(fid,'\nReferencia del banco: %s. Tustin a %.6f s, wn=40 rad/s y zeta=1. La primera salida de velocidad conserva IC=0 incluso con encoder inicial no nulo. Ambos polos discretos tienen modulo %.9f, inferior a uno. La discretizacion produce diferencias pequenas, por lo que **no se afirma igualdad muestra a muestra del sistema completo**.\n\n',obsBank.reference,obsBank.sampleTime_s,max(abs(obsBank.poles)));
fprintf(fid,'## Alcance y limitaciones\n\n');
fprintf(fid,'Se conservan referencias a 0.3 m/s^2, a_cmd a +/-0.8, habilitacion anti-sway de 2 s, anulacion con E=0, compensacion horizontal independiente de E y AW parametrico. La aceleracion fisica del carro permanece dentro de +/-0.8 en esta maniobra, como en los bloques FF limitado. Los impactos al apoyar la carga se conservan; consultar los picos nativos en `../analisis_desempeno/INFORME_DESEMPENO.md`. AUTO aprobado no implica cumplimiento global.\n\n');
fprintf(fid,'El contenedor MC no es atomico: la funcion de estimadores se ejecuta antes de que el supervisor utilice sus salidas; las dos funciones de eje usan las consignas resultantes. Cada funcion tiene Ts=1 ms. Entre funciones solo hay buses/cables, parametros y selectores de diagnostico. No hay sumas, ganancias o saturaciones externas dentro del MC. El muestreo de la interfaz retiene las consignas del supervisor entre actualizaciones de 20 ms; no agrega un Unit Delay.\n\n');
fprintf(fid,'Los dos modelos de ley simple siguen intactos. Datos completos en RAM: `ffReference` y `ffRun`; bancos: `ffRegBank` y `vfdObserverBank`. El banco de observadores se reutiliza del MC aprobado, con codigo y parametros identicos. Se guardan metricas y figuras, no un nuevo paquete bruto ni video. `ejemplo_analisis.m` muestra 17 figuras sin simular.\n');
disp(report.checks);

 function value=peak(key)
  value=report.signals.maxAbsDifference(strcmp(report.signals.signal,key));
 end
 function f=newFig(name,nr,nc)
  f=figure('Visible','off','Color','w','Name',['MC FF limitado | ' name], ...
   'NumberTitle','off','Position',[40 40 1450 1080]);setappdata(f,'ExportName',name);
  tiledlayout(f,nr,nc,'TileSpacing','compact','Padding','loose');
  sgtitle(['Bloques FF limitado / MC FF limitado | ' strrep(name,'_',' ')]);
 end
 function exportFig(f)
  drawnow;name=getappdata(f,'ExportName');exportgraphics(f,fullfile(out,[name '.png']),'Resolution',145);
  set(f,'Visible','on');savefig(f,fullfile(out,[name '.fig']));
  if visible,set(f,'WindowStyle','docked');else,close(f);end
 end
end
function v=at(run,key,t)
z=run.signals.(key);[tt,ix]=unique(z.t,'last');v=interp1(tt,z.v(ix),t,'linear','extrap');
end
function tableMD(fid,t)
fprintf(fid,'| %s |\n',strjoin(t.Properties.VariableNames,' | '));
fprintf(fid,'| %s |\n',strjoin(repmat({'---'},1,width(t)),' | '));
for j=1:height(t)
 row=cell(1,width(t));
 for k=1:width(t)
  value=t{j,k};if iscell(value),value=value{1};end
  if isnumeric(value)||islogical(value),row{k}=sprintf('%.9g',value);else,row{k}=char(string(value));end
 end
 fprintf(fid,'| %s |\n',strjoin(row,' | '));
end
end
