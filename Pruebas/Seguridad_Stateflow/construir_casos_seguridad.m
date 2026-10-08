function cases=construir_casos_seguridad
N=[1 1 1 1 1 1 0 0];C=[1 0 1 0 1 1 1 0];H=[1 1 0 1 0 0 1 0];G=[0 0 0 0 0 0 1 0];W=[0 0 0 0 0 0 1 1];
cases={};
c=newcase('Normal y actividad de watchdog',6);c=check(c,5.9,N,'Funcionamiento normal con conmutaciones','LOGICA');cases{end+1}=c;
% Umbrales independientes: lado interior, igualdad y exterior.
limits={4,-30.5,-1,C,9,'Posicion minima carro','m';4,50.5,1,C,10,'Posicion maxima carro','m'; ...
 5,-4.6,-1,C,9,'Velocidad negativa carro','m/s';5,4.6,1,C,10,'Velocidad positiva carro','m/s'; ...
 6,-20.5,-1,H,11,'Altura minima izaje','m';6,40.5,1,H,12,'Altura maxima izaje','m'; ...
 7,-3.45,-1,H,13,'Velocidad negativa izaje','m/s';7,3.45,1,H,13,'Velocidad positiva izaje','m/s'};
for j=1:size(limits,1)
 for side=-1:1
  labels={'interior','igualdad','exterior'};c=newcase([limits{j,6} ' - ' labels{side+2}],.6);
  v=limits{j,2}+side*limits{j,3}*.001;c=setv(c,limits{j,1},.2,inf,v);c.variables=limits{j,1};
  if side==-1,state=N;flag=0;else,state=limits{j,4};flag=1;end
  c=check(c,.24,state,'Respuesta del umbral inclusivo','LOGICA');
  c=checkcols(c,.24,limits{j,5},flag,'Indicacion del sensor correspondiente','LOGICA');cases{end+1}=c;
 end
 % Enclavamiento, rechazo con causa activa y rearme por nuevo flanco.
 c=newcase([limits{j,6} ' - retencion y rearme'],.8);c.variables=limits{j,1};
 c=setv(c,limits{j,1},.2,.4,limits{j,2}+limits{j,3}*.01);c=pulse(c,2,.3);c=pulse(c,2,.6);
 c=check(c,.24,limits{j,4},'Intervencion de eje','LOGICA');c=check(c,.32,limits{j,4},'Reinicio rechazado con causa activa','LOGICA');
 c=check(c,.5,limits{j,4},'Retencion tras desaparecer la causa','LOGICA');c=check(c,.62,N,'Nuevo flanco con causa inactiva','LOGICA');cases{end+1}=c;
end
% Emergencia por nivel y rearme.
c=newcase('Pulsador de emergencia y rearme',.8);c.variables=3;c=setv(c,3,.2,.4,1);c=pulse(c,2,.3);c=pulse(c,2,.6);
c=check(c,.24,G,'Boton inhibe ambos ejes','LOGICA');c=check(c,.32,G,'Boton activo impide rearme','LOGICA');c=check(c,.5,G,'Soltar boton no rearma','LOGICA');c=check(c,.62,N,'Rearme intencional','LOGICA');cases{end+1}=c;
% Escalamiento secuencial, y prioridad absoluta del pulsador.
for direction=1:2
 if direction==1,col1=4;v1=-31;state=C;col2=6;v2=41;label='Carro luego izaje';else,col1=6;v1=41;state=H;col2=4;v2=-31;label='Izaje luego carro';end
 c=newcase(['Escalamiento - ' label],.8);c.variables=[col1 col2];c=setv(c,col1,.2,.5,v1);c=setv(c,col2,.3,.5,v2);c=pulse(c,2,.6);
 c=check(c,.24,state,'Primera emergencia parcial','LOGICA');c=check(c,.34,G,'Segundo eje escala a total','LOGICA');c=check(c,.62,N,'Rearme total con todas las causas despejadas','LOGICA');cases{end+1}=c;
 c=newcase(['Pulsador durante emergencia - ' label],.6);c.variables=[col1 3];c=setv(c,col1,.2,inf,v1);c=setv(c,3,.3,inf,1);
 c=check(c,.24,state,'Emergencia parcial previa','LOGICA');c=check(c,.34,G,'Boton escala a total','LOGICA');cases{end+1}=c;
end
c=newcase('Limites de ambos ejes simultaneos',.8);c.variables=[4 6];c=setv(c,4,.2,inf,-31);c=setv(c,6,.2,inf,41);
c=check(c,.24,H,'Prioridad de izaje implementada','LOGICA');c=check(c,.6,H,'El flanco de carro no se vuelve a evaluar','LOGICA');
c=checkcols(c,.24,[2 3],[0 0],'Ambos ejes peligrosos deben quedar inhibidos','ROBUSTEZ');cases{end+1}=c;
c=newcase('Pulsador y limites simultaneos',.6);c.variables=[3 4 6];c=setv(c,3,.2,inf,1);c=setv(c,4,.2,inf,-31);c=setv(c,6,.2,inf,41);c=check(c,.24,G,'Prioridad total del boton','LOGICA');cases{end+1}=c;
% Cada guarda de rearme total se prueba por separado.
guards={3,1,'boton';4,-31,'carro minimo';4,51,'carro maximo';6,-21,'izaje minimo';6,41,'izaje maximo';7,3.5,'sobrevelocidad izaje'};
for j=1:size(guards,1)
 c=newcase(['Rearme total bloqueado por ' guards{j,3}],.9);c.variables=unique([3 guards{j,1}]);
 c=setv(c,3,.1,.2,1);c=setv(c,guards{j,1},.16,.5,guards{j,2});c=pulse(c,2,.3);c=pulse(c,2,.7);
 c=check(c,.32,G,'Una sola causa activa impide rearme total','LOGICA');c=check(c,.6,G,'La desaparicion no rearma sola','LOGICA');c=check(c,.72,N,'Rearme tras eliminar la ultima causa','LOGICA');cases{end+1}=c;
end
c=newcase('Reinicio sostenido requiere nuevo flanco',.9);c.variables=[2 4];c=setv(c,2,.1,.6,1);c=setv(c,4,.2,.4,-31);c=pulse(c,2,.7);
c=check(c,.24,C,'Limite dispara aun con reset alto','LOGICA');c=check(c,.5,C,'Reset alto no equivale a flanco nuevo','LOGICA');c=check(c,.72,N,'Rearme por nuevo flanco','LOGICA');cases{end+1}=c;
c=newcase('Pulso de limite de un ciclo queda enclavado',.7);c.variables=4;c=setv(c,4,.2,.22,-31);c=pulse(c,2,.5);
c=check(c,.24,C,'Un pulso muestreado queda retenido','LOGICA');c=check(c,.52,N,'Rearme posterior','LOGICA');cases{end+1}=c;
% Watchdog: el congelamiento en uno y cero son equivalentes funcionalmente.
for frozen=0:1
 c=newcase(sprintf('Watchdog congelado en %d',frozen),5.9);c.variables=1;c=setv(c,1,.2,inf,frozen);
 c=pulse(c,2,5.4);c=pulse(c,2,5.7);c=setv(c,1,5.42,inf,0);c=pulse(c,1,5.5);
 c=check(c,5.26,W,'Sin cambios aparece fallo y total','LOGICA');c=check(c,5.42,G,'Primer reset limpia WD, total permanece','LOGICA');c=check(c,5.72,N,'Segundo flanco rearma emergencia total','LOGICA');cases{end+1}=c;
end
for partial=1:2
 c=newcase('Watchdog durante emergencia parcial',5.5);if partial==1,col=4;v=-31;st=C;else,col=6;v=41;st=H;end
 c.variables=[1 col];c=setv(c,col,.2,inf,v);c=setv(c,1,.2,inf,1);
 c=check(c,.24,st,'Parcial antes del watchdog','LOGICA');c=check(c,5.2,W,'Watchdog escala parcial a total','LOGICA');cases{end+1}=c;
end
for delta=[-.02 0 .02]
 c=newcase(sprintf('Cambio WD relativo al vencimiento %+.2f s',delta),5.25);c.variables=1;
 c=setv(c,1,.2,5.1+delta,1);c=setv(c,1,5.1+delta,inf,0);
 if delta<0,c=check(c,5.2,N,'Cambio previo renueva temporizador','LOGICA');else,c=check(c,5.2,W,'Al vencer prevalece fallo sobre cambio','LOGICA');end
 cases{end+1}=c;
end
c=newcase('Reinicio normal no sustituye latido WD',5.4);c.variables=[1 2];c=setv(c,1,.2,inf,1);c=pulse(c,2,4);
c=check(c,5.2,W,'Reset en W0 no realimenta el watchdog','LOGICA');cases{end+1}=c;
c=newcase('Reinicio del WD sin restaurar actividad',10.7);c.variables=[1 2];c=setv(c,1,.2,inf,1);c=pulse(c,2,5.4);c=pulse(c,2,5.7);
c=check(c,5.72,N,'Dos flancos permiten rearme aun sin latido','LOGICA');c=check(c,10.5,W,'Nuevo vencimiento tras rearme sin actividad','LOGICA');cases{end+1}=c;
% Condiciones de arranque y entradas no validas: caracterizacion de robustez.
for j=[1 5 7]
 c=newcase(['Limite activo desde arranque - ' limits{j,6}],.4);c.variables=limits{j,1};c=setv(c,limits{j,1},0,inf,limits{j,2}+limits{j,3}*.01);
 c=checkcols(c,.1,find(~limits{j,4}(2:3))+1,0,'Eje peligroso inhibido al arrancar','ROBUSTEZ');cases{end+1}=c;
end
c=newcase('Pulsador activo desde arranque',.4);c.variables=3;c=setv(c,3,0,inf,1);c=check(c,.04,G,'Boton por nivel protege desde el arranque','LOGICA');cases{end+1}=c;
for col=4:7
 c=newcase(sprintf('Entrada fisica no valida NaN - canal %d',col),.5);c.variables=col;c=setv(c,col,.2,inf,NaN);
 if col<=5,idx=2;else,idx=3;end
 c=checkcols(c,.24,idx,0,'Medicion NaN no debe autorizar su eje','ROBUSTEZ');cases{end+1}=c;
end
c=newcase('Pulso entre instantes de muestreo',.5);c.variables=4;
 c.t=sort([c.t;.205;.215]);c.U=interp1((0:.02:.5)',c.U,c.t,'previous');c=setv(c,4,.205,.215,-31);
c=check(c,.24,N,'Un pulso no muestreado no dispara el chart','LOGICA');cases{end+1}=c;
% Completar las ramas de escalamiento que el informe de cobertura identifico.
extra={4,-31,6,-21,'Carro luego limite inferior izaje';4,-31,7,3.5,'Carro luego sobrevelocidad izaje';6,41,4,51,'Izaje luego limite derecho carro'};
for j=1:size(extra,1)
 c=newcase(['Escalamiento - ' extra{j,5}],.6);c.variables=[extra{j,1} extra{j,3}];
 c=setv(c,extra{j,1},.2,inf,extra{j,2});c=setv(c,extra{j,3},.3,inf,extra{j,4});
 c=check(c,.34,G,'Escalamiento por la causa restante del otro eje','LOGICA');cases{end+1}=c;
end
for j=[2 3 4 6 8]
 c=newcase(['Limite activo desde arranque - ' limits{j,6}],.4);c.variables=limits{j,1};c=setv(c,limits{j,1},0,inf,limits{j,2}+limits{j,3}*.01);
 c=checkcols(c,.1,find(~limits{j,4}(2:3))+1,0,'Eje peligroso inhibido al arrancar','ROBUSTEZ');cases{end+1}=c;
end
c=newcase('Limite carro y sobrevelocidad izaje simultaneos',.6);c.variables=[4 7];c=setv(c,4,.2,inf,-31);c=setv(c,7,.2,inf,3.5);
c=check(c,.24,H,'Prioridad de izaje tambien ante exceso de velocidad','LOGICA');c=checkcols(c,.24,[2 3],[0 0],'Ambos ejes peligrosos deben quedar inhibidos','ROBUSTEZ');cases{end+1}=c;
for j=1:numel(cases),cases{j}.id=sprintf('S%02d',j);end
end
function c=newcase(name,T)
t=(0:.02:T)';U=zeros(numel(t),7);U(:,1)=mod(floor((0:numel(t)-1)'/5),2);U(:,6)=10;
c=struct('id','','nombre',name,'t',t,'U',U,'stop',T,'variables',[],'checks',struct('t',{},'cols',{},'expected',{},'texto',{},'tipo',{}));
end
function c=setv(c,col,a,b,v)
c.U(c.t>=a-1e-9 & c.t<b-1e-9,col)=v;
end
function c=pulse(c,col,a)
c=setv(c,col,a,a+.02,1);
end
function c=check(c,t,v,label,type)
c=checkcols(c,t,1:8,v,label,type);
end
function c=checkcols(c,t,cols,v,label,type)
c.checks(end+1)=struct('t',t,'cols',cols,'expected',v,'texto',label,'tipo',type);
end
