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
