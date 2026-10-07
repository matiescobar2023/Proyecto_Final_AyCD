function codesys_opcua_conjunto_sfun(block)
% Un solo intercambio OPC UA para supervisor y seguridad cada 20 ms.
% Entradas 1:33 y salidas 1:38 conservan los puertos del supervisor.
% Entradas 34:41 corresponden a los puertos 2:9 del bloque de seguridad;
% su puerto 1 (pulso_WD) no se transmite por OPC UA.
% Salidas 39:43 conservan los cinco puertos del bloque de seguridad.
setup(block);
end

function setup(block)
block.NumDialogPrms = 0;
block.NumInputPorts = 41;
block.NumOutputPorts = 44;
block.SetPreCompPortInfoToDefaults;
for k = 1:41
    block.InputPort(k).Dimensions = 1;
    block.InputPort(k).DatatypeID = -1;
    % Los permisos 13:15 son lecturas de retorno del PLC; no se escriben ni
    % se usan para calcular salidas. Declararlos sin feedthrough evita un
    % lazo algebraico espurio al reunir ambos clientes en un solo bloque.
    block.InputPort(k).DirectFeedthrough = ~ismember(k,13:15);
end
for k = 1:44
    block.OutputPort(k).Dimensions = 1;
    block.OutputPort(k).DatatypeID = 0;
end
logicalSupervisorOutputs = [1:11 23:28 34:36];
for k = [logicalSupervisorOutputs 39:43]
    block.OutputPort(k).DatatypeID = 8;
end
block.OutputPort(29).Dimensions = 33;
block.OutputPort(44).Dimensions = 33;
block.SampleTimes = [0.02 0];
block.SimStateCompliance = 'DefaultSimState';
block.SetAccelRunOnTLC(false);
block.RegBlockMethod('Start',@startBlock);
block.RegBlockMethod('Outputs',@outputsBlock);
block.RegBlockMethod('Terminate',@terminateBlock);
end

function startBlock(~)
opcContext('reset');
setappdata(0,'CODESYSOPCUATimingEvents',zeros(0,4));
setappdata(0,'CODESYSOPCUASafetyEvents',zeros(0,8));
end

function outputsBlock(block)
setSafeOutputs(block);
[writeNames,allReadNames,writePorts] = signalNames();
ctx = opcContext('get');
if isempty(ctx) || ~isfield(ctx,'ready') || ~ctx.ready
    ctx = connectContext(writeNames,allReadNames,block.CurrentTime,ctx);
end
if isempty(ctx) || ~ctx.ready
    opcContext('set',ctx);
    return
end

wallStart = now;
gapSeconds = NaN;
if isfield(ctx,'lastReplyWall') && isfinite(ctx.lastReplyWall)
    gapSeconds = (wallStart-ctx.lastReplyWall)*86400;
end
try
    values = cell(1,numel(writePorts)+10);
    for k = 1:numel(writePorts)
        value = block.InputPort(writePorts(k)).Data;
        if islogical(value)
            values{k} = logical(value);
        else
            values{k} = double(value);
        end
    end
    ctx.heartbeat = ~ctx.heartbeat;
    values{numel(writePorts)+9} = true; % Modo explicito del banco simulado.
    values{numel(writePorts)+10} = ctx.heartbeat;
    for k = 1:8
        value = block.InputPort(33+k).Data;
        if k == 6 % TiempoMaxWD, correspondiente al puerto 7 de seguridad.
            values{numel(writePorts)+k} = double(value);
        else
            values{numel(writePorts)+k} = logical(value);
        end
    end
    rawRead = jsondecode(char(ctx.client.exchange(jsonencode(values))));
    if ~iscell(rawRead), rawRead = num2cell(rawRead); end
    readValues = rawRead(ctx.readMap);
    for k = 1:38
        if ismember(k,[1:11 23:28 34:36])
            block.OutputPort(k).Data = logical(readValues{k});
        else
            block.OutputPort(k).Data = double(readValues{k});
        end
    end
    for k = 1:5
        block.OutputPort(38+k).Data = logical(readValues{44+k});
    end
    block.OutputPort(44).Data = double(readValues{50});
    if double(readValues{20}) ~= 0
        events = getappdata(0,'CODESYSOPCUASafetyEvents');
        events(end+1,:) = [double(block.CurrentTime), ...
            double(readValues{20}),double(readValues{39}), ...
            double(readValues{40}),double(readValues{41}), ...
            double(readValues{42}),double(readValues{43}), ...
            double(readValues{44})];
        setappdata(0,'CODESYSOPCUASafetyEvents',events);
    end
    wallEnd = now;
    recordTimingEvent(block.CurrentTime,gapSeconds, ...
        (wallEnd-wallStart)*86400,1);
    ctx.lastReplyWall = wallEnd;
catch exception
    recordTimingEvent(block.CurrentTime,gapSeconds, ...
        (now-wallStart)*86400,0);
    ctx = markDisconnected(ctx,block.CurrentTime,exception);
end
opcContext('set',ctx);
end

function [writeNames,allReadNames,writePorts] = signalNames()
supervisorInputs = {'cmdStart','cmdStop','modeAutoReq','cmdAutoStart', ...
    'cmdReset','swayControlSelect','configValid','twistlockButton', ...
    'contact4','twistlocksClosedFb','normalLimitXMin','normalLimitXMax', ...
    'safetyPermitGlobal','safetyPermitTrolley','safetyPermitHoist', ...
    'joyTrolley','joyHoist','xTrolley','omegaTrolley','yHoist','vHoist', ...
    'ropeTension','torqueTrolleyRaw','torqueHoistRaw','autoTargetX', ...
    'manualToAutoHeight','finalApproachDistance','spreaderSwayAngle', ...
    'spreaderSwayRate','hmiScanRequestRaw','lidarX','lidarY','scanSpeed'};
supervisorOutputs = {'enableTrolleyReg','enableHoistReg', ...
    'brakeTrolleyOpenCmd','brakeHoistOpenCmd', ...
    'emergencyBrakeHoistOpenCmd','twistlockCloseCmd', ...
    'twistlockOpenCmd','swayControlEnable','loadedState', ...
    'overloadDetected','watchdogToggle','xRef','vxRef','axRef','yRef', ...
    'vyRef','ayRef','modeCode','alarmCode','faultCode','aTrolley', ...
    'aHoist','trackingFault','torqueProvenTrolley', ...
    'torqueProvenHoist','profileScanComplete','profileValid', ...
    'scanActive','scannedObstacleProfile','profileMaxY', ...
    'automaticTargetY','clearanceLineY','estimatedContainerMass', ...
    'massEstimateValid','normalLimitYMin','normalLimitYMax', ...
    'manualTrolleyRef','manualHoistRef','opcCommFault', ...
    'BOTON_EMERGENCIA','PARADA_EMERGENCIA_WD','safetyPermitGlobal', ...
    'safetyPermitTrolley','safetyPermitHoist'};
safetyInputs = {'REINICIO','LST_MINU','LST_MAXU','LSH_MINU', ...
    'LSH_MAXU','TiempoMaxWD','BOTON_EMERGENCIA','VH_MAX'};
safetyOutputs = {'BRK_h','BRK_hE','BRK_t','EMERGENCIA', ...
    'PARADA_EMERGENCIA_WD'};
writePorts = [1:12 16:33];
writeNames = [supervisorInputs(writePorts) safetyInputs {'opcModoBancoSimulado','opcHeartbeatSimulink'}];
allReadNames = [supervisorOutputs safetyOutputs {'safetyEnvelopeProfile','opcHeartbeatPLC'}];
end

function ctx = connectContext(writeNames,allReadNames,currentTime,ctx)
if ~isempty(ctx) && isfield(ctx,'nextRetry') && currentTime<ctx.nextRetry
    return
end
ctx = struct('ready',false,'nextRetry',currentTime+1.0, ...
    'heartbeat',false,'client',[],'lastWarning',-inf, ...
    'lastReplyWall',NaN,'readMap',[]);
try
    [uniqueReadNames,~,ctx.readMap] = unique(allReadNames,'stable');
    ctx.client = codesys_opcua_bridge(writeNames,uniqueReadNames);
    ctx.ready = true;
catch exception
    ctx = markDisconnected(ctx,currentTime,exception);
end
end

function recordTimingEvent(simTime,gapSeconds,exchangeSeconds,success)
if (isfinite(gapSeconds) && gapSeconds>0.8) || ...
        exchangeSeconds>0.8 || ~success
    events = getappdata(0,'CODESYSOPCUATimingEvents');
    events(end+1,:) = [simTime,gapSeconds,exchangeSeconds,success];
    setappdata(0,'CODESYSOPCUATimingEvents',events);
end
end

function ctx = markDisconnected(ctx,currentTime,exception)
if isempty(ctx), ctx = struct; end
if isfield(ctx,'client') && ~isempty(ctx.client)
    try, ctx.client.close(); catch, end
end
ctx.ready = false;
ctx.client = [];
ctx.nextRetry = currentTime+1.0;
if ~isfield(ctx,'lastWarning') || currentTime-ctx.lastWarning>=5.0
    warning('CODESYS:OPCUA:Conjunto', ...
        'Enlace OPC UA no disponible: %s',exception.message);
    ctx.lastWarning = currentTime;
end
end

function setSafeOutputs(block)
for k = 1:38
    if ismember(k,[1:11 23:28 34:36])
        block.OutputPort(k).Data = false;
    elseif k == 29
        block.OutputPort(k).Data = zeros(33,1);
    else
        block.OutputPort(k).Data = 0.0;
    end
end
block.OutputPort(39).Data = false;
block.OutputPort(40).Data = false;
block.OutputPort(41).Data = false;
block.OutputPort(42).Data = true;
block.OutputPort(43).Data = true;
block.OutputPort(44).Data = zeros(33,1);
end

function terminateBlock(~)
ctx = opcContext('get');
if ~isempty(ctx) && isfield(ctx,'client') && ~isempty(ctx.client)
    try, ctx.client.close(); catch, end
end
opcContext('reset');
end

function out = opcContext(action,value)
persistent stored
if nargin<2, value=[]; end
switch action
    case 'get', out=stored;
    case 'set', stored=value; out=stored;
    otherwise, stored=[]; out=[];
end
end

