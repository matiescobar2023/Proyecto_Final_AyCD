function crear_paneles_final_codesys(soloOmega)
if nargin<1,soloOmega=false;end
% Analiza exclusivamente señales guardadas. No carga modelos ni simula.
root='C:/Users/tinch/OneDrive/Desktop/overhead crane - local/chatgpt';
folder=[root '/OCTUBRE/Informe_Combinado_07102026/Informe_Proyecto_Grua/imagenes_informe/prueba_completa_CODESYS/paneles_0810'];
if ~isfolder(folder),mkdir(folder);end
D=load([root '/tmp/pdfs/final_codesys_paneles/senales_originales.mat'],'signals');S=D.signals;
keys=fieldnames(S);
for k=1:numel(keys)
 q=S.(keys{k});[q.t,ix]=unique(q.t(:),'last');q.v=q.v(ix,:);S.(keys{k})=q;
end
S.altura_encoder=struct('t',S.longitud_cable_estimada.t,'v',45-S.longitud_cable_estimada.v);
S.velocidad_altura_encoder=struct('t',S.mc_encoder_lengthRate.t,'v',-S.mc_encoder_lengthRate.v);
S.aceleracion_carro_encoder=struct('t',S.mc_encoder_vT.t,'v',gradient(S.mc_encoder_vT.v,S.mc_encoder_vT.t));
S.aceleracion_izaje_encoder=struct('t',S.velocidad_altura_encoder.t,'v',gradient(S.velocidad_altura_encoder.v,S.velocidad_altura_encoder.t));
colors=[.05 .35 .70;.88 .36 .08;.12 .52 .30];
fig=makefig(3);tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
rows={{'mon_xRef','mc_encoder_x'},{'mon_vxRef','mc_encoder_vT'},{'mon_axRef','aceleracion_carro_encoder'}};
units={'Posición [m]','Velocidad [m/s]','Aceleración [m/s^2]'};
for k=1:3,ax=nexttile(tl);curves(ax,rows{k},{'Referencia','Reconstruida'},[3.24 611.08],units{k},true);if k==3,ylim(ax,[-1 1]);end;end
export(fig,'carro_tres_filas');
fig=makefig(3);tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
rows={{'mon_yRef','altura_encoder'},{'mon_vyRef','velocidad_altura_encoder'},{'mon_ayRef','aceleracion_izaje_encoder'}};
for k=1:3,ax=nexttile(tl);curves(ax,rows{k},{'Referencia','Reconstruida'},[3.24 611.08],units{k},true);if k==3,ylim(ax,[-1 1]);end;end
export(fig,'izaje_tres_filas');
fig=makefig(2);tl=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);curves(ax,{'angulo_referencia','mc_diag_theta_medida'},{'Referencia','Sensado'},[3.24 130.04],'Ángulo [rad]',false);title(ax,'Barrido del perfil','FontWeight','normal');
ax=nexttile(tl);curves(ax,{'angulo_referencia','mc_diag_theta_medida'},{'Referencia','Sensado'},[130.04 611.08],'Ángulo [rad]',true);title(ax,'Después del barrido: aproximaciones y transferencias','FontWeight','normal');ylim(ax,[-.05 .05]);export(fig,'angulo_dos_etapas');
fig=makefig(2);tl=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);curves(ax,{'mon_thetaRate'},{'Sensada'},[3.24 130.04],'Velocidad angular [rad/s]',false);umbralOmega(ax);title(ax,'Barrido del perfil','FontWeight','normal');
ax=nexttile(tl);curves(ax,{'mon_thetaRate'},{'Sensada'},[130.04 611.08],'Velocidad angular [rad/s]',true);umbralOmega(ax);title(ax,'Después del barrido: aproximaciones y transferencias','FontWeight','normal');ylim(ax,[-.05 .05]);export(fig,'velocidad_angular_dos_etapas');
fig=makefig(2);tl=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);curves(ax,{'torque_carro_consigna_controlador','T_tmlim_','torque_carro_fisico_motor'},{'Antes del limitador','Después del limitador','Motor físico'},[3.24 611.08],'Torque [kN m]',true,1e-3);title(ax,'Carro','FontWeight','normal');yline(ax,4,':','Límite +4','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');yline(ax,-4,':','Límite -4','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');ylim(ax,[-4.5 4.5]);
ax=nexttile(tl);curves(ax,{'torque_izaje_consigna_controlador','Thm_sat','torque_izaje_fisico_motor'},{'Antes del limitador','Después del limitador','Motor físico'},[3.24 611.08],'Torque [kN m]',true,1e-3);title(ax,'Izaje','FontWeight','normal');yline(ax,20,':','Límite +20','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');yline(ax,-20,':','Límite -20','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');ylim(ax,[-22 22]);export(fig,'torques_dos_ejes');
fig=makefig(1);ax=axes(fig);curves(ax,{'antisway_efectiva'},{'Corrección aplicada'},[3.24 611.08],'Corrección [m/s]',true);ylim(ax,[-.3 .3]);export(fig,'antisway_aplicada');
fig=makefig(1);ax=axes(fig);curves(ax,{'mc_diag_vref_input','v_cmd'},{'Referencia base','Comando'},[3.24 611.08],'Velocidad [m/s]',true);export(fig,'comando');
fig=makefig(1);ax=axes(fig);curves(ax,{'tension_fisica_cable'},{'Tensión del cable'},[3.24 611.08],'Tensión [kN]',true,1e-3);export(fig,'tension');
map=struct('posicion_carro','mc_encoder_x','altura','45-longitud_cable_estimada', ...
 'velocidad_carro','mc_encoder_vT','velocidad_izaje','-mc_encoder_lengthRate', ...
 'aceleraciones','Derivada numérica de velocidades reconstruidas en sus tiempos nativos; sin filtro adicional', ...
 'angulo','mc_diag_theta_medida','velocidad_angular','mon_thetaRate', ...
 'torque_carro_antes','torque_carro_consigna_controlador','torque_carro_despues','T_tmlim_', ...
 'torque_izaje_antes','torque_izaje_consigna_controlador','torque_izaje_despues','Thm_sat', ...
 'torques_fisicos','torque_carro_fisico_motor y torque_izaje_fisico_motor', ...
 'division_barrido_s',130.04,'fin_graficas_s',611.08,'simulacion_repetida',false);
fid=fopen([folder '/procedencia_paneles.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(map,PrettyPrint=true));fclose(fid);
q=S.masa_fisica_suspendida;ix=find(diff(q.v)~=0)+1;disp(table(q.t(ix),q.v(ix),'VariableNames',{'Tiempo_s','Masa_kg'}));
if soloOmega,fprintf('Actualizado únicamente el panel de velocidad angular CODESYS. Sin simulación.\n');else,fprintf('Paneles generados: 8 PDF y 8 PNG. Sin simulación.\n');end
for nm={'aceleracion_carro_encoder','aceleracion_izaje_encoder','torque_carro_consigna_controlador'},q=S.(nm{1});mask=q.t>=3.24&q.t<=611.08;[v,ix]=max(abs(q.v(mask)));tt=q.t(mask);vv=q.v(mask);fprintf('%s extremo operativo %.8g a %.8g s\n',nm{1},vv(ix),tt(ix));end;
q=S.torque_carro_consigna_controlador;[~,ix]=max(abs(q.v));fprintf('Pico inicial carro %.8g a %.8g s\n',q.v(ix),q.t(ix));
 function f=makefig(n)
  f=figure('Visible','off','Color','w','Units','pixels','Position',[100 100 1100 280*n+100]);
 end
 function curves(ax,names,labels,range,unit,events,scale)
  if nargin<7,scale=1;end
  hold(ax,'on');set(ax,'FontName','Arial','FontSize',12,'GridAlpha',.16,'Layer','top');
  hh=gobjects(numel(names),1);
  for j=1:numel(names)
   q=S.(names{j});mask=q.t>=range(1)&q.t<=range(2);style='-';if j==1 && numel(names)>1,style='--';end
   hh(j)=plot(ax,q.t(mask),q.v(mask)*scale,style,'Color',colors(j,:),'LineWidth',1.25);
  end
  xlim(ax,range);grid(ax,'on');ylabel(ax,unit);xlabel(ax,'Tiempo [s]');
  if events
   yy=ylim(ax);patch(ax,[203.68 316.24 316.24 203.68],[yy(1) yy(1) yy(2) yy(2)],[.91 .88 .97],'FaceAlpha',.40,'EdgeColor','none','HandleVisibility','off');
   patch(ax,[448.12 609.04 609.04 448.12],[yy(1) yy(1) yy(2) yy(2)],[.91 .88 .97],'FaceAlpha',.40,'EdgeColor','none','HandleVisibility','off');
   uistack(hh,'top');
   times=[200.80 315.80 445.24 608.60];labelsE={'Toma 1','Apoyo 1','Toma 2','Apoyo 2'};
   for m=1:4,if times(m)>range(1)&&times(m)<range(2),xline(ax,times(m),':',labelsE{m},'Color',[.59 .28 .49],'FontSize',9,'LabelVerticalAlignment','bottom','HandleVisibility','off');end;end
  end
  legend(ax,hh,labels,'Location','northoutside','Orientation','horizontal','FontSize',10,'Box','off');
 end
 function umbralOmega(ax)
  yline(ax,.012,':','+0,012 rad/s','LabelVerticalAlignment','bottom','Color',[.40 .40 .40],'FontSize',9,'HandleVisibility','off');
  yline(ax,-.012,':','-0,012 rad/s','LabelVerticalAlignment','top','Color',[.40 .40 .40],'FontSize',9,'HandleVisibility','off');
 end
 function export(f,name)
  if soloOmega && ~strcmp(name,'velocidad_angular_dos_etapas'),close(f);return;end
  exportgraphics(f,[folder '/' name '.pdf'],'ContentType','vector','BackgroundColor','white');
  exportgraphics(f,[folder '/' name '.png'],'Resolution',150,'BackgroundColor','white');close(f);
 end
end
