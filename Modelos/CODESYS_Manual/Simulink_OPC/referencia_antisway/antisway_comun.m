function [sw,feedbackUsed,anticipationUsed,activation]=antisway_comun(feedback,thetaRef,length,E,brakeOpen,Ts,T_SW_on)
%#codegen
% Feedback sin rampa; anticipacion y habilitacion tienen memorias separadas.
persistent ff gain
if isempty(ff),ff=0.0;gain=0.0;end
if ~E || ~brakeOpen
 ff=0.0;gain=0.0;
 sw=0.0;feedbackUsed=0.0;anticipationUsed=0.0;activation=0.0;return;
end
h=max(1e-6,Ts);
gain=min(1.0,gain+h/T_SW_on);
k=2.0*sqrt(9.80665*max(1.0,length));
target=-k*thetaRef;
% Limita solo la velocidad de cambio de la anticipacion, no del feedback.
ff=ff+min(.25*h,max(-.25*h,target-ff));
feedbackUsed=gain*feedback;anticipationUsed=gain*ff;activation=gain;
sw=min(3.2,max(-3.2,feedbackUsed+anticipationUsed));
end
