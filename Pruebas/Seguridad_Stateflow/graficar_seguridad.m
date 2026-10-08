function graficar_seguridad(regenerar)
if nargin<1,regenerar=false;end
root=fileparts(mfilename('fullpath'));result=fullfile(root,'Resultados_finales');d=dir(fullfile(result,'S*'));
d=d(~cellfun('isempty',regexp({d.name},'^S[0-9]+_','once')));
audit={};colors=[.14 .40 .70;.86 .41 .12;.22 .60 .40];
for k=1:numel(d)
 if ~d(k).isdir,continue;end
 folder=fullfile(d(k).folder,d(k).name);v=load(fullfile(folder,'senales.mat'),'t','Y','sampleU','c');
 dest=fullfile(folder,'Graficas');mkdir(dest);t=v.t;Y=v.Y;U=v.sampleU;c=v.c;
 draw('permisos','Permisos de movimiento',Y(:,1:3),{'Global','Carro','Izaje'},'Permiso [0/1]',true,[],false);
 draw('frenos','Autorización de apertura de frenos',Y(:,4:6),{'Carro','Izaje operativo','Izaje emergencia'},'Autorización [0/1]',true,[],false);
 draw('alarmas','Emergencia y fallo watchdog',Y(:,7:8),{'Emergencia','Fallo watchdog'},'Alarma [0/1]',true,[],false);
 draw('mandos','Latido y órdenes del operador',U(:,1:3),{'Latido watchdog','Reinicio','Pulsador emergencia'},'Entrada [0/1]',true,[],false);
 for j=reshape(unique(c.variables),1,[])
  if j<=3,continue;end
  names={'','','','Posición del carro','Velocidad del carro','Altura de izaje','Velocidad de izaje'};
  units={'','','','Posición [m]','Velocidad [m/s]','Altura [m]','Velocidad [m/s]'};
  values=U(:,j);finite=values(isfinite(values));
  if any(~isfinite(values))
   draw(sprintf('entrada_%d_valida',j),[names{j} ': validez de la entrada'],double(isfinite(values)),{'Medición finita'},'Validez [0/1]',true,[],false);
  else
   limits=[];
   switch j
    case 4,if min(finite)<=-30,limits(end+1)=-30.5;end;if max(finite)>=50,limits(end+1)=50.5;end
    case 5,if min(finite)<=-4,limits(end+1)=-4.6;end;if max(finite)>=4,limits(end+1)=4.6;end
    case 6,if min(finite)<=-20,limits(end+1)=-20.5;end;if max(finite)>=40,limits(end+1)=40.5;end
    case 7,if min(finite)<=-3,limits(end+1)=-3.45;end;if max(finite)>=3,limits(end+1)=3.45;end
   end
   draw(sprintf('entrada_%d',j),names{j},values,{'Entrada física inyectada'},units{j},false,limits,false);
   if contains(c.nombre,'igualdad')||contains(c.nombre,'interior')||contains(c.nombre,'exterior')
    draw(sprintf('entrada_%d_umbral',j),[names{j} ': detalle del umbral'],values,{'Entrada física inyectada'},units{j},false,limits,true);
   end
  end
 end
 if strcmp(c.id,'S66')
  draw('pulso_original','Pulso original entre muestras del chart',c.U(:,4),{'Estímulo original'},'Posición [m]',false,-30.5,false,c.t);
 end
 if any(strcmp(c.id,{'S49','S50','S54','S55'}))
  draw('detalle_watchdog','Detalle del vencimiento del watchdog',[U(:,1),Y(:,7:8)],{'Latido','Emergencia','Fallo watchdog'},'Señal [0/1]',true,[],false,[],[5 5.26]);
 end
 fprintf('Gráficas %s (%d/%d)\n',c.id,k,numel(d));
end
writetable(cell2table(audit,'VariableNames',{'caso','grafico','minimo_datos','maximo_datos','limite_inferior','limite_superior','zoom_vertical','muestras_fuera'}),fullfile(result,'verificacion_escalas.csv'));
 function draw(id,titleText,data,labels,unit,binary,limits,zoom,tt,xx)
  if nargin<9||isempty(tt),tt=t;end;if nargin<10,xx=[];end
  f=figure('Visible','off','Color','w','Position',[70 70 1350 530]);a=axes(f);hold(a,'on');
  for z=1:size(data,2),stairs(a,tt,data(:,z),'Color',colors(mod(z-1,3)+1,:),'LineWidth',1.8,'DisplayName',labels{z});end
  if ~isempty(limits)
   for z=1:numel(limits),yline(a,limits(z),'--',sprintf('Umbral %.4g',limits(z)),'Color',[.55 .18 .18],'LineWidth',1.3,'FontSize',13,'HandleVisibility','off');end
  end
  vals=data(isfinite(data));lo=min(vals);hi=max(vals);
  if binary,bounds=[-.1 1.15];yticks(a,[0 1]);
  elseif zoom,center=limits(1);bounds=center+[-.003 .003];
  else,allvals=[vals(:);limits(:)];loAll=min(allvals);hiAll=max(allvals);pad=max(.04,.1*(hiAll-loAll));bounds=[loAll-pad hiAll+pad];end
  ylim(a,bounds);xlim(a,[tt(1) tt(end)]);if ~isempty(xx),xlim(a,xx);end
  title(a,[c.id ' · ' titleText],'FontSize',19,'FontWeight','bold','Interpreter','none');
  subtitle(a,c.nombre,'FontSize',13,'Interpreter','none');xlabel(a,'Tiempo de simulación [s]');ylabel(a,unit);
  set(a,'FontName','Arial','FontSize',15,'GridAlpha',.16,'Box','on');grid(a,'on');
  legend(a,'Location','southoutside','Orientation','horizontal','FontSize',13,'Interpreter','none');
  if regenerar||~isfile(fullfile(dest,[id '.png']))||~isfile(fullfile(dest,[id '.pdf']))
   exportgraphics(f,fullfile(dest,[id '.png']),'Resolution',170);exportgraphics(f,fullfile(dest,[id '.pdf']),'ContentType','vector');
  end
  outside=nnz(vals<bounds(1)|vals>bounds(2));audit(end+1,:)={c.id,id,lo,hi,bounds(1),bounds(2),zoom,outside};
  close(f);
 end
end
