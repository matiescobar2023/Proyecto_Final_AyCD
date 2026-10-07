function result=verificar_observadores_variadores()
% Banco sin planta. Referencia continua EXACTA para entradas lineales entre ticks.
root=fileparts(mfilename('fullpath'));addpath(root,'-begin');p=evalin('base','MC_FF');
h=p.Ts;t=(0:h:6)';A=[-2*p.observerZeta*p.observerWn,1;-p.observerWn^2,0];
B=[2*p.observerZeta*p.observerWn;p.observerWn^2];
aug=zeros(4);aug(1:2,1:2)=A;aug(1:2,3)=B;aug(3,4)=1;F=expm(h*aug);
rows=cell(3,6);
for scenario=1:3
 clear mc_estimadores
 if scenario==1,uT=2*ones(size(t));uH=-ones(size(t));name='Encoder inicial no nulo';
 elseif scenario==2,uT=.3*t;uH=-.5*t;name='Rampa';
 else,uT=.2*sin(1.7*t);uH=.3*sin(1.2*t);name='Seno';end
 refT=[0;0];refH=[0;0];maxQ=0;maxWT=0;maxWH=0;firstOmega=NaN;
 for j=1:numel(t)
  s=struct('force',0.0,'motorAngleT',p.i_t*uT(j),'motorAngleH',p.i_h*uH(j),'theta',0.0);
  [ct,ch]=mc_estimadores(s,p);
  if j>1
   state=F*[refT;uT(j-1);(uT(j)-uT(j-1))/h];refT=state(1:2);
   state=F*[refH;uH(j-1);(uH(j)-uH(j-1))/h];refH=state(1:2);
  else,firstOmega=max(abs([ct.omegaDrum,ch.omegaDrum]));end
  maxQ=max(maxQ,max(abs([ct.observerAngle-refT(1),ch.observerAngle-refH(1)])));
  maxWT=max(maxWT,abs(ct.omegaDrum-refT(2)));maxWH=max(maxWH,abs(ch.omegaDrum-refH(2)));
 end
 rows(scenario,:)={name,maxQ,maxWT,maxWH,p.r_td*maxWT,p.r_hd/2*maxWH};
 assert(firstOmega==0,'La primera salida no conserva IC=0.');
end
result=struct('metrics',cell2table(rows,'VariableNames',{'scenario','maxAngleError_rad', ...
 'maxOmegaTError_radps','maxOmegaHError_radps','maxTrolleySpeedError_mps','maxLengthRateError_mps'}), ...
 'sampleTime_s',h,'duration_s',6,'initialOutputPreserved',true, ...
 'reference','Solucion continua exacta por exponencial de matriz con entrada lineal entre muestras', ...
 'poles',eig([p.obsA11 p.obsA12;p.obsA21 p.obsA22]));
result.stable=all(abs(result.poles)<1);assert(result.stable);disp(result.metrics);
clear mc_estimadores
end
