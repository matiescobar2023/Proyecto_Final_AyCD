function operador_medio_ciclo(block,h)
% Operador virtual para la prueba conjunta. Solo usa botones y joysticks
% reales del HMI; los estados, la trayectoria y la seguridad son del PLC.
fig = ancestor(h.hmi.panel,'figure');
t = double(block.CurrentTime);
if ~isappdata(fig,'CODESYSCycle')
    set(fig,'Name','STS_HMI_CODESYS_PRUEBA_CONJUNTA', ...
        'WindowState','normal','Position',[35 35 1280 720]);
    figure(fig); % Solo el HMI y la visualizacion de Simulink en el video.
    if strcmp(getenv('CODESYS_JOINT_NO_VIDEO'),'1')
        % Ensayo de validacion: no crear ni capturar ningun video.
        videoFile = '';
    elseif strcmp(getenv('CODESYS_JOINT_EXTERNAL_VIDEO'),'1')
        % La captura externa no bloquea el ciclo que envia latidos OPC UA.
        videoFile = strtrim(getenv('CODESYS_JOINT_EXTERNAL_VIDEO_FILE'));
        if isempty(videoFile)
            error('Falta CODESYS_JOINT_EXTERNAL_VIDEO_FILE.');
        end
    else
        videoDir = fullfile(fileparts(mfilename('fullpath')),'Video_prueba_conjunta');
        if ~isfolder(videoDir), mkdir(videoDir); end
        videoFile = fullfile(videoDir, ...
            ['Prueba_HMI_Simulink_' datestr(now,'yyyymmdd_HHMMSS') '.mp4']);
        writer = VideoWriter(videoFile,'MPEG-4');
        writer.FrameRate = 2;
        writer.Quality = 85;
        open(writer);
        setappdata(fig,'CODESYSJointVideoWriter',writer);
        setappdata(fig,'CODESYSJointVideoNext',0);
    end
    if ~isempty(videoFile)
        setappdata(0,'CODESYSJointVideoFile',videoFile);
        fprintf('VIDEO_HMI_ARCHIVO=%s\n',videoFile);
    end
    q = struct('stage',0,'entered',t,'nextLog',t,'lastT',t, ...
        'lastX',double(block.InputPort(1).Data), ...
        'lastY',double(block.InputPort(3).Data), ...
        'vx',0,'vy',0,'lastVx',0,'lastVy',0,'lastReset',-inf, ...
        'dockX',-26.34,'dockSlot',2,'shipSlot',22, ...
        'events',zeros(0,5),'initialProfile',double(block.InputPort(6).Data(:)), ...
        'approachCommitted',false,'approachPhase',0,'phaseEntered',t, ...
        'settledSince',NaN,'lastTheta',0,'omega',0, ...
        'vxFiltered',0,'vyFiltered',0, ...
        'loadedHandoffHoldAt',NaN,'emptyHandoffHoldAt',NaN, ...
        'requestedManualLoaded',false,'requestedManualEmpty',false, ...
        'done',false,'abort','', ...
        'maxTrackingGap',0,'transitionToAutoY',NaN,'transitionToManualX',NaN, ...
        'telemetry',zeros(0,22));
else
    q = getappdata(fig,'CODESYSCycle');
end
x = double(block.InputPort(1).Data);
y = double(block.InputPort(3).Data);
theta = double(block.InputPort(4).Data);
mode = double(block.InputPort(10).Data);
loaded = logical(block.InputPort(9).Data);
contact = logical(block.InputPort(11).Data);
emergency = logical(block.InputPort(22).Data);
watchdog = logical(block.InputPort(29).Data);
fault = double(block.InputPort(40).Data);
valid = logical(block.InputPort(37).Data);
scanning = logical(block.InputPort(38).Data);
complete = logical(block.InputPort(41).Data);
clearance = double(block.InputPort(35).Data);
dt = max(t-q.lastT,0.04);
q.vx = (x-q.lastX)/dt;
q.vy = (y-q.lastY)/dt;
q.omega = (theta-q.lastTheta)/dt;
q.vxFiltered = 0.75*q.vxFiltered+0.25*q.vx;
q.vyFiltered = 0.75*q.vyFiltered+0.25*q.vy;
q.lastTheta = theta;
ax = (q.vx-q.lastVx)/dt;
ay = (q.vy-q.lastVy)/dt;
q.lastVx = q.vx; q.lastVy = q.vy;
q.lastX = x; q.lastY = y; q.lastT = t;
q.telemetry(end+1,:) = [t,x,y,q.vx,q.vy,ax,ay,theta,mode, ...
    double(loaded),double(contact),double(emergency),double(watchdog), ...
    fault,double(valid),double(scanning),double(complete),clearance, ...
    double(block.InputPort(28).Data), ...
    double(block.InputPort(14).Data), ...
    double(block.InputPort(15).Data), ...
    double(block.InputPort(16).Data)];
jt = 0; jh = 0;
if t >= q.nextLog
    fprintf('CICLO_CODESYS t=%.1f etapa=%d modo=%d x=%.2f y=%.2f linea=%.2f carga=%d contacto=%d perfil=%d scan=%d falla=%.0f\n', ...
        t,q.stage,mode,x,y,clearance,loaded,contact,valid,scanning,fault);
    registrar_progreso_mc(q,t,x,y,mode,loaded,fault);
    q.nextLog = t+5;
end
if (emergency || watchdog || fault~=0 || mode==6) && q.stage>0 && q.stage<13
    q.abort = sprintf('Falla t=%.2f etapa=%d emergency=%d watchdog=%d fault=%.0f', ...
        t,q.stage,emergency,watchdog,fault);
elseif t-q.entered>240
    q.abort = sprintf('Tiempo de etapa %d excedido en t=%.2f',q.stage,t);
end
if ~isempty(q.abort)
    grabar_video(fig,t);
    finalizar(fig,q,block);
    return
end
switch q.stage
    case 0 % Dar tiempo a restablecer el enlace y borrar el fallo retenido.
        if t>=0.5 && t<3.0 && t-q.lastReset>=0.8
            click(h.hmi.resetButton);
            q.lastReset = t;
        elseif t>=3.2 && ~emergency && ~watchdog && fault==0
            click(h.hmi.startButton);
            q = avanzar(q,1,t,x,y,loaded);
        end
    case 1
        if mode==3 && valid && ~scanning && t-q.entered>=0.5
            q.scannedProfile=double(block.InputPort(6).Data(:));
            q=avanzar(q,3,t,x,y,loaded);
        end
    case 3 % Aproximacion por fases del ensayo de referencia.
        errorX = q.dockX-x;
        switch q.approachPhase
            case 0
                if y>25.6
                    jh = -0.16;
                elseif abs(q.vyFiltered)<0.08
                    q.approachPhase=1; q.phaseEntered=t;
                end
            case 1
                if abs(errorX)>0.45
                    jt = 0.055*sign(errorX);
                elseif abs(q.vxFiltered)<0.08
                    q.approachPhase=2; q.phaseEntered=t;
                end
            case 2
                if t-q.phaseEntered>=3 && abs(q.vxFiltered)<0.08
                    if abs(errorX)>0.35
                        q.approachPhase=1; q.phaseEntered=t; q.settledSince=NaN;
                    elseif abs(theta)<0.020 && abs(q.omega)<0.020
                        if isnan(q.settledSince), q.settledSince=t; end
                        if t-q.settledSince>=2
                            q.approachCommitted=true; q.approachPhase=4;
                        end
                    else
                        q.settledSince=NaN;
                    end
                end
            case 4
                jh=-0.2;
        end
        if contact
            jh = 0;
            set(h.hmi.twistlockButton,'Value',1);
            click(h.hmi.twistlockButton);
            q = avanzar(q,4,t,x,y,loaded);
        end
    case 4
        jt = 0;
        if block.InputPort(5).Data>0.5
            set(h.hmi.slotEdit,'String',num2str(q.shipSlot));
            click(h.hmi.applySlot);
            q = avanzar(q,5,t,x,y,loaded);
        end
    case 5 % Izaje manual hasta superar el objetivo local de la envolvente.
        if isnan(q.loadedHandoffHoldAt)
            jh=0.2;
            if y>=alturaLocalParaAuto(block,x,loaded)+1.0
                jh=0; q.loadedHandoffHoldAt=t;
            end
        elseif t-q.loadedHandoffHoldAt>=2.0 && abs(q.vyFiltered)<0.03
            q.transitionToAutoY=y; q.solicitudAutomatico=t;
            set(h.hmi.modeButton,'Value',1);
            click(h.hmi.modeButton);
            click(h.hmi.autoStartButton);
            q = avanzar(q,6,t,x,y,loaded);
        end
    case 6
        if mode==4, q = avanzar(q,7,t,x,y,loaded); end
    case 7
        if mode==4 && ~q.requestedManualLoaded && ...
                abs(x-(-30+(q.shipSlot-0.5)*2.44))<0.5 && ...
                abs(q.vxFiltered)<0.25 && ...
                y<=double(block.InputPort(36).Data)+0.25
            set(h.hmi.modeButton,'Value',0);
            click(h.hmi.modeButton);
            q.requestedManualLoaded=true; q.solicitudManual=t;
        end
        if mode==3
            q.transitionToManualX = x;
            q = avanzar(q,8,t,x,y,loaded);
        end
    case 8 % Descenso final manual hasta apoyo en el barco.
        jh = -0.2;
        if contact
            jh = 0;
            set(h.hmi.twistlockButton,'Value',0);
            click(h.hmi.twistlockButton);
            q = avanzar(q,9,t,x,y,loaded);
        end
    case 9
        if ~loaded && block.InputPort(5).Data<0.5
            q.finalProfile = double(block.InputPort(6).Data(:));
            if strcmp(getenv('CODESYS_JOINT_STOP_AFTER_DELIVERY'),'1')
                click(h.hmi.stopButton);
                q = avanzar(q,14,t,x,y,loaded);
            else
                q = avanzar(q,10,t,x,y,loaded);
            end
        end
    case 14 % Terminar en el barco despues de descargar y detener la grua.
        if (mode==0 || mode==5) && abs(q.vxFiltered)<0.10 && ...
                abs(q.vyFiltered)<0.10 && ~loaded
            q.done=true;
            grabar_video(fig,t);
            finalizar(fig,q,block);
            return
        end
    case 10 % Retorno vacio: mismo criterio local de ingreso automatico.
        if isnan(q.emptyHandoffHoldAt)
            jh=0.2;
            if y>=alturaLocalParaAuto(block,x,loaded)+1.0
                jh=0; q.emptyHandoffHoldAt=t;
            end
        elseif t-q.emptyHandoffHoldAt>=2.0 && abs(q.vyFiltered)<0.03
            set(h.hmi.slotEdit,'String',num2str(q.dockSlot));
            click(h.hmi.applySlot);
            set(h.hmi.modeButton,'Value',1); click(h.hmi.modeButton);
            click(h.hmi.autoStartButton);
            q=avanzar(q,11,t,x,y,loaded);
        end
    case 11
        if mode==4 && ~loaded, q=avanzar(q,12,t,x,y,loaded); end
    case 12 % Finalizar el retorno sin descenso en el muelle.
        if mode==4 && ~q.requestedManualEmpty && ~loaded && ...
                abs(x-q.dockX)<0.25 && abs(q.vxFiltered)<0.25
            set(h.hmi.modeButton,'Value',0); click(h.hmi.modeButton);
            q.requestedManualEmpty=true;
        end
        if mode==3 && ~loaded && abs(x-q.dockX)<0.5 && ...
                abs(q.vxFiltered)<0.25 && abs(theta)<0.020
            click(h.hmi.stopButton);
            q = avanzar(q,13,t,x,y,loaded);
        end
    case 13
        if (mode==0 || mode==5) && abs(x-q.dockX)<0.35 && ...
                abs(q.vxFiltered)<0.10 && abs(theta)<0.020 && ~loaded
            q.done = true;
            grabar_video(fig,t);
            finalizar(fig,q,block);
            return
        end
end
s = getappdata(fig,'CraneHMIState');
s.keyboardTrolley = jt;
s.keyboardHoist = jh;
s.lastKeyEvent = now;
setappdata(fig,'CraneHMIState',s);
setappdata(fig,'CODESYSCycle',q);
grabar_video(fig,t);
end

function grabar_video(fig,t)
if isappdata(fig,'CODESYSJointVideoWriter') && ...
        t+1e-8>=getappdata(fig,'CODESYSJointVideoNext')
    drawnow;
    frame = getframe(fig);
    writeVideo(getappdata(fig,'CODESYSJointVideoWriter'),frame);
    setappdata(fig,'CODESYSJointVideoNext',t+0.50);
end
end

function q = avanzar(q,stage,t,x,y,loaded)
q.stage = stage;
q.entered = t;
q.events(end+1,:) = [stage,t,x,y,double(loaded)];
fprintf('CICLO_CODESYS_ETAPA=%d T=%.2f X=%.2f Y=%.2f CARGA=%d\n', ...
    stage,t,x,y,loaded);
end

function finalizar(fig,q,block)
setappdata(fig,'CODESYSCycle',q);
setappdata(0,'CODESYSCycleResult',q);
registrar_progreso_mc(q,q.lastT,q.lastX,q.lastY,NaN,NaN,NaN,true);
if q.done
    fprintf('CICLO_CODESYS_COMPLETO t=%.2f\n',double(block.CurrentTime));
else
    fprintf('CICLO_CODESYS_ABORT=%s\n',q.abort);
end
set_param(bdroot(getfullname(block.BlockHandle)),'SimulationCommand','stop');
end

function click(control)
callback = get(control,'Callback');
callback(control,[]);
end

function yLimit = alturaLocalParaAuto(block,x,loaded)
envelope = double(block.InputPort(42).Data(:));
surface = -20.0;
loadMin = x-1.22; loadMax=x+1.22;
for k=1:min(33,numel(envelope))
    slotMin=-30.0+double(k-1)*2.44;
    slotMax=slotMin+2.44;
    if slotMax>loadMin+1.0e-6 && slotMin<loadMax-1.0e-6
        surface=max(surface,envelope(k));
    end
end
base=surface+2.59+2.59*double(loaded);
rope=max(5.0,min(65.0,45.0-base));
khw=236.0e6/(2.0*rope+110.0);
stretch=65000.0*9.80665/(4.0*khw);
yLimit=base+stretch;
end



