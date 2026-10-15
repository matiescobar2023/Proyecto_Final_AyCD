function paneles_codesys_13_3(soloBalanceo)
if nargin<1,soloBalanceo=false;end
root='C:/Users/tinch/OneDrive/Desktop/overhead crane - local/chatgpt';
load([root '/tmp/pdfs/revision_13_3/feedback_seleccionado.mat'],'R');
dest=[root '/OCTUBRE/Informe_Combinado_07102026/Informe_Proyecto_Grua/imagenes_informe/medio_ciclo_0810'];if ~isfolder(dest),mkdir(dest);end
for k=1:3
 Q=R{k};Q.y=struct('t',Q.longitud_cable_estimada.t,'v',45-Q.longitud_cable_estimada.v);Q.vy=struct('t',Q.mc_encoder_lengthRate.t,'v',-Q.mc_encoder_lengthRate.v);
 Q.ax=struct('t',Q.mc_encoder_vT.t,'v',gradient(Q.mc_encoder_vT.v,Q.mc_encoder_vT.t));Q.ay=struct('t',Q.vy.t,'v',gradient(Q.vy.v,Q.vy.t));
 Q.delta=struct('t',Q.v_cmd.t,'v',Q.v_cmd.v-interp1(Q.mc_diag_vref_input.t,Q.mc_diag_vref_input.v,Q.v_cmd.t,'linear',NaN));
 R{k}=Q;
end
colors=[.05 .35 .7;.88 .36 .08;.15 .55 .35];lab={'SFC manual + SW','ST autogenerado + SW','SFC manual sin SW'};cap=[169.2 169.24 187.2];
make('posiciones',{'mc_encoder_x','y'},{'mon_xRef','mon_yRef'},{'Posición carro [m]','Altura inferida [m]'},[1 2],[0 170]);
make('velocidades',{'mc_encoder_vT','vy'},{'mon_vxRef','mon_vyRef'},{'Velocidad carro [m/s]','Velocidad izaje [m/s]'},[1 2],[3.24 170]);
make('aceleraciones',{'ax','ay'},{'mon_axRef','mon_ayRef'},{'Aceleración carro [m/s^2]','Aceleración izaje [m/s^2]'},[1 2],[3.24 170]);
make('balanceo',{'mc_diag_theta_medida','mon_thetaRate'},{'angulo_referencia',''},{'Ángulo [rad]','Velocidad angular [rad/s]'},[1 2],[0 170]);
make('accion_antisway',{'antisway_efectiva'},{''},{'Corrección aplicada [m/s]'},[1 2],[0 170]);
make('torques',{'torque_carro_fisico_motor','torque_izaje_fisico_motor'},{'torque_carro_consigna_controlador','torque_izaje_consigna_controlador'},{'Torque carro [kN m]','Torque izaje [kN m]'},[1 2],[3.24 170],1e-3);
make('entrega',{'tension_fisica_cable','masa_fisica_suspendida'},{'',''},{'Tensión [kN]','Masa física [t]'},[1 2],[165 172],1e-3,true);
make('diagnostico',{'tension_fisica_cable','torque_izaje_fisico_motor','sup_loadedState'},{'','torque_izaje_consigna_controlador','mon_loadedPhysical'},{'Tensión [kN]','Torque izaje [kN m]','Estado de carga'},2,[165 279.52],[1e-3 1e-3 1],true);
make('sin_sw_balanceo',{'mc_diag_theta_medida','mon_thetaRate'},{'',''},{'Ángulo [rad]','Velocidad angular [rad/s]'},[1 3],[0 187.2]);
make('sin_sw_posiciones',{'mc_encoder_x','y'},{'mon_xRef','mon_yRef'},{'Posición carro [m]','Altura inferida [m]'},[1 3],[0 187.2]);
% Métricas en ventana común de realimentación.
for k=[1 3]
 Q=R{k};for nm={'mc_diag_theta_medida','mon_thetaRate'},q=Q.(nm{1});v=q.v(q.t>=120&q.t<=130.72);fprintf('%d %s RMS %.8f max %.8f\n',k,nm{1},sqrt(mean(v.^2)),max(abs(v)));end
end
Q=R{2};for nm={'tension_fisica_cable','torque_izaje_consigna_controlador','torque_izaje_fisico_motor','sup_loadedState','mon_loadedPhysical','mon_twistlocksClosed','mon_twistlockCloseCmd','fuerza_contacto_fisica'},q=Q.(nm{1});fprintf('ST final %s %.8f @ %.3f\n',nm{1},q.v(end),q.t(end));end
save([root '/tmp/pdfs/revision_13_3/feedback_paneles.mat'],'R','-v7.3');fprintf('10 paneles generados sin simulación.\n');
 function make(name,fields,refs,units,ks,xr,scale,full)
  if soloBalanceo && ~strcmp(name,'balanceo'),return;end
  if nargin<7,scale=1;end;if nargin<8,full=false;end
  n=numel(fields);f=figure('Visible','off','Color','w','Position',[100 100 1100 280*n+100]);tl=tiledlayout(f,n,1,'TileSpacing','compact','Padding','compact');
  for row=1:n
   ax=nexttile(tl);hold(ax,'on');set(ax,'FontName','Arial','FontSize',12,'Box','on','GridAlpha',.17);grid(ax,'on');
   sc=scale(min(row,numel(scale)));
   for k=ks
    if full,stop=R{k}.(fields{row}).t(end);else,stop=cap(k);end
    if ~isempty(refs{row}),q=R{k}.(refs{row});plotq(q,'--',[lab{k} ' referencia / consigna'],.9);end
    q=R{k}.(fields{row});label=lab{k};if strcmp(name,'diagnostico')&&row==3,label='PLC: carga';end;plotq(q,'-',label,1.3);
   end
   if contains(name,'balanceo'),th=.005;if row==2,th=.012;end;yline(ax,th,':','Umbral','HandleVisibility','off','FontSize',9);yline(ax,-th,':','HandleVisibility','off');yy=ylim(ax);ylim(ax,[min(yy(1),-1.25*th) max(yy(2),1.25*th)]);end
   if strcmp(name,'diagnostico')&&row==1,yline(ax,15.0093,':','Umbral de liberación','HandleVisibility','off');end
   if strcmp(name,'diagnostico')&&row==3,legend(ax,{'Planta: carga','PLC: carga'},'Location','northoutside','NumColumns',2);ylim(ax,[-.1 1.1]);else,legend(ax,'Location','northoutside','NumColumns',2,'FontSize',10);end
   if strcmp(name,'torques'),lim=4;if row==2,lim=20;end;yline(ax,lim,':','HandleVisibility','off');yline(ax,-lim,':','HandleVisibility','off');end
   xlim(ax,xr);ylabel(ax,units{row});xlabel(ax,'Tiempo de simulación [s]');
   if strcmp(name,'sin_sw_posiciones'),xline(ax,130.72,':','Fin encoder sin SW','HandleVisibility','off','FontSize',9);end
  end
  exportgraphics(f,fullfile(dest,[name '.pdf']),'ContentType','vector');exportgraphics(f,fullfile(dest,[name '.png']),'Resolution',150);close(f);
  function plotq(q,style,label,lw)
   ix=find(q.t>=xr(1)&q.t<=min(xr(2),stop));t=q.t(ix);v=q.v(ix)*sc;
   % Reducir sólo el dibujo por bloques de 10 muestras, reteniendo extremos.
   if numel(t)>10000
    keep=[1;numel(t)];for z=1:10:numel(t),b=z:min(z+9,numel(t));[~,mi]=min(v(b));[~,ma]=max(v(b));keep=[keep;b(mi);b(ma)];end %#ok<AGROW>
    keep=unique(keep);t=t(keep);v=v(keep);
   end
   plot(ax,t,v,style,'Color',colors(k,:),'LineWidth',lw,'DisplayName',label);
  end
 end
end
