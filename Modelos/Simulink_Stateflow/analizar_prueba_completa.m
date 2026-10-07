function analizar_prueba_completa(out,folder)
if nargin<1,out=evalin('base','FullCycleOutput');end
if nargin<2,folder=evalin('base','FullCycleFolder');end
Q=load(fullfile(folder,'operador_final.mat'));q=Q.q;
signals=struct;coverage=cell(0,8);
if ismember('logsout',out.who),for k=1:out.logsout.numElements,e=out.logsout.get(k);walk(e.Values,e.Name);end;end
for key=out.who',name=key{1};if strcmp(name,'logsout'),continue;end;v=out.get(name);if isa(v,'timeseries')||isstruct(v),walk(v,name);end;end
t=signals.y_carga_fisica.t;
omegaRef=signals.angulo_referencia;omegaRef.v=gradient(omegaRef.v,omegaRef.t);
signals.velocidad_angular_referencia_derivada=omegaRef;
save(fullfile(folder,'senales_originales.mat'),'signals','q','-v7.3');
C=cell2table(coverage,'VariableNames',{'senal','inicio_s','fin_s','muestras','cubreFin','pasoMaximo_s','retrasoFinal_s','serieUnica'});writetable(C,fullfile(folder,'cobertura_registro.csv'));
writeJson(fullfile(folder,'catalogo_senales.json'),fieldnames(signals));
if isfield(q,'scanFinished')
 p=signals.mon_scannedObstacleProfile;[~,idx]=min(abs(p.t-q.scanFinished));profile=p.v(idx,:).';
else,profile=nan(33,1);end
if isfield(q,'finalProfile'),final=q.finalProfile;else,final=q.telemetry(end,7:39).';end
initial=q.initialProfile;slots=(1:33).';operable=~ismember(slots,[11 12 13 33]);
delta=final-initial;expected=zeros(33,1);expected([6 32])=-2.59;expected([23 1])=2.59;
P=table(slots,-30+(slots-.5)*2.44,operable,initial,profile,final,delta, ...
 'VariableNames',{'slot','x_m','operable','inicial_m','relevado_m','final_m','cambio_m'});writetable(P,fullfile(folder,'perfiles.csv'));
events=array2table(q.events,'VariableNames',{'etapa','tiempo_s','tramo','x_m','y_m','cargado','contacto'});writetable(events,fullfile(folder,'eventos.csv'));
meta=struct('completo',q.done,'causa',q.abort,'duracion_s',q.lastT,'ruta',q.route, ...
 'perfilErrorMaximo_m',max(abs(profile(operable)-initial(operable))), ...
 'balancePerfilErrorMaximo_m',max(abs(delta-expected)), ...
 'cantidadSenales',numel(fieldnames(signals)),'registroCompleto',all(C.cubreFin|C.serieUnica),'videoVelocidad',5, ...
 'muestreoHMI_s',.04,'muestreoVideo_s',.20,'decimacionRegistro',10);
if isfield(q,'contactTimes'),meta.contactos_s=q.contactTimes;end
if isfield(q,'transferTimes'),meta.transferencias_s=q.transferTimes;end
meta.emergencia=max(signals.n0_emergency.v);meta.fallaSeguimiento=max(signals.mon_trackingFault.v);
meta.finRegistroFisico_s=t(end);
meta.codigoFalla=max(signals.sup_faultCode.v);meta.masaFinal_kg=signals.masa_fisica_suspendida.v(end);
edges=diff(signals.mon_loadedPhysical.v>.5);meta.numeroTomas=sum(edges>0);meta.numeroEntregas=sum(edges<0);
names={'v_carro_fisica','v_izaje_fisica','aceleracion_carro_fisica','aceleracion_izaje_fisica', ...
 'angulo_fisico','velocidad_angular_fisica','torque_carro_fisico_motor','torque_izaje_fisico_motor'};
for k=1:numel(names),meta.maximosAbsolutos.(names{k})=max(abs(signals.(names{k}).v));end
z=signals.aceleracion_izaje_fisica;[~,idx]=max(abs(z.v));meta.picoAceleracionIzaje=struct('tiempo_s',z.t(idx),'valor_m_s2',z.v(idx));
meta.trasladosCargados=struct('tramo',{},'inicio_s',{},'fin_s',{},'anguloMaximo_rad',{},'velocidadCarroMaxima_m_s',{});
for leg=[2 4]
 a=find(q.events(:,1)==5 & q.events(:,3)==leg,1);b=find(q.events(:,1)==6 & q.events(:,3)==leg,1);
 if isempty(a)||isempty(b),continue;end
 t0=q.events(a,2);t1=q.events(b,2);z=signals.angulo_fisico;ix=z.t>=t0&z.t<=t1;ang=max(abs(z.v(ix)));
 z=signals.v_carro_fisica;ix=z.t>=t0&z.t<=t1;vel=max(abs(z.v(ix)));
 meta.trasladosCargados(end+1)=struct('tramo',leg,'inicio_s',t0,'fin_s',t1,'anguloMaximo_rad',ang,'velocidadCarroMaxima_m_s',vel);
end
meta.videoDisponible=isfile(fullfile(folder,'prueba_completa.mp4'));
meta.videoCubreEnsayo=false;
meta.videoOmitidoPorPedidoUsuario=isfield(q,'registroVideo') && ~q.registroVideo;
if meta.videoOmitidoPorPedidoUsuario,meta.muestreoVideo_s=[];meta.videoVelocidad=[];end
if meta.videoDisponible,v=VideoReader(fullfile(folder,'prueba_completa.mp4'));meta.videoDuracion_s=v.Duration;meta.videoAncho=v.Width;meta.videoAlto=v.Height;meta.videoCubreEnsayo=v.Duration*5>=q.lastT-.25;end
writeJson(fullfile(folder,'resumen.json'),meta);
save(fullfile(folder,'resumen.mat'),'meta','P','events');
fprintf('ANALISIS: %d senales; completo=%d; error perfil=%g m; balance=%g m\n',meta.cantidadSenales,q.done,meta.perfilErrorMaximo_m,meta.balancePerfilErrorMaximo_m);
 function walk(v,name)
  if isa(v,'timeseries') && ~isempty(v.Time)
   if isempty(name),name=sprintf('anonima_%d',numel(fieldnames(signals))+1);end
   key=matlab.lang.makeValidName(name);base=key;n=2;while isfield(signals,key),key=[base '_' num2str(n)];n=n+1;end
   tt=double(v.Time(:));values=double(squeeze(v.Data));
   if numel(tt)==1,values=reshape(values,1,[]);elseif isvector(values),values=values(:);elseif size(values,1)~=numel(tt) && size(values,2)==numel(tt),values=values.';end
   assert(size(values,1)==numel(tt),'Dimensiones incompatibles: %s',name);
   signals.(key)=struct('t',tt,'v',values);
   if numel(tt)>1,step=max(diff(tt));else,step=0;end
   coverage(end+1,:)={key,tt(1),tt(end),numel(tt),tt(end)>=q.lastT-max(.04,step)-1e-6,step,q.lastT-tt(end),numel(tt)==1};
  elseif isstruct(v),for f=fieldnames(v)',walk(v.(f{1}),[name '_' f{1}]);end
  elseif isa(v,'Simulink.SimulationData.Dataset'),for j=1:v.numElements,e=v.get(j);walk(e.Values,[name '_' e.Name]);end
  end
 end
end
function writeJson(path,value)
fid=fopen(path,'w','n','UTF-8');assert(fid>0);guard=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(value,PrettyPrint=true));
end
