function [cart,hoist]=mc_estimadores(s,p)
%#codegen
% Dos observadores Tustin de encoders, independientes de referencias y modos.
persistent qt wt qh wh previousT previousH started
if isempty(qt)
 qt=0.0;wt=0.0;qh=0.0;wh=0.0;previousT=0.0;previousH=0.0;started=false;
end
ut=s.motorAngleT/p.i_t;uh=s.motorAngleH/p.i_h;
if started
 [qt,wt]=actualizar_observador_encoder(qt,wt,previousT,ut,p);
 [qh,wh]=actualizar_observador_encoder(qh,wh,previousH,uh,p);
else
 started=true;
end
previousT=ut;previousH=uh;
cart=struct('x',p.r_td*ut,'omegaDrum',wt,'velocity',p.r_td*wt,'observerAngle',qt);
hoist=struct('length',p.length0-(p.r_hd/2)*uh,'lengthRate',(p.r_hd/(-2))*wh, ...
 'omegaDrum',wh,'observerAngle',qh);
end
function [qNext,wNext]=actualizar_observador_encoder(q,w,uPrevious,u,p)
%#codegen
% Trapezoidal: x[n]=Ad*x[n-1]+Bd*(u[n-1]+u[n]).
% La primera muestra y la IC=0 se manejan en el propietario del estado.
qNext=(p.obsA11*q+p.obsA12*w)+p.obsB1*(uPrevious+u);
wNext=(p.obsA21*q+p.obsA22*w)+p.obsB2*(uPrevious+u);
end
