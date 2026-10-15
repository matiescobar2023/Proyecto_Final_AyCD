function actualizar_perfiles_unidos
% Dos corridas existentes, sin simulacion; conservan sus puntos independientes.
root='C:/Users/tinch/OneDrive/Desktop/overhead crane - local/chatgpt';d=[root '/OCTUBRE/Informe_Combinado_07102026/Informe_Proyecto_Grua/'];
folders={'prueba_completa_MIL','prueba_completa_CODESYS'};
files={[root '/tmp/pdfs/revision_13_2_paneles/datos/senales_originales.mat'],[root '/tmp/pdfs/final_codesys_paneles/senales_originales.mat']};
for run=1:2
 folder=folders{run};doc=[d 'documentacion_' folder '/'];
 pointFile=[doc 'puntos_lidar_perfil.mat'];
 if isfile(pointFile)
  D=load(pointFile);x=D.x;y=D.y;scanEnd=D.scanEnd;
 else
  D=load(files{run},'signals');S=D.signals;qx=S.mon_lidarX;qy=S.mon_lidarY;qb=S.mon_scanActive;
  [tx,ix]=unique(qx.t(:),'last');xx=double(qx.v(ix));[ty,iy]=unique(qy.t(:),'last');yy=interp1(ty,double(qy.v(iy)),tx,'linear',NaN);[tb,ib]=unique(qb.t(:),'last');active=interp1(tb,double(qb.v(ib)),tx,'previous',0)>0;
  valid=active&isfinite(xx)&isfinite(yy);x=xx(valid);y=yy(valid);scanEnd=max(tx(valid));save(pointFile,'x','y','scanEnd');
 end
 P=readtable([doc 'perfiles.csv']);
 f=figure('Visible','off','Color','w','Position',[100 100 1250 690]);a=axes(f);hold(a,'on');set(a,'FontName','Arial','FontSize',12,'Box','on','GridAlpha',.16);grid(a,'on');
 % Unir las cotas con tramos horizontales y verticales, sin interpolar pendientes.
 xx=[];yy=[];
 for k=1:height(P)
  xx=[xx;P.x_m(k)-1.22;P.x_m(k)+1.22];yy=[yy;P.relevado_m(k);P.relevado_m(k)]; %#ok<AGROW>
 end
 hp=plot(a,xx,yy,'-','Color',[.05 .35 .7],'LineWidth',1.8,'DisplayName','Perfil reconstruido');
 [~,pick]=unique([round(x/.8) round(y/.1)],'rows','stable');
 hs=scatter(a,x(pick),y(pick),10,'MarkerEdgeColor',[.35 .35 .35],'MarkerFaceColor','w','DisplayName','Puntos relevados LiDAR');
 slots=[6 23 32 1];roles={'Toma 1','Entrega 1','Toma 2','Entrega 2'};levels=[23 23 23 23];ht=gobjects(1);he=gobjects(1);
 for j=1:4
  k=slots(j);xc=P.x_m(k);h=P.relevado_m(k);take=mod(j,2)==1;
  if take,bottom=h-2.59;c=[.88 .36 .08];style='-';face=[1 .88 .72];else,bottom=h;c=[.12 .52 .30];style='--';face='none';end
  rectangle(a,'Position',[xc-1.1 bottom 2.2 2.59],'EdgeColor',c,'LineStyle',style,'LineWidth',2,'FaceColor',face);
  if take && j==1,ht=plot(a,NaN,NaN,'-s','Color',c,'LineWidth',2,'MarkerFaceColor',[1 .88 .72],'DisplayName','Contenedor a retirar');end
  if ~take && j==2,he=plot(a,NaN,NaN,'--s','Color',c,'LineWidth',2,'DisplayName','Ubicación de entrega');end
  tip=bottom+2.59;plot(a,[xc xc],[levels(j)-2 tip+.7],':','Color',c,'LineWidth',1,'HandleVisibility','off');plot(a,xc,tip+.35,'v','MarkerSize',5,'MarkerFaceColor',c,'Color',c,'HandleVisibility','off');
  text(a,xc,levels(j),sprintf('%s\nSlot %d',roles{j},k),'HorizontalAlignment','center','Color',c,'FontSize',11,'FontWeight','bold');
 end
 xlabel(a,'Posición horizontal [m]');ylabel(a,'Altura [m]');xlim(a,[-33 50]);ylim(a,[-23 28]);legend(a,[hs hp ht he],'Location','southoutside','NumColumns',2,'FontSize',11);
 exportgraphics(f,[d 'imagenes_informe/' folder '/perfil.pdf'],'ContentType','vector');exportgraphics(f,[d 'imagenes_informe/' folder '/perfil.png'],'Resolution',170);close(f);
 info=struct('fuente',files{run},'puntos','mon_lidarX, mon_lidarY durante mon_scanActive','fin_barrido_s',scanEnd,'cantidad_puntos',numel(x),'puntos_representados',numel(pick),'representacion','Muestras originales representativas por celda espacial de 0.8 m horizontal y 0.1 m vertical; sin promediar','perfil','perfiles.csv, columna relevado_m, unido con segmentos horizontales y verticales; cotas neutras incluidas','tomas',[6 32],'entregas',[23 1],'simulacion_nueva',false);
 fid=fopen([doc 'procedencia_perfil_unido.json'],'w','n','UTF-8');fwrite(fid,jsonencode(info,PrettyPrint=true),'char');fclose(fid);fprintf('%s: %d puntos; fin %.3f s\n',folder,numel(x),scanEnd);
end
end
