function summary=analizar_ley_ff(candidate,blocks,simple,bank,comparison,visible)
% Verifica la ley sobre señales ya simuladas y compara el pico manual.
if nargin<6,visible=true;end
out=fullfile(candidate.result.folder,'analisis_ff');if ~isfolder(out),mkdir(out);end
s=candidate.signals;a=s.sw_habilitacion_comun;tt=a.t;alpha=a.v;
anticipation=at(s.sw_anticipacion_comun,tt);feedback=at(s.sw_feedback_comun,tt);
rawFeedback=at(s.diag_sw_unsat,tt);sw=at(s.antisway_correccion_aplicada,tt);
ff=zeros(size(alpha));enabled=alpha>0;ff(enabled)=anticipation(enabled)./alpha(enabled);
dt=diff(tt);both=enabled(1:end-1)&enabled(2:end)&dt>0;
slope=diff(ff);slope=slope(both)./dt(both);
summary=struct('model',candidate.result.model,'duration_s',candidate.result.duration_s, ...
 'autoPassed',sum(candidate.protocol.checks.cumple),'autoTotal',height(candidate.protocol.checks), ...
 'sameInputRegulationExact',all(bank.metrics.maxAbsDifference==0), ...
 'comparedSignals',height(comparison.signals),'ffRateLimit_mps2',0.25, ...
 'ffMaxRate_mps2',max(abs(slope)), ...
 'feedbackLawResidual_mps',max(abs(feedback-alpha.*rawFeedback)), ...
 'sumLawResidual_mps',max(abs(sw-min(3.2,max(-3.2,feedback+anticipation)))), ...
 'maxSWWithAlphaZero_mps',max(abs(sw(~enabled))), ...
 'rawDataSaved',false,'videoSaved',false);
summary.cartPeakBlocks=peak(blocks.signals.carro_aceleracion_fisica);
summary.cartPeakMC=peak(s.carro_aceleracion_fisica);
summary.cartPeakSimple=peak(simple.signals.carro_aceleracion_fisica);
summary.maxCommand_mps2=max(abs(s.diag_acmd_applied.v));
summary.maxTorqueClipping_Nm=max(abs(s.aw_delta_torque_Nm.v));
summary.passed=summary.sameInputRegulationExact && comparison.passed && ...
 summary.ffMaxRate_mps2<=summary.ffRateLimit_mps2+1e-8 && ...
 summary.feedbackLawResidual_mps<1e-10 && summary.sumLawResidual_mps<1e-10 && ...
 summary.maxSWWithAlphaZero_mps==0 && summary.cartPeakMC.absolute<=0.8;
assert(summary.passed,'Revisar verificacion de ley FF.');
fid=fopen(fullfile(out,'metricas_ff.json'),'w');assert(fid>=0);
fprintf(fid,'%s',jsonencode(summary,PrettyPrint=true));fclose(fid);
f=figure('Visible','off','Color','w','Name','Comparacion de leyes anti-sway | parada manual', ...
 'NumberTitle','off','Position',[60 60 1450 1100]);
tiledlayout(f,4,1,'TileSpacing','compact','Padding','loose');
sgtitle('Mismas consignas | ley simple y anticipacion limitada | datos ya simulados');
window=[147 161];
keys={'carro_aceleracion_fisica','diag_acmd_applied','sw_anticipacion_comun','antisway_correccion_aplicada'};
labels={'a carro fisica [m/s^2]','a_cmd [m/s^2]','Anticipacion aplicada [m/s]','v_sw [m/s]'};
for j=1:numel(keys)
 nexttile;hold on;
 z=simple.signals.(keys{j});mask=z.t>=window(1)&z.t<=window(2);
 plot(z.t(mask),z.v(mask),'DisplayName','Bloques ley simple','LineWidth',1);
 z=blocks.signals.(keys{j});mask=z.t>=window(1)&z.t<=window(2);
 plot(z.t(mask),z.v(mask),'DisplayName','Bloques FF limitado','LineWidth',1);
 z=s.(keys{j});mask=z.t>=window(1)&z.t<=window(2);
 plot(z.t(mask),z.v(mask),'--','DisplayName','MC FF limitado','LineWidth',1);
 if j<=2
  yline(.8,'r:','Limite +0.8','HandleVisibility','off');
  yline(-.8,'r:','Limite -0.8','HandleVisibility','off');
 end
 if j==1
  p=summary.cartPeakSimple;xline(p.time_s,'Color',[.65 .1 .1], ...
   'Label',sprintf('Pico ley simple %.4f',p.value),'HandleVisibility','off');
  z=s.carro_aceleracion_fisica;mask=z.t>=window(1)&z.t<=window(2);q=peak(struct('t',z.t(mask),'v',z.v(mask)));
  plot(q.time_s,q.value,'ko','HandleVisibility','off');
  text(q.time_s,q.value,sprintf('  FF limitado %.4f',q.value),'VerticalAlignment','bottom');
 end
 xline(154,'k:','Joystick soltado','HandleVisibility','off');
 grid on;xlim(window);ylabel(labels{j});xlabel('Tiempo [s]');legend('Location','eastoutside','AutoUpdate','off');
end
drawnow;exportgraphics(f,fullfile(out,'comparacion_pico_manual.png'),'Resolution',150);
set(f,'Visible','on');savefig(f,fullfile(out,'comparacion_pico_manual.fig'));
if visible,set(f,'WindowStyle','docked');else,close(f);end
fid=fopen(fullfile(out,'INFORME_LEY_FF.md'),'w');assert(fid>=0);guard=onCleanup(@()fclose(fid));
fprintf(fid,'# Verificacion de la anticipacion limitada\n\n');
fprintf(fid,'Modelo `%s`. Ciclo **%.3f s**, **%d/%d** criterios AUTO. **%d señales** comparadas con bloques FF limitado.\n\n', ...
 summary.model,summary.duration_s,summary.autoPassed,summary.autoTotal,summary.comparedSignals);
fprintf(fid,'El banco comprueba igualdad exacta de las **13 señales** regulatorias con las mismas estimaciones. El ciclo cerrado utiliza estimadores Tustin a 1 ms, frente a los continuos de los bloques; por eso presenta pequeñas diferencias numéricas. No se cambia el autómata.\n\n');
fprintf(fid,'Pico físico global del carro: **%.9f m/s²** en bloques FF y **%.9f m/s²** en MC FF, frente a **%.9f m/s²** en bloques de ley simple. El nuevo pico ocurre a **%.3f s** y queda dentro de ±0.8 m/s² para esta maniobra. Esto es evidencia del ensayo, no una garantía para toda consigna posible.\n\n', ...
 summary.cartPeakBlocks.absolute,summary.cartPeakMC.absolute,summary.cartPeakSimple.absolute,summary.cartPeakMC.time_s);
fprintf(fid,'FF reconstruida = anticipacionUsed/alpha cuando alpha>0. Máxima variación entre muestras habilitadas: **%.12g m/s²**, límite **%.2f m/s²**. Se excluye la puesta a cero al deshabilitar y tiempos repetidos. Residuo feedback=alpha*k*theta: **%.3g m/s**. Residuo SW=sat(feedbackUsed+anticipationUsed): **%.3g m/s**. SW con alpha=0: **%.3g m/s**.\n\n', ...
 summary.ffMaxRate_mps2,summary.ffRateLimit_mps2,summary.feedbackLawResidual_mps,summary.sumLawResidual_mps,summary.maxSWWithAlphaZero_mps);
fprintf(fid,'Máximo a_cmd: **%.9f m/s²**. Recorte máximo de torque del carro: **%.9g Nm**. Los límites de referencia siguen en 0.3 m/s², y el límite regulatorio sigue en 0.8 m/s². La compensación horizontal permanece activa independientemente de E.\n\n',summary.maxCommand_mps2,summary.maxTorqueClipping_Nm);
fprintf(fid,'La figura compara tres corridas ya realizadas, con tiempos absolutos y sin realinear fases: ley simple, bloques FF y MC FF. La limitación suaviza la evolución de la anticipación durante la desaceleración manual; alpha de 2 s no sustituye ese límite una vez completada la habilitación. El feedback mantiene respuesta directa.\n\n');
fprintf(fid,'Los impactos manuales de contacto, conmutaciones de masa y picos del freno de izaje se conservan: esta reforma es del carro. Revisar figuras de contacto, frenos y desempeño completo. No se guardaron series brutas nuevas ni video; las figuras y métricas sí se conservan.\n');
disp(summary);
end
function v=at(z,t)
[tt,ix]=unique(z.t,'last');v=interp1(tt,z.v(ix),t,'previous','extrap');
end
function p=peak(z)
[pk,ix]=max(abs(z.v));p=struct('absolute',pk,'value',z.v(ix),'time_s',z.t(ix));
end
