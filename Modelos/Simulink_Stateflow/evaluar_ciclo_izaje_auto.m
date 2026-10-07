function report=evaluar_ciclo_izaje_auto(o,q)
% Evalua un ciclo con retorno vacio sin descenso final.
t=(0:0.02:double(o.mon_yH.Time(end))).';
mode=sample(o.sup_modeCode,t,'previous');
loaded=sample(o.sup_loadedState,t,'previous')>0.5;
yl=sample(o.mon_yH,t,'linear'); yr=sample(o.mon_yRef,t,'linear');
vy=sample(o.mon_vH,t,'linear'); vyr=sample(o.mon_vyRef,t,'previous');
ay=sample(o.mon_aHoistMeasured,t,'linear');
x=sample(o.mon_xT,t,'linear'); xr=sample(o.mon_xRef,t,'linear');
vx=sample(logSignal(o,'carro_velocidad_real'),t,'linear');
axMeasured=sample(o.mon_aTrolleyMeasured,t,'linear');
ax=sample(logSignal(o,'carro_aceleracion_fisica'),t,'linear');
theta=rad2deg(sample(o.mon_theta,t,'linear'));
rope=sample(o.mon_ropeTension,t,'linear');
mass=15000+sample(logSignal(o,'masa_contenedor_estimada'),t,'previous');
mass=max(15000,min(65000,mass));
massPhysical=15000+sample(logSignal(o,'masa_contenedor_fisica'),t,'previous');
vAllowed=min(3,max(1.5,97500./mass));
vAllowedPhysical=min(3,max(1.5,97500./massPhysical));
torque=sample(logSignal(o,'torque_izaje_fisico_motor'),t,'linear');
omegaDrum=sample(logSignal(o,'tambor_izaje_velocidad_angular'),t,'linear');
omegaMotor=22.0*omegaDrum;
brake=sample(logSignal(o,'freno_operacion_izaje_torque'),t,'linear');
fault=sample(o.sup_faultCode,t,'previous');
emergency=sample(o.n0_emergency,t,'previous');
tracking=sample(o.mon_trackingFault,t,'previous');
loadedAuto=mode==4 & loaded;
emptyAuto=mode==4 & ~loaded;
automatic=loadedAuto|emptyAuto;
assert(any(loadedAuto)&&any(emptyAuto),'No hubo dos tramos automaticos');
finalRequest=q.manualRequests(end,1);
afterRequest=t>=finalRequest;
finalY=yl(end); finalX=x(end);
returnTop=max(yl(emptyAuto));
movingHoist=automatic & abs(vyr)>0.05;
cruise=automatic & abs(sample(o.mon_axRef,t,'previous'))<0.03 & abs(sample(o.mon_vxRef,t,'previous'))>0.3;
arrivals=[q.events(find(q.events(:,1)==8,1),2), ...
    q.events(find(q.events(:,1)==13,1),2)];
arrivalTheta=[abs(interp1(t,theta,arrivals(1))),abs(interp1(t,theta,arrivals(2)))];
autoStart=sort(t([false;diff(mode==4)==1]));
errorY=max(abs(yl(automatic)-yr(automatic)));
report=struct;
report.duration_s=double(o.mon_yH.Time(end));
report.historicoCompletoMasaIncorrecta_s=504.7980;
report.historicoSinDescensoMasaIncorrecta_s=461.1983;
report.diferenciaHistoricaCompleta_s=report.historicoCompletoMasaIncorrecta_s-report.duration_s;
report.diferenciaHistoricaSinDescenso_s=report.historicoSinDescensoMasaIncorrecta_s-report.duration_s;
report.referenciaCap03MasaCorrectaAborto_s=452.5977;
report.referenciaCap03MasaCorrectaTermino=false;
report.termino=q.done;
report.aborto=q.abort;
report.autoInicios_s=autoStart;
report.eventos=q.events;
report.duracionAutoCargado_s=q.events(q.events(:,1)==8,2)-q.events(q.events(:,1)==7,2);
report.duracionAutoVacio_s=q.events(q.events(:,1)==13,2)-q.events(q.events(:,1)==12,2);
report.solicitudesAuto=q.autoRequests;
report.solicitudesManual=q.manualRequests;
report.maxVelRealCargado_mps=max(abs(vy(loadedAuto)));
report.maxVelRefCargado_mps=max(abs(vyr(loadedAuto)));
report.maxLimiteCargado_mps=max(vAllowed(loadedAuto));
report.masaEstimadaTotalCargada_kg=median(mass(loadedAuto));
report.masaFisicaTotalCargada_kg=median(massPhysical(loadedAuto));
report.errorEstimacionMasa_relativo=abs(report.masaEstimadaTotalCargada_kg- ...
    report.masaFisicaTotalCargada_kg)/ ...
    (report.masaFisicaTotalCargada_kg-15000);
report.excesoRefSobreLimite_mps=max(abs(vyr(loadedAuto))-vAllowed(loadedAuto));
report.excesoRefSobreLimiteFisico_mps=max(abs(vyr(loadedAuto))-vAllowedPhysical(loadedAuto));
report.maxVelRealVacio_mps=max(abs(vy(emptyAuto)));
report.maxAceleracionIzajeAuto_mps2=max(abs(ay(automatic)));
report.maxVelCarroAuto_mps=max(abs(vx(automatic)));
report.maxAceleracionCarroAuto_mps2=max(abs(ax(automatic)));
report.maxAceleracionEstimadaDesdeMotor_mps2=max(abs(axMeasured(automatic)));
report.maxErrorYAuto_m=errorY;
report.maxErrorXAuto_m=max(abs(x(automatic)-xr(automatic)));
report.tensionAutoCargadoMin_N=min(rope(loadedAuto));
report.tensionAutoCargadoMax_N=max(rope(loadedAuto));
report.maxTorqueIzajeFisico_Nm=max(abs(torque(automatic)));
report.maxPotenciaMecanicaIzaje_kW=max(abs(torque(automatic).*omegaMotor(automatic)))/1000;
report.maxTorqueFrenoEnMovimiento_Nm=max(abs(brake(movingHoist)));
report.maxAnguloAuto_deg=max(abs(theta(automatic)));
report.maxAnguloCrucero_deg=max(abs(theta(cruise)));
report.anguloLlegadaCargado_deg=arrivalTheta(1);
report.anguloLlegadaVacio_deg=arrivalTheta(2);
report.xFinal_m=finalX;
report.yFinal_m=finalY;
report.caidaDesdeMaxRetornoVacio_m=returnTop-finalY;
report.caidaDespuesPedidoManualVacio_m=max(yl(afterRequest))-finalY;
report.faultCodes=unique(fault).';
report.anyEmergency=any(emergency>0.5);
report.anyTrackingFault=any(tracking>0.5);
names=["Ciclo terminado sin aborto";"Dos tramos automaticos"; ...
    "Sin fallas ni emergencia";"Masa estimada y referencia dentro de potencia constante"; ...
    "Velocidad y aceleracion de izaje dentro de guia"; ...
    "Velocidad y aceleracion de carro dentro de guia"; ...
    "Torque y potencia de motor de izaje dentro de guia"; ...
    "Freno de operacion abierto al mover izaje automatico"; ...
    "Tension positiva y seguimiento vertical"; ...
    "Balanceo dentro de limites de guia"; ...
    "Retorno a x de slot 2 sin descenso final"; ...
    "Ciclo terminado antes del tiempo maximo de ensayo"];
passed=[q.done && isempty(q.abort);numel(autoStart)==2; ...
    ~any(fault~=0)&&~report.anyEmergency&&~report.anyTrackingFault; ...
    report.errorEstimacionMasa_relativo<0.01 && ...
        report.excesoRefSobreLimite_mps<0.02 && ...
        report.excesoRefSobreLimiteFisico_mps<0.02; ...
    max(abs(vy(automatic)))<3.05 && report.maxAceleracionIzajeAuto_mps2<0.80; ...
    report.maxVelCarroAuto_mps<4.05 && report.maxAceleracionCarroAuto_mps2<0.85; ...
    report.maxTorqueIzajeFisico_Nm<20050 && report.maxPotenciaMecanicaIzaje_kW<1000; ...
    report.maxTorqueFrenoEnMovimiento_Nm<10; ...
    report.tensionAutoCargadoMin_N>1000 && errorY<0.25; ...
    report.maxAnguloAuto_deg<20 && report.maxAnguloCrucero_deg<5 && ...
        all(arrivalTheta<1); ...
    abs(finalX+26.34)<0.35 && report.caidaDesdeMaxRetornoVacio_m<0.2 && ...
        report.caidaDespuesPedidoManualVacio_m<0.2; ...
    report.duration_s<900];
report.checks=table(names,passed,'VariableNames',{'criterio','cumple'});
report.passed=all(passed);
end

function v=sample(s,t,method)
v=interp1(double(s.Time(:)),double(s.Data(:)),t,method,'extrap');
end

function s=logSignal(o,name)
element=o.logsout.get(name);
assert(~isempty(element),'Falta senal interna: %s',name);
s=element.Values;
end
