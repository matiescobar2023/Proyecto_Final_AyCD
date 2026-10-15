function [torque,d]=mc_eje_izaje(s,r,est,p)
%#codegen
% Variador de izaje. No implementa ninguna funcion del automata.
[torque,ev,z1,z2,P,D,I,ff]=controlador_izaje_mc_r2( ...
 s.force,-r.hoistVelocityRef,est.lengthRate,-r.hoistAccelerationRef,p);
d=struct('torque_izaje_consigna_controlador',torque,'mc_hoist_velocity_error',ev, ...
 'mc_hoist_integral1',z1,'mc_hoist_integral2',z2,'mc_hoist_P',P, ...
 'mc_hoist_D',D,'mc_hoist_I',I,'mc_hoist_FF',ff);
end
function [torque,errorVelocity,z1,z2,pTerm,dTerm,iTerm,ff]= ...
 controlador_izaje_mc_r2(force,vRef,vMeasured,aRef,p)
%#codegen
% Doble integracion Tustin de R2, sin seleccion por modo ni AW adicional.
persistent firstIntegral secondIntegral previousError previousFirst
if isempty(firstIntegral)
 firstIntegral=0.0;secondIntegral=0.0;previousError=0.0;previousFirst=0.0;
end
errorVelocity=vRef-vMeasured;
firstIntegral=(p.Ts/2)*(previousError+errorVelocity)+firstIntegral;
secondIntegral=(p.Ts/2)*(previousFirst+firstIntegral)+secondIntegral;
z1=firstIntegral;z2=secondIntegral;
pTerm=p.Khp*z1;dTerm=p.Khd*errorVelocity;iTerm=p.Khi*z2;
feedback=(iTerm+pTerm)+dTerm;
forceTerm=(-p.r_hd/p.i_h)*force;
ff=(-p.r_hd/p.i_h)*(p.M_EQh*aRef+p.b_EQh*vRef);
torque=ff+(feedback-forceTerm);
previousError=errorVelocity;previousFirst=firstIntegral;
end

