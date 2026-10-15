function [torque,sw,d]=mc_eje_carro(s,r,c,drive,est,hoist,p)
%#codegen
% Variador de carro. Estimaciones recibidas del estimador interno del MC.
persistent ff gain
if isempty(gain),ff=0.0;gain=0.0;end
omega=est.omegaDrum;
k=2.0*sqrt(p.gravity*hoist.length); anticipationGain=2.0*sqrt(9.80665*max(1.0,hoist.length));
thetaEff=double(c.E)*s.theta;
feedback=k*(thetaEff-0.0);
thetaRef=atan2(-r.aRef,p.gravity);
if ~c.E || ~c.brakeOpen
 ff=0.0;gain=0.0;sw=0.0;feedbackUsed=0.0;anticipationUsed=0.0;
else
 gain=min(1.0,gain+max(1e-6,p.Ts)/p.swayOnTime);
 target=-anticipationGain*thetaRef;
 h=max(1e-6,p.Ts);
 ff=ff+min(p.swayFFRate*h,max(-p.swayFFRate*h,target-ff));
 anticipation=ff;
 feedbackUsed=gain*feedback;anticipationUsed=gain*anticipation;
 sw=min(3.2,max(-3.2,feedbackUsed+anticipationUsed));
end
vBase=(r.vRef+sw)+r.swTransfer;
[torque,vRaw,vCmd,vObs,I,pTerm,iTerm,aRaw,aCmd,ev,deltaA,deltaAPrevious, ...
 deltaATorque,deltaATotal,awCorrection,uI]=controlador_carro_mc_r2( ...
 s.force,omega,vBase,r.xRef,r.aRef,est.x,s.theta,drive.deltaTorqueDelayed,p);
d=struct('diag_torque_unsat',torque,'diag_vcmd',vRaw,'diag_vcmd_applied',vCmd, ...
 'diag_vobs',vObs,'diag_integral',I,'diag_p',pTerm,'diag_i',iTerm,'diag_acmd',aRaw, ...
 'diag_acmd_applied',aCmd,'diag_ev',ev,'aw_delta_a_limite',deltaA, ...
 'aw_delta_a_limite_memoria',deltaAPrevious,'aw_delta_a_torque',deltaATorque, ...
 'aw_delta_a_total',deltaATotal,'aw_correccion_integrador',awCorrection, ...
 'mc_integrator_input',uI,'antisway_correccion_aplicada',sw, ...
 'sw_feedback_comun',feedbackUsed,'sw_anticipacion_comun',anticipationUsed, ...
 'sw_habilitacion_comun',gain,'diag_sw_unsat',feedback,'diag_sw_gain',k, ...
 'angulo_referencia',thetaRef,'diag_aff',r.aRef,'diag_xref_input',r.xRef, ...
 'diag_vref_input',r.vRef,'diag_aref_input',r.aRef,'diag_xencoder',est.x, ...
 'diag_omega_observer',omega,'diag_theta_medida',s.theta,'diag_theta_eff',thetaEff, ...
 'diag_brake_supervisor',double(c.brakeOpen));
end
function [torque,vRaw,vCmd,vObs,I,pTerm,iTerm,aRaw,aCmd,ev, ...
 deltaA,deltaAPrevious,deltaATorque,deltaATotal,awCorrection,uI]= ...
 controlador_carro_mc_r2(force,omega,vBase,xRef,aRef,x,theta,deltaTorque,p)
%#codegen
% N2 de R2: PI Tustin limitado, AW de aceleracion y torque con demora 1 ms.
% El regulador no recibe modo, enable de eje ni reset; N0 autoriza el par.
persistent integralState previousDeltaA
if isempty(integralState)
 integralState=0.0;previousDeltaA=0.0;
end
vObs=p.r_td*omega;
vRaw=vBase+p.Kx*(xRef-x);
vCmd=min(p.vmax,max(-p.vmax,vRaw));
ev=vCmd-vObs;
deltaAPrevious=previousDeltaA;
deltaATorque=(p.i_t/(p.r_td*p.M_EQt))*deltaTorque;
deltaATotal=deltaAPrevious+deltaATorque;
awCorrection=(1/p.Ki)*deltaATotal;
uI=ev+awCorrection;
% IC=0 es el estado X; la salida incluye el medio paso de entrada actual.
I=min(p.Imax,max(-p.Imax,integralState+p.Ts/2*uI));
% El bloque original limita salida Y y estado X por separado en Tustin.
% Esto permite salir del limite en el primer medio paso de signo contrario.
integralState=min(p.Imax,max(-p.Imax,I+p.Ts/2*uI));
pTerm=p.Kp*ev;iTerm=p.Ki*I;
aRaw=aRef+(pTerm+iTerm);
aCmd=min(p.amax,max(-p.amax,aRaw));
deltaA=aCmd-aRaw;
% Conservar la estructura de operaciones del Computed Torque de R2.
friction=(p.b_EQt/p.M_EQt)*vObs;
horizontal=(2/p.M_EQt)*(force*sin(theta));
torque=((p.r_td*p.M_EQt)/p.i_t)*((friction+aCmd)-horizontal);
previousDeltaA=deltaA;
end

