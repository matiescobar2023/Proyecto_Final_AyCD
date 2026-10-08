function [qNext,wNext]=actualizar_observador_encoder(q,w,uPrevious,u,p)
%#codegen
% Trapezoidal: x[n]=Ad*x[n-1]+Bd*(u[n-1]+u[n]).
% La primera muestra y la IC=0 se manejan en el propietario del estado.
qNext=(p.obsA11*q+p.obsA12*w)+p.obsB1*(uPrevious+u);
wNext=(p.obsA21*q+p.obsA22*w)+p.obsB2*(uPrevious+u);
end
