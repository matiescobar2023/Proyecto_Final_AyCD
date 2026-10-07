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
