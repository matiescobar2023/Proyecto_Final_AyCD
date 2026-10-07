function graficar_prueba_completa(folder)
if nargin<1,folder=evalin('base','FullCycleFolder');end
R=load(fullfile(folder,'senales_originales.mat'));S=R.signals;q=R.q;
dest=fullfile(folder,'graficas');if ~isfolder(dest),mkdir(dest);end
manifest=struct('id',{},'titulo',{},'zoom',{});audit=struct('id',{},'minimo',{},'maximo',{},'limites',{},'muestrasFuera',{});
pair=@(a,b) {a,'Referencia';b,'Física'};
draw('x','Posición del carro','Posición [m]',pair('mon_xRef','x_carro_fisica'));
draw('y','Altura de la carga','Altura [m]',pair('mon_yRef','y_carga_fisica'));
draw('vx','Velocidad del carro','Velocidad [m/s]',pair('mon_vxRef','v_carro_fisica'));
draw('vy','Velocidad de izaje','Velocidad [m/s]',pair('mon_vyRef','v_izaje_fisica'));
draw('ax','Aceleración del carro','Aceleración [m/s²]',pair('mon_axRef','aceleracion_carro_fisica'));
draw('ay','Aceleración de izaje: escala completa','Aceleración [m/s²]',pair('mon_ayRef','aceleracion_izaje_fisica'));
draw('ay_zoom','Aceleración de izaje: zoom vertical','Aceleración [m/s²]',pair('mon_ayRef','aceleracion_izaje_fisica'),[-1 1]);
draw('theta','Ángulo del péndulo','Ángulo [rad]',pair('angulo_referencia','angulo_fisico'));
draw('theta_operativo','Ángulo después del relevamiento','Ángulo [rad]',pair('angulo_referencia','angulo_fisico'),[],1,[q.scanFinished q.lastT]);
draw('omega','Velocidad angular del péndulo','Velocidad angular [rad/s]',{'velocidad_angular_referencia_derivada','Referencia derivada';'velocidad_angular_fisica','Física'});
draw('omega_operativo','Velocidad angular después del relevamiento','Velocidad angular [rad/s]',{'velocidad_angular_referencia_derivada','Referencia derivada';'velocidad_angular_fisica','Física'},[],1,[q.scanFinished q.lastT]);
draw('ax_carga','Aceleración horizontal de la carga','Aceleración [m/s²]',{'aceleracion_carga_x_fisica','Física'});
draw('tx','Torque del carro','Torque [kN m]',{'torque_carro_consigna_controlador','Consigna';'torque_carro_fisico_motor','Motor físico'},[],.001);
draw('tx_operativo','Torque del carro desde el arranque','Torque [kN m]',{'torque_carro_consigna_controlador','Consigna';'torque_carro_fisico_motor','Motor físico'},[],.001,[.2 q.lastT]);
draw('ty','Torque de izaje','Torque [kN m]',{'torque_izaje_consigna_controlador','Consigna';'torque_izaje_fisico_motor','Motor físico'},[],.001);
draw('tension','Tensión del cable de izaje','Tensión [kN]',{'tension_fisica_cable','Física'},[],.001);
draw('masa','Masa física suspendida','Masa [t]',{'masa_fisica_suspendida','Física'},[],.001);
draw('antisway','Contribuciones antisway','Velocidad [m/s]',{'antisway_correccion_aplicada','Aplicada';'sw_feedback_comun','Feedback';'sw_anticipacion_comun','Anticipación'});
draw('comando','Referencia y comando del carro','Velocidad [m/s]',{'diag_vref_input','Referencia base';'diag_vcmd_applied','Comando limitado'});
for direction={'x','y'}
 key=direction{1};if key=='x',phys='x_carro_fisica';ref='mon_xRef';else,phys='y_carga_fisica';ref='mon_yRef';end
 z=S.(phys);r=S.(ref);z.v=interp1(r.t,r.v,z.t,'linear')-z.v;S.(['error_' key])=z;
 draw(['error_' key],['Error de posición ' upper(key)],'Error [m]',{['error_' key],'Referencia menos física'});
end
P=readtable(fullfile(folder,'perfiles.csv'));f=figure('Visible','off','Color','w','Position',[80 80 1150 470]);a=axes(f);hold(a,'on');
plot(a,P.x_m,P.inicial_m,'-','Color',[.15 .45 .7],'LineWidth',1.8,'DisplayName','Perfil físico inicial');
mask=logical(P.operable);plot(a,P.x_m(mask),P.relevado_m(mask),'o','Color',[.88 .45 .16],'LineWidth',1.4,'DisplayName','Perfil relevado');
plot(a,P.x_m,P.final_m,'--','Color',[.3 .6 .4],'LineWidth',1.6,'DisplayName','Perfil físico final');
style(a);xlabel(a,'Posición horizontal [m]');ylabel(a,'Altura [m]');ylim(a,'padded');title(a,'Prueba completa | Perfil inicial, relevado y final','FontWeight','bold');legend(a,'Location','southoutside','NumColumns',3);emit(f,'perfil');close(f);
f=figure('Visible','off','Color','w','Position',[80 80 1150 470]);a=axes(f);bar(a,P.slot,P.cambio_m,'FaceColor',[.15 .45 .7]);style(a);xlabel(a,'Slot');ylabel(a,'Variación [m]');ylim(a,[-3.1 3.1]);title(a,'Prueba completa | Balance de las dos transferencias','FontWeight','bold');emit(f,'balance_perfil');close(f);
writeJson('manifest.json',manifest);writeJson('verificacion_escalas.json',audit);
fprintf('%d figuras de señales y dos figuras de perfil.\n',numel(manifest));
 function draw(id,ttl,unit,keys,yr,scale,xr)
  if nargin<5,yr=[];end;if nargin<6,scale=1;end;if nargin<7,xr=[0 q.lastT];end
  values=[];for h=1:size(keys,1),z=S.(keys{h,1});ix=z.t>=xr(1)&z.t<=xr(2)&isfinite(z.v);values=[values;scale*z.v(ix)];end %#ok<AGROW>
  low=min(values);high=max(values);if isempty(yr),pad=max(.08*(high-low),.01);yr=[low-pad high+pad];end
  f=figure('Visible','off','Color','w','Position',[80 80 1150 470]);a=axes(f);hold(a,'on');
  if isfield(q,'scanFinished'),patch(a,[0 q.scanFinished q.scanFinished 0],[yr(1) yr(1) yr(2) yr(2)],[.9 .9 .9],'FaceAlpha',.55,'EdgeColor','none','HandleVisibility','off');end
  if isfield(q,'transferTimes') && numel(q.transferTimes)==4
   for j=[1 3],tt=q.transferTimes(j:j+1);patch(a,[tt(1) tt(2) tt(2) tt(1)],[yr(1) yr(1) yr(2) yr(2)],[.89 .84 .97],'FaceAlpha',.45,'EdgeColor','none','HandleVisibility','off');end
  end
  colors=[.15 .45 .7;.88 .45 .16;.3 .6 .4];
  for h=1:size(keys,1),z=S.(keys{h,1});plot(a,z.t,scale*z.v,'Color',colors(h,:),'LineWidth',1.35,'DisplayName',keys{h,2});end
  if isfield(q,'contactTimes'),labels={'Toma 1','Apoyo 1','Toma 2','Apoyo 2'};for j=1:numel(q.contactTimes),xline(a,q.contactTimes(j),'--',labels{j},'Color',[.6 .3 .5],'LabelVerticalAlignment','bottom','LabelHorizontalAlignment','left','FontSize',14,'HandleVisibility','off');end;end
  style(a);xlim(a,xr);ylim(a,yr);ylabel(a,unit);title(a,['Prueba completa | ' ttl],'FontWeight','bold','FontSize',18);legend(a,'Location','southwest','FontSize',15);
  if strcmp(id,'ay_zoom'),text(a,.02,.92,'Zoom vertical: picos preservados en la figura de escala completa','Units','normalized','FontSize',15);end
  emit(f,id);close(f);manifest(end+1)=struct('id',id,'titulo',ttl,'zoom',strcmp(id,'ay_zoom'));
  audit(end+1)=struct('id',id,'minimo',low,'maximo',high,'limites',yr,'muestrasFuera',sum(values<yr(1)|values>yr(2)));
 end
 function emit(f,id)
  exportgraphics(f,fullfile(dest,[id '.png']),'Resolution',180);
  exportgraphics(f,fullfile(dest,[id '.pdf']),'ContentType','vector');
 end
 function writeJson(name,v)
  fid=fopen(fullfile(dest,name),'w','n','UTF-8');assert(fid>0);fprintf(fid,'%s',jsonencode(v,PrettyPrint=true));fclose(fid);
 end
end
function style(a)
set(a,'FontName','Arial','FontSize',18,'GridAlpha',.15,'GridLineStyle',':','Box','on');grid(a,'on');xlabel(a,'Tiempo [s]');
end
