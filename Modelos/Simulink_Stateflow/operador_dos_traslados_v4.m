function operador_dos_traslados_v4(block,h)
% Solicitudes por callbacks reales; no fuerza estados ni modifica planta.
fig=ancestor(h.hmi.panel,'figure'); t=block.CurrentTime;
x=double(block.InputPort(1).Data);y=double(block.InputPort(3).Data);
theta=double(block.InputPort(4).Data);mode=double(block.InputPort(10).Data);
loaded=block.InputPort(9).Data>0.5;contact=block.InputPort(11).Data>0.5;
if ~isappdata(fig,'CycleHMI')
 q=struct('stage',0,'entered',t,'leg',1,'route',[6 23 32 1], ...
 'actions',[1 0 1 0],'lastT',t,'lastX',x,'lastY',y,'lastTheta',theta, ...
 'vx',0,'vy',0,'omega',0,'holdAt',NaN,'nextLog',0,'done',false,'abort','', ...
 'events',zeros(0,7),'telemetry',zeros(0,107),'initialProfile',double(block.InputPort(6).Data(:)));
 setappdata(fig,'CycleOutputFolder',h.captureFolder);
 q.registroVideo=false; % Pedido del usuario después del reinicio de la PC.
 setappdata(fig,'CycleHMI',q);
end
q=getappdata(fig,'CycleHMI');
if q.done || ~isempty(q.abort),return;end
if ~isfield(q,'pendingPick'),q.pendingPick=0;end
dt=max(.04,t-q.lastT);q.vx=.75*q.vx+.25*(x-q.lastX)/dt;
q.vy=.75*q.vy+.25*(y-q.lastY)/dt;q.omega=(theta-q.lastTheta)/dt;
q.lastT=t;q.lastX=x;q.lastY=y;q.lastTheta=theta;
row=t;for p=1:42,row=[row double(block.InputPort(p).Data(:)')];end %#ok<AGROW>
q.telemetry(end+1,:)=row;
jt=0;jh=0;
if block.InputPort(22).Data>.5 || block.InputPort(39).Data>.5 || mode==6
 q.abort=sprintf('Falla t=%.2f etapa=%d codigo=%g',t,q.stage,block.InputPort(40).Data);
elseif t-q.entered>300
 q.abort=sprintf('Etapa %d excedio 300 s en t=%.2f',q.stage,t);
end
switch q.stage
 case 0
  if t>=.2,click(h.hmi.startButton);q=advance(q,1);end
 case 1
  if mode==3,click(h.hmi.surveyButton);q=advance(q,2);end
 case 2
  if block.InputPort(37).Data>.5 && block.InputPort(38).Data<.5 && mode==3
   q.scanFinished=t;q.scannedPhysicalProfile=double(block.InputPort(6).Data(:));
   snap('01_barrido');q=advance(q,3);
  end
 case 3
  % Despeje local antes de cada solicitud AUTO (vacio o cargado).
  planLoaded=ismember(q.leg,[2 4]);
  if q.pendingPick>0 && loaded
   q.transferTimes(q.pendingPick)=t;q.profiles(:,q.pendingPick)=double(block.InputPort(6).Data(:));
   snap(sprintf('transferencia_%d',q.pendingPick));q.pendingPick=0;
  end
  if isnan(q.holdAt)
   if y<localHeight(block,x,planLoaded)+1 || (planLoaded && ~loaded),jh=.2;else,q.holdAt=t;end
  elseif t-q.holdAt>=2 && abs(q.vy)<.03 && loaded==planLoaded
   set(h.hmi.slotEdit,'String',num2str(q.route(q.leg)));click(h.hmi.applySlot);
   set(h.hmi.modeButton,'Value',1);click(h.hmi.modeButton);click(h.hmi.autoStartButton);
   q=advance(q,4);
  end
 case 4
  if mode==4,q=advance(q,5);end
 case 5
  target=-30+(q.route(q.leg)-.5)*2.44;
  arrived=abs(x-target)<.25 && abs(q.vx)<.15;
  if arrived && (~loaded || y<=double(block.InputPort(36).Data)+.25)
   set(h.hmi.modeButton,'Value',0);click(h.hmi.modeButton);q=advance(q,6);
  end
 case 6
  if mode==3 && abs(q.vx)<.08 && abs(theta)<.02 && abs(q.omega)<.02
   if isnan(q.holdAt),q.holdAt=t;end
   if t-q.holdAt>=2,q=advance(q,7);end
  else,q.holdAt=NaN;end
 case 7
  jh=-.2;
  if contact
   jh=0;q.contactTimes(q.leg)=t;snap(sprintf('contacto_%d',q.leg));
   set(h.hmi.twistlockButton,'Value',q.actions(q.leg));click(h.hmi.twistlockButton);
   q=advance(q,8);
  end
 case 8
  expected=logical(q.actions(q.leg));
  if expected && block.InputPort(5).Data>.5 && t-q.entered>.4
   % PICK/PLACE confirma la carga durante la extraccion, no al cerrar TLK.
   q.pendingPick=q.leg;q.pickCloseTimes(q.leg)=t;
   q.leg=q.leg+1;q=advance(q,3);
  elseif ~expected && ~loaded && block.InputPort(5).Data<.5 && t-q.entered>.4
   q.transferTimes(q.leg)=t;q.profiles(:,q.leg)=double(block.InputPort(6).Data(:));
   snap(sprintf('transferencia_%d',q.leg));
   if q.leg<4,q.leg=q.leg+1;q=advance(q,3);
   else,click(h.hmi.stopButton);q=advance(q,9);end
  end
 case 9
  if t-q.entered>2 && mode==0 && ~loaded && abs(q.vx)<.1 && abs(q.vy)<.1
   q.done=true;q.finalProfile=double(block.InputPort(6).Data(:));snap('05_final');
  end
end
s=getappdata(fig,'CraneHMIState');s.keyboardTrolley=jt;s.keyboardHoist=jh;s.lastKeyEvent=now;
setappdata(fig,'CraneHMIState',s);setappdata(fig,'CycleHMI',q);
setappdata(groot,'FullCycleSnapshot',q);
if t>=q.nextLog || q.done || ~isempty(q.abort)
 state=rmfield(q,'telemetry');writeJson(fullfile(h.captureFolder,'progreso.json'),state);
 save(fullfile(h.captureFolder,'operador_progreso.mat'),'q');q.nextLog=t+5;setappdata(fig,'CycleHMI',q);
 fprintf('PRUEBA t=%.2f etapa=%d tramo=%d x=%.2f y=%.2f carga=%d\n',t,q.stage,q.leg,x,y,loaded);
end
if q.done || ~isempty(q.abort)
 % El motor termina por StopTime fuera del callback de la S-function.
 save(fullfile(h.captureFolder,'operador_final.mat'),'q','-v7.3');
end
 function q=advance(q,stage)
  q.stage=stage;q.entered=t;q.holdAt=NaN;q.events(end+1,:)=[stage t q.leg x y loaded contact];
 end
 function snap(name)
  drawnow;frame=getframe(fig);imwrite(frame.cdata,fullfile(h.captureFolder,[name '.png']));
 end
end
function click(control),cb=get(control,'Callback');cb(control,[]);end
function writeJson(path,value)
fid=fopen(path,'w','n','UTF-8');if fid>0,fprintf(fid,'%s',jsonencode(value,PrettyPrint=true));fclose(fid);end
end
function yl=localHeight(block,x,loaded)
env=double(block.InputPort(42).Data(:));surface=-20;
for k=1:min(33,numel(env))
 a=-30+(k-1)*2.44;b=a+2.44;
 if b>x-1.22+1e-6 && a<x+1.22-1e-6,surface=max(surface,env(k));end
end
base=surface+2.59+2.59*loaded;rope=max(5,min(65,45-base));
yl=base+65000*9.80665/(4*(236e6/(2*rope+110)));
end

