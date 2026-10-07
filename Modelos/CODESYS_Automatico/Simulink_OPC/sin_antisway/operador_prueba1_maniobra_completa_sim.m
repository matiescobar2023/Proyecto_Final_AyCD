function operador_prueba1_maniobra_completa_sim(block,h,recordVideo)
%OPERADOR_PRUEBA1_MANIOBRA_COMPLETA_SIM Ciclo con retorno vacio automatico.
% Los botones usan sus callbacks reales. Los joysticks proporcionales se
% publican por el mismo estado/salidas HMI que usa el teclado del operador.
if nargin<3, recordVideo=true; end
fig=ancestor(h.hmi.panel,'figure'); t=block.CurrentTime;
if ~recordVideo, set(fig,'Visible','off'); end
if ~isappdata(fig,'CycleHMI')
    q=struct('stage',0,'entered',t,'nextLog',0,'lastT',t,'lastX',0, ...
        'lastY',25,'vx',0,'vy',0,'dockX',-26.34,'dockSlot',2,'shipSlot',22, ...
        'events',zeros(0,5),'manualRequests',zeros(0,5), ...
        'autoRequests',zeros(0,5), ...
        'initialProfile',double(block.InputPort(6).Data(:)), ...
        'approachCommitted',false,'approachPhase',0,'phaseEntered',t, ...
        'approachEvents',zeros(0,5),'settledSince',NaN,'lastTheta',0, ...
        'omega',0,'vxFiltered',0,'vyFiltered',0, ...
        'loadedHandoffHoldAt',NaN,'emptyHandoffHoldAt',NaN, ...
        'requestedManualLoaded',false,'requestedManualEmpty',false, ...
        'done',false,'abort','', ...
        'telemetry',zeros(0,107));
    setappdata(fig,'CycleHMI',q);
    setappdata(fig,'CycleCaptureEnabled',logical(recordVideo));
    folder=outputFolder(h);
    setappdata(fig,'CycleOutputFolder',folder);
    if recordVideo
        if ~isfolder(folder), mkdir(folder); end
        writer=VideoWriter(fullfile(folder,'maniobra_completa_retorno_automatico.mp4'),'MPEG-4');
        writer.FrameRate=25; writer.Quality=90; open(writer);
        setappdata(fig,'CycleVideoWriter',writer);
        setappdata(fig,'CycleVideoNext',0);
    end
end
q=getappdata(fig,'CycleHMI');
% Registro del operador independiente de la vida de la ventana de ensayo.
setappdata(groot,'CartAcmdOperatorSnapshot', ...
    struct('folder',getappdata(fig,'CycleOutputFolder'),'q',q,'t',t));
row=t;
for port=1:42, row=[row,double(block.InputPort(port).Data(:)')]; end %#ok<AGROW>
q.telemetry(end+1,:)=row;
if isappdata(fig,'CycleVideoWriter') && t+1e-8>=getappdata(fig,'CycleVideoNext')
    drawnow; frame=getframe(fig); writeVideo(getappdata(fig,'CycleVideoWriter'),frame);
    setappdata(fig,'CycleVideoNext',t+0.20); % 5x, todo el intervalo temporal.
end
x=double(block.InputPort(1).Data); y=double(block.InputPort(3).Data);
theta=double(block.InputPort(4).Data); mode=double(block.InputPort(10).Data);
loaded=block.InputPort(9).Data>0.5; contact=block.InputPort(11).Data>0.5;
valid=block.InputPort(37).Data>0.5; scan=block.InputPort(38).Data>0.5;
dt=max(t-q.lastT,0.04); q.vx=(x-q.lastX)/dt; q.vy=(y-q.lastY)/dt;
q.omega=(theta-q.lastTheta)/dt;
q.vxFiltered=0.75*q.vxFiltered+0.25*q.vx;
q.vyFiltered=0.75*q.vyFiltered+0.25*q.vy;
q.lastTheta=theta;
q.lastX=x; q.lastY=y; q.lastT=t;
jt=0; jh=0;
if t>=q.nextLog
    fprintf('CICLO t=%.2f etapa=%d modo=%d x=%.3f y=%.3f carga=%d contacto=%d perfil=%d\n', ...
        t,q.stage,mode,x,y,loaded,contact,valid);
    q.nextLog=t+10;
end
if block.InputPort(22).Data>0.5 || block.InputPort(39).Data>0.5 || mode==6
    q.abort=sprintf('Falla en t=%.2f, etapa=%d, codigo=%g',t,q.stage,block.InputPort(40).Data);
elseif (q.stage==13 && t-q.entered>20) || t-q.entered>220
    q.abort=sprintf('Tiempo de etapa %d excedido en t=%.2f',q.stage,t);
end
if ~isempty(q.abort)
    setappdata(fig,'CycleHMI',q); click(h.hmi.stopButton);
    fprintf('CICLO_ABORT=%s\n',q.abort);
    closeVideo(fig);
    set_param(bdroot(getfullname(block.BlockHandle)),'SimulationCommand','stop'); return;
end
switch q.stage
    case 0
        if t>=0.2, click(h.hmi.startButton); q=advance(q,1,t,x,y,loaded); end
    case 1
        if mode==3
            click(h.hmi.surveyButton); q=advance(q,2,t,x,y,loaded);
        end
    case 2
        if valid && ~scan && mode==3
            q.scannedProfile=double(block.InputPort(6).Data(:));
            snap(fig,'01_perfil_relevado'); q=advance(q,3,t,x,y,loaded);
        end
    case 3 % Aproximacion manual por fases, sin compensacion angular duplicada.
        jt=0; jh=0;
        errorX=q.dockX-x;
        switch q.approachPhase
            case 0 % Bajar vacio en vertical; perfil maximo relevado 18.85 m.
                if y>25.6
                    jh=-0.16;
                elseif abs(q.vyFiltered)<0.08
                    q=approachPhase(q,1,t,x,y,theta);
                end
            case 1 % Avance lento continuo para vencer la zona muerta.
                if abs(errorX)>0.45
                    jt=0.055*sign(errorX);
                elseif abs(q.vxFiltered)<0.08
                    q=approachPhase(q,2,t,x,y,theta);
                end
            case 2 % Reposo y evaluacion antes de iniciar microajustes.
                if t-q.phaseEntered>=3 && abs(q.vxFiltered)<0.08
                    if abs(errorX)>0.35
                        q=approachPhase(q,1,t,x,y,theta);
                    elseif abs(theta)<0.020 && abs(q.omega)<0.020
                        if isnan(q.settledSince), q.settledSince=t; end
                        if t-q.settledSince>=2
                            q.approachCommitted=true;
                            q=approachPhase(q,4,t,x,y,theta);
                        end
                    else
                        q.settledSince=NaN;
                    end
                end
            case 4 % Descenso final con carro sin orden manual.
                jh=-0.2;
        end
        if contact
            jh=0; set(h.hmi.twistlockButton,'Value',1); click(h.hmi.twistlockButton);
            q=advance(q,4,t,x,y,loaded);
        end
    case 4
        jt=0;
        if block.InputPort(5).Data>0.5
            set(h.hmi.slotEdit,'String',num2str(q.shipSlot)); click(h.hmi.applySlot);
            q=advance(q,5,t,x,y,loaded); snap(fig,'02_twistlocks_cerrados');
        end
    case 5 % Solicitar automatico al superar la seguridad local de partida.
        if isnan(q.loadedHandoffHoldAt)
            jh=0.2;
            if y>=alturaLocalParaAuto(block,x,loaded)+1.0
                jh=0; q.loadedHandoffHoldAt=t;
            end
        elseif t-q.loadedHandoffHoldAt>=2.0 && abs(q.vyFiltered)<0.03
            set(h.hmi.modeButton,'Value',1); click(h.hmi.modeButton);
            click(h.hmi.autoStartButton); q=advance(q,6,t,x,y,loaded);
            q.autoRequests(end+1,:)=[t x y alturaLocalParaAuto(block,x,loaded) double(loaded)];
        end
    case 6
        if mode==4, q=advance(q,7,t,x,y,loaded); end
    case 7
        if mode==4 && ~q.requestedManualLoaded && ...
                abs(x-(-30+(q.shipSlot-0.5)*2.44))<0.5 && ...
                abs(q.vxFiltered)<0.25 && ...
                y<=double(block.InputPort(36).Data)+0.25
            set(h.hmi.modeButton,'Value',0); click(h.hmi.modeButton);
            q.requestedManualLoaded=true;
            q.manualRequests(end+1,:)=[t x y double(block.InputPort(36).Data) double(loaded)];
        end
        if mode==3
            q=advance(q,8,t,x,y,loaded);
        end
    case 8 % Descenso manual controlado, retencion X del supervisor.
        jh=-0.2;
        if contact
            jh=0; set(h.hmi.twistlockButton,'Value',0); click(h.hmi.twistlockButton);
            q=advance(q,9,t,x,y,loaded);
        end
    case 9
        if ~loaded
            snap(fig,'03_entrega_en_barco'); q=advance(q,10,t,x,y,loaded);
        end
    case 10 % Retorno: mismo criterio local, ahora con spreader vacio.
        if isnan(q.emptyHandoffHoldAt)
            jh=0.2;
            if y>=alturaLocalParaAuto(block,x,loaded)+1.0
                jh=0; q.emptyHandoffHoldAt=t;
            end
        elseif t-q.emptyHandoffHoldAt>=2.0 && abs(q.vyFiltered)<0.03
            set(h.hmi.slotEdit,'String',num2str(q.dockSlot)); click(h.hmi.applySlot);
            set(h.hmi.modeButton,'Value',1); click(h.hmi.modeButton);
            click(h.hmi.autoStartButton);
            q=advance(q,11,t,x,y,loaded);
            q.autoRequests(end+1,:)=[t x y alturaLocalParaAuto(block,x,loaded) double(loaded)];
        end
    case 11 % Esperar la entrada efectiva a automatico.
        if mode==4 && ~loaded, q=advance(q,12,t,x,y,loaded); end
    case 12 % Retorno vacio: terminar el traslado en X sin descenso final.
        if mode==4 && ~q.requestedManualEmpty && ~loaded && ...
                abs(x-q.dockX)<0.25 && abs(q.vxFiltered)<0.25
            set(h.hmi.modeButton,'Value',0); click(h.hmi.modeButton);
            q.requestedManualEmpty=true;
            q.manualRequests(end+1,:)=[t x y double(block.InputPort(36).Data) double(loaded)];
        end
        if mode==3 && ~loaded && abs(x-q.dockX)<0.5 && ...
                abs(q.vxFiltered)<0.25 && abs(theta)<0.020
            click(h.hmi.stopButton);
            q=advance(q,13,t,x,y,loaded);
        end
    case 13 % Confirmar frenado, posicion final y reposo.
        finalMode=(mode==0 || mode==5);
        if getSimulinkBlockHandle([bdroot(getfullname(block.BlockHandle)) '/Subsystem/Antisway comun'])>0
            finalMode=mode==0; % Comprobar tambien el fin efectivo de la parada.
        end
        if t-q.entered>1 && finalMode && ...
                abs(x-q.dockX)<0.35 && ...
                abs(q.vxFiltered)<0.10 && abs(theta)<0.020
            q.done=true; q.finalProfile=double(block.InputPort(6).Data(:));
            snap(fig,'04_retorno_automatico_vacio_al_muelle');
            setappdata(fig,'CycleHMI',q);
            fprintf('CICLO_COMPLETO t=%.2f x=%.3f y=%.3f carga=%d\n',t,x,y,loaded);
            closeVideo(fig);
            set_param(bdroot(getfullname(block.BlockHandle)),'SimulationCommand','stop'); return;
        end
end
s=getappdata(fig,'CraneHMIState');
s.keyboardTrolley=jt; s.keyboardHoist=jh; s.lastKeyEvent=now;
setappdata(fig,'CraneHMIState',s); setappdata(fig,'CycleHMI',q);
end

function q=advance(q,stage,t,x,y,loaded)
q.stage=stage; q.entered=t; q.events(end+1,:)=[stage,t,x,y,double(loaded)];
fprintf('ETAPA=%d T=%.3f X=%.3f Y=%.3f CARGA=%d\n',stage,t,x,y,loaded);
end
function q=approachPhase(q,phase,t,x,y,theta)
q.approachPhase=phase; q.phaseEntered=t; q.settledSince=NaN;
q.approachEvents(end+1,:)=[phase,t,x,y,theta];
fprintf('APROX_FASE=%d T=%.3f X=%.3f Y=%.3f THETA=%.4f\n',phase,t,x,y,theta);
end
function click(control)
callback=get(control,'Callback'); callback(control,[]);
end
function v=clip(v,lo,hi)
v=max(lo,min(hi,v));
end
function yLimit=alturaLocalParaAuto(block,x,loaded)
% Misma envolvente de tres slots del supervisor, expresada como altura de
% izaje. Se usa la masa suspendida maxima para no anticipar la solicitud.
envelope=double(block.InputPort(42).Data(:));
surface=-20.0;
loadMin=x-1.22; loadMax=x+1.22;
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
function snap(fig,name)
if strcmp(get(fig,'Visible'),'off') || ...
        (isappdata(fig,'CycleCaptureEnabled') && ~getappdata(fig,'CycleCaptureEnabled'))
    return;
end
folder=getappdata(fig,'CycleOutputFolder');
if ~isfolder(folder), mkdir(folder); end
drawnow; frame=getframe(fig); imwrite(frame.cdata,fullfile(folder,[name '.png']));
end
function folder=outputFolder(h)
folder=fullfile(fileparts(mfilename('fullpath')),'resultados');
if isfield(h,'captureFolder') && ~isempty(h.captureFolder)
    folder=h.captureFolder;
end
end
function closeVideo(fig)
if isappdata(fig,'CycleVideoWriter')
    close(getappdata(fig,'CycleVideoWriter')); rmappdata(fig,'CycleVideoWriter');
end
end
