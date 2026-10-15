function crear_paneles_mil_0810(archivoSenales,soloOmega)
if nargin<2,soloOmega=false;end
% Analiza exclusivamente señales guardadas. No carga modelos ni simula.
base=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(base,'imagenes_informe','prueba_completa_MIL','paneles_0810');
if ~isfolder(folder),mkdir(folder);end
D=load(archivoSenales,'signals');S=D.signals;
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
for k=1:3,ax=nexttile(tl);curves(ax,rows{k},{'Referencia','Reconstruida'},[0 626.36],units{k},true);end
export(fig,'carro_tres_filas');
fig=makefig(3);tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
rows={{'mon_yRef','altura_encoder'},{'mon_vyRef','velocidad_altura_encoder'},{'mon_ayRef','aceleracion_izaje_encoder'}};
for k=1:3,ax=nexttile(tl);curves(ax,rows{k},{'Referencia','Reconstruida'},[0 626.36],units{k},true);end
export(fig,'izaje_tres_filas');
fig=makefig(2);tl=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);curves(ax,{'angulo_referencia','sensor_angulo'},{'Referencia','Sensado'},[0 112],'Ángulo [rad]',false);title(ax,'Barrido del perfil','FontWeight','normal');
ax=nexttile(tl);curves(ax,{'angulo_referencia','sensor_angulo'},{'Referencia','Sensado'},[112 626.36],'Ángulo [rad]',true);title(ax,'Después del barrido: aproximaciones y transferencias','FontWeight','normal');export(fig,'angulo_dos_etapas');
fig=makefig(2);tl=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);curves(ax,{'sensor_velocidad_angular'},{'Sensada'},[0 112],'Velocidad angular [rad/s]',false);umbralOmega(ax);title(ax,'Barrido del perfil','FontWeight','normal');
ax=nexttile(tl);curves(ax,{'sensor_velocidad_angular'},{'Sensada'},[112 626.36],'Velocidad angular [rad/s]',true);umbralOmega(ax);title(ax,'Después del barrido: aproximaciones y transferencias','FontWeight','normal');export(fig,'velocidad_angular_dos_etapas');
fig=makefig(2);tl=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);curves(ax,{'torque_carro_consigna_controlador','torque_carro_limitado','torque_carro_fisico_motor'},{'Antes del limitador','Después del limitador','Motor físico'},[0 626.36],'Torque [kN m]',true,1e-3);title(ax,'Carro','FontWeight','normal');yline(ax,4,':','Límite +4','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');yline(ax,-4,':','Límite -4','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');ylim(ax,[-4.5 4.5]);
ax=nexttile(tl);curves(ax,{'torque_izaje_consigna_controlador','Thm_sat','torque_izaje_fisico_motor'},{'Antes del limitador','Después del limitador','Motor físico'},[0 626.36],'Torque [kN m]',true,1e-3);title(ax,'Izaje','FontWeight','normal');yline(ax,20,':','Límite +20','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');yline(ax,-20,':','Límite -20','Color',[.4 .4 .4],'FontSize',9,'HandleVisibility','off');ylim(ax,[-22 22]);export(fig,'torques_dos_ejes');
map=struct('posicion_carro','mc_encoder_x','altura','45-longitud_cable_estimada', ...
 'velocidad_carro','mc_encoder_vT','velocidad_izaje','-mc_encoder_lengthRate', ...
 'aceleraciones','Derivada numérica de velocidades reconstruidas en sus tiempos nativos; sin filtro adicional', ...
 'angulo','sensor_angulo','velocidad_angular','sensor_velocidad_angular', ...
 'torque_carro_antes','torque_carro_consigna_controlador','torque_carro_despues','torque_carro_limitado', ...
 'torque_izaje_antes','torque_izaje_consigna_controlador','torque_izaje_despues','Thm_sat', ...
 'torques_fisicos','torque_carro_fisico_motor y torque_izaje_fisico_motor', ...
 'division_barrido_s',112,'fin_graficas_s',626.36,'simulacion_repetida',false);
fid=fopen([folder '/procedencia_paneles.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(map,PrettyPrint=true));fclose(fid);
q=S.masa_fisica_suspendida;ix=find(diff(q.v)~=0)+1;disp(table(q.t(ix),q.v(ix),'VariableNames',{'Tiempo_s','Masa_kg'}));
if soloOmega,fprintf('Actualizado únicamente el panel de velocidad angular MIL. Sin simulación.\n');else,fprintf('Paneles generados: 5 PDF y 5 PNG. Sin simulación.\n');end
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
   yy=ylim(ax);patch(ax,[194.96 309 309 194.96],[yy(1) yy(1) yy(2) yy(2)],[.91 .88 .97],'FaceAlpha',.40,'EdgeColor','none','HandleVisibility','off');
   patch(ax,[447.56 624.32 624.32 447.56],[yy(1) yy(1) yy(2) yy(2)],[.91 .88 .97],'FaceAlpha',.40,'EdgeColor','none','HandleVisibility','off');
   uistack(hh,'top');
   times=[192.12 308.60 444.72 623.88];labelsE={'Toma 1','Apoyo 1','Toma 2','Apoyo 2'};
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
