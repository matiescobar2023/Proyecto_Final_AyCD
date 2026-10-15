function [xRef, vxRef, axRef, yRef, vyRef, ayRef, plan] = generador_ejemplo_informe( ...
    enable, reset, ...
    xPos, xVel, xAcc, ...
    yPos, yVel, yAcc, ...
    xTarget, yTarget, ...
    obstacleProfile, ...
    suspendedMassKg, loaded, swayAngle, swayRate, Ts)
%#codegen
% CRANETRAJECTORYGENERATOR
% Generador coordinado de referencias de posicion para trolley e izaje.
%
% Salidas:
%   xRef  [m]     : referencia de posicion del trolley.
%   vxRef [m/s]   : referencia de velocidad del trolley.
%   axRef [m/s^2] : referencia de aceleracion del trolley.
%   yRef  [m]     : referencia de posicion del izaje.
%   vyRef [m/s]   : referencia de velocidad del izaje.
%   ayRef [m/s^2] : referencia de aceleracion del izaje.
%
% Convencion de coordenadas de la guia:
%   x positivo hacia el barco.
%   y positivo hacia arriba, con Yt0 = 45 m.
%
% Uso:
%   - Llamar periodicamente con Ts constante.
%   - Aplicar reset=true durante al menos una muestra para inicializar.
%   - Un flanco ascendente de enable genera una trayectoria nueva.
%   - Un cambio de objetivo mientras enable=true provoca replanificacion
%     suave desde el estado medido actual.
%
% Obstaculos:
%   obsXMin, obsXMax: intervalo horizontal ocupado por los obstaculos.
%   obsYMax: maxima cota superior dentro de ese intervalo.
%   Si obsXMax <= obsXMin, se considera que no hay obstaculo intermedio.
%
% suspendedMassKg es la masa total suspendida:
% spreader + headblock + container, entre 15000 y 65000 kg normalmente.

% -------------------------------------------------------------------------
% Parametros de la guia y parametros de diseno
% -------------------------------------------------------------------------
X_MIN = -30.0;
X_MAX =  50.0;
Y_MIN = -20.0;
Y_MAX =  40.0;

VX_MAX = 2.5;       % maxima velocidad de diseno verificable con la planta
AX_MAX = 0.3;       % rampa compatible con el seguimiento del accionamiento
JX_MAX = 0.5;       % limite de jerk para el traslado productivo

AY_MAX = 0.25;       % conserva tension durante el descenso cargado
JY_MAX = 0.10;       % evita transitorios de izaje que aflojen el cable       % Parametro de diseno [m/s^3]
% La velocidad cargada se calcula con la masa suspendida.
VY_MAX_EMPTY  = 3.00;

YT0 = 45.0;
HC = 2.59;
WC = 2.44;
G = 9.80665;
KHWU = 236.0e6;
LH0 = 110.0;

VERTICAL_MARGIN = 2.59;       % Parametro de diseno [m]
PATH_SWAY_LIMIT = 5.0*pi/180.0;
TARGET_CHANGE_TOL = 1.0e-6;
MAX_PLAN_TIME = 300.0;  % permite traslados largos a velocidad conservadora

% -------------------------------------------------------------------------
% Memoria interna
% -------------------------------------------------------------------------
persistent initialized prevEnable active validPlan trajectoryTime
persistent xCoef xDuration
persistent yUpCoef yUpDuration
persistent yDownCoef yDownDuration yDownStart
persistent savedXTarget savedYTarget

if isempty(initialized)
    initialized = true;
    prevEnable = false;
    active = false;
    validPlan = false;
    trajectoryTime = 0.0;

    xCoef = zeros(1,6);
    xDuration = 0.0;
    yUpCoef = zeros(1,6);
    yUpDuration = 0.0;
    yDownCoef = zeros(1,6);
    yDownDuration = 0.0;
    yDownStart = 0.0;

    % Inicializacion constante para compatibilidad con MATLAB/PLC Coder.
    savedXTarget = 0.0;
    savedYTarget = 0.0;
end

% Sanitizacion minima de entradas
if Ts <= 0.0
    TsUse = 0.001;
else
    TsUse = Ts;
end

xGoal = clampValue(xTarget, X_MIN, X_MAX);
yGoal = clampValue(yTarget, Y_MIN, Y_MAX);

if reset
    prevEnable = false;
    active = false;
    validPlan = false;
    trajectoryTime = 0.0;
    savedXTarget = xGoal;
    savedYTarget = yGoal;
    xRef = clampValue(xPos, X_MIN, X_MAX);
    vxRef = clampValue(xVel, -VX_MAX, VX_MAX);
    axRef = clampValue(xAcc, -AX_MAX, AX_MAX);
    yRef = clampValue(yPos, Y_MIN, Y_MAX);
    if loaded
        vyLimitReset = hoistSpeedLimit(suspendedMassKg,loaded);
    else
        vyLimitReset = VY_MAX_EMPTY;
    end
    vyRef = clampValue(yVel, -vyLimitReset, vyLimitReset);
    ayRef = clampValue(yAcc, -AY_MAX, AY_MAX);
    return;
end

targetChanged = abs(xGoal-savedXTarget) > TARGET_CHANGE_TOL || ...
                abs(yGoal-savedYTarget) > TARGET_CHANGE_TOL;
startRequest = enable && (~prevEnable || targetChanged);

if ~enable
    active = false;
    validPlan = false;
    trajectoryTime = 0.0;
    prevEnable = false;
    xRef = clampValue(xPos, X_MIN, X_MAX);
    vxRef = clampValue(xVel, -VX_MAX, VX_MAX);
    axRef = clampValue(xAcc, -AX_MAX, AX_MAX);
    yRef = clampValue(yPos, Y_MIN, Y_MAX);
    if loaded
        vyLimitDisabled = hoistSpeedLimit(suspendedMassKg,loaded);
    else
        vyLimitDisabled = VY_MAX_EMPTY;
    end
    vyRef = clampValue(yVel, -vyLimitDisabled, vyLimitDisabled);
    ayRef = clampValue(yAcc, -AY_MAX, AY_MAX);
    return;
end

% -------------------------------------------------------------------------
% Planificacion en el flanco de enable o ante cambio de objetivo
% -------------------------------------------------------------------------
if startRequest
    savedXTarget = xGoal;
    savedYTarget = yGoal;
    trajectoryTime = 0.0;
    active = true;

    x0 = clampValue(xPos, X_MIN, X_MAX);
    y0 = clampValue(yPos, Y_MIN, Y_MAX);
    vx0 = clampValue(xVel, -VX_MAX, VX_MAX);
    ax0 = clampValue(xAcc, -AX_MAX, AX_MAX);
    ay0 = clampValue(yAcc, -AY_MAX, AY_MAX);

    massUse = clampValue(suspendedMassKg, 15000.0, 65000.0);
    if loaded
        containerHeight = HC;
        vyMax = hoistSpeedLimit(suspendedMassKg,loaded);
    else
        containerHeight = 0.0;
        vyMax = VY_MAX_EMPTY;
    end

    vy0 = clampValue(yVel, -vyMax, vyMax);
    obsXMin=min(x0,xGoal);
    obsXMax=max(x0,xGoal);
    obsYMax=maximumProfileBetween(obstacleProfile,obsXMin,obsXMax);
    hasObstacle=abs(xGoal-x0)>1.0e-6;

    % Altura de izaje necesaria. El estiramiento se obtiene de las
    % ecuaciones 4, 5 y 5.a de la guia en equilibrio cuasiestatico.
    if hasObstacle
        yRequired0 = obsYMax + containerHeight + VERTICAL_MARGIN;
        lhEstimate = clampValue(YT0-yRequired0, 5.0, 65.0);
        khw = KHWU/(2.0*lhEstimate + LH0);
        cableStretch = massUse*G/(4.0*khw);
        yRequired = yRequired0 + cableStretch;
        yClear = max(max(y0,yGoal),yRequired);
        % Se conserva la altura alta de cruce del ciclo original.
        yClear = max(yClear,max(obstacleProfile)+5.18);
    else
        cableStretch = 0.0;
        yRequired = max(y0,yGoal);
        yClear = yRequired;
    end

    % Si el despeje requerido supera el limite mecanico no se inicia.
    validPlan = yClear <= Y_MAX + 1.0e-9;
    yClear = clampValue(yClear, Y_MIN, Y_MAX);

    % Plan vertical ascendente.
    [yUpCoef,yUpDuration,okYUp] = makeMinimumTimeQuintic( ...
        y0,vy0,ay0,yClear,0.0,0.0,vyMax,AY_MAX,JY_MAX,TsUse,MAX_PLAN_TIME);
    validPlan = validPlan && okYUp;

    % Plan horizontal inicialmente minimo.
    [xCoef,xDuration,okX] = makeCruiseProfile( ...
        x0,xGoal,VX_MAX,AX_MAX,JX_MAX,MAX_PLAN_TIME);
    validPlan = validPlan && okX;

    if validPlan && hasObstacle && xDuration > 0.0
        % Se expande horizontalmente la zona por el ancho de la carga y
        % por el sway permitido durante la transferencia.
        minHoistY = min(min(y0,yGoal),yClear);
        maxRopeLength = clampValue(YT0-minHoistY,5.0,65.0);
        collisionMargin = 0.5*WC + VERTICAL_MARGIN;
        expandedObsMin = obsXMin-collisionMargin;
        expandedObsMax = obsXMax+collisionMargin;

        % Si el trolley alcanzaria el obstaculo antes de lograr despeje,
        % se aumenta solamente la duracion horizontal. Ambos ejes siguen
        % arrancando en t=0, por lo que no hay salto en la referencia.
        safe = trajectoryClearsObstacle( ...
            xCoef,xDuration,yUpCoef,yUpDuration,yClear, ...
            expandedObsMin,expandedObsMax,obstacleProfile, ...
            containerHeight,cableStretch,VERTICAL_MARGIN);

        scaleIterations = 0;
        while ~safe && xDuration < MAX_PLAN_TIME && scaleIterations < 240
            [xCoef,xDuration] = stretchCruiseProfile(xCoef,1.025,MAX_PLAN_TIME);

            safe = trajectoryClearsObstacle( ...
                xCoef,xDuration,yUpCoef,yUpDuration,yClear, ...
                expandedObsMin,expandedObsMax,obstacleProfile, ...
                containerHeight,cableStretch,VERTICAL_MARGIN);
            scaleIterations = scaleIterations+1;
        end

        validPlan = validPlan && safe;

        % El descenso comienza en cuanto toda la envolvente horizontal de
        % la carga ha salido de la zona de obstaculos.
        if xGoal >= x0
            exitPosition = expandedObsMax;
            targetBeyondObstacle = xGoal >= exitPosition;
        else
            exitPosition = expandedObsMin;
            targetBeyondObstacle = xGoal <= exitPosition;
        end

        if targetBeyondObstacle
            yDownStart = findCrossingTime( ...
                xCoef,xDuration,exitPosition,xGoal>=x0);
        else
            yDownStart = xDuration;
        end
    else
        yDownStart = xDuration;
    end

    % Si no hay obstaculo, se coordina el descenso para terminar junto con
    % el trolley, comenzando desde el estado vertical previsto.
    if ~hasObstacle
        yDownStart = min(xDuration,yUpDuration);
    end

    % Estado vertical exacto al comenzar el descenso.
    if yDownStart < yUpDuration
        [yDown0,vyDown0,ayDown0] = evaluateQuintic( ...
            yUpCoef,yDownStart,yUpDuration);
    else
        yDown0 = yClear;
        vyDown0 = 0.0;
        ayDown0 = 0.0;
    end

    [yDownCoef,yDownDuration,okYDown] = makeMinimumTimeQuintic( ...
        yDown0,vyDown0,ayDown0,yGoal,0.0,0.0, ...
        vyMax,AY_MAX,JY_MAX,TsUse,MAX_PLAN_TIME);
    validPlan = validPlan && okYDown;

    if ~validPlan
        active = false;
    end
end

% -------------------------------------------------------------------------
% Evaluacion de la trayectoria
% -------------------------------------------------------------------------
if active && validPlan
    [xRef,vxRef,axRef] = evaluateCruiseProfile( ...
        xCoef,trajectoryTime,xDuration);

    if trajectoryTime < yDownStart
        [yRef,vyRef,ayRef] = evaluateQuintic( ...
            yUpCoef,trajectoryTime,yUpDuration);
    else
        [yRef,vyRef,ayRef] = evaluateQuintic( ...
            yDownCoef,trajectoryTime-yDownStart,yDownDuration);
    end

    totalDuration = max(xDuration,yDownStart+yDownDuration);
    if trajectoryTime >= totalDuration
        xRef = xGoal;
        vxRef = 0.0;
        axRef = 0.0;
        yRef = yGoal;
        vyRef = 0.0;
        ayRef = 0.0;
        % Mantener el plan activo y el reloj saturado para conservar las
        % referencias finales hasta reset, disable o replanificacion.
        % No volver a las posiciones medidas al terminar la maniobra.
        trajectoryTime = totalDuration;
    else
        finalDescentAtTarget=yDownStart>=xDuration-1.0e-9;
        readyForFinalDescent=abs(xPos-xGoal)<=0.08 && abs(xVel)<=0.06 && ...
            abs(swayAngle)<=0.0050 && abs(swayRate)<=0.0120;
        if finalDescentAtTarget && trajectoryTime>=yDownStart && ~readyForFinalDescent
            trajectoryTime=yDownStart;
        else
            trajectoryTime=trajectoryTime+TsUse;
        end
    end
else
    % Comportamiento seguro cuando el plan es inviable: mantener la
    % posicion medida y no generar movimiento automatico.
    xRef = clampValue(xPos,X_MIN,X_MAX);
    vxRef = clampValue(xVel,-VX_MAX,VX_MAX);
    axRef = clampValue(xAcc,-AX_MAX,AX_MAX);
    yRef = clampValue(yPos,Y_MIN,Y_MAX);
    if loaded
        vyLimitInvalid = hoistSpeedLimit(suspendedMassKg,loaded);
    else
        vyLimitInvalid = VY_MAX_EMPTY;
    end
    vyRef = clampValue(yVel,-vyLimitInvalid,vyLimitInvalid);
    ayRef = clampValue(yAcc,-AY_MAX,AY_MAX);
end

xRef = clampValue(xRef,X_MIN,X_MAX);
vxRef = clampValue(vxRef,-VX_MAX,VX_MAX);
axRef = clampValue(axRef,-AX_MAX,AX_MAX);
yRef = clampValue(yRef,Y_MIN,Y_MAX);
if loaded
    vyLimitOutput = hoistSpeedLimit(suspendedMassKg,loaded);
else
    vyLimitOutput = VY_MAX_EMPTY;
end
vyRef = clampValue(vyRef,-vyLimitOutput,vyLimitOutput);
ayRef = clampValue(ayRef,-AY_MAX,AY_MAX);
prevEnable = enable;
plan=struct('xCoef',xCoef,'xDuration',xDuration,'yUpCoef',yUpCoef,'yUpDuration',yUpDuration,'yDownCoef',yDownCoef,'yDownDuration',yDownDuration,'yDownStart',yDownStart,'validPlan',validPlan,'cableStretch',cableStretch,'yClear',yClear,'vyMax',vyMax);
end

% =========================================================================
% Funciones auxiliares compatibles con generacion de codigo
% =========================================================================

function maximumY = maximumProfileBetween(profile,xStart,xEnd)
xMin=-30.0; slotWidth=2.44; halfWidth=1.22;
pathMin=min(xStart,xEnd)-halfWidth;
pathMax=max(xStart,xEnd)+halfWidth;
maximumY=-20.0;
for k=1:33
    slotX=xMin+double(k-1)*slotWidth;
    if slotX+halfWidth>=pathMin && slotX-halfWidth<=pathMax
        maximumY=max(maximumY,profile(k));
    end
end
end

function value = clampValue(value,lowerLimit,upperLimit)
value = min(upperLimit,max(lowerLimit,value));
end

function [profile,duration,ok] = makeCruiseProfile( ...
    xStart,xGoal,vMax,aMax,jMax,maxTime)
distance=abs(xGoal-xStart);
if distance<1.0e-10
    profile=[xGoal,xGoal,0.0,0.0,0.0,0.0];
    duration=0.0; ok=true; return;
end
direction=sign(xGoal-xStart);
rampA=pi*vMax/(2.0*max(aMax,1.0e-6));
rampJ=pi*sqrt(vMax/(2.0*max(jMax,1.0e-6)));
rampDuration=max(0.25,max(rampA,rampJ));
if distance>=vMax*rampDuration
    cruiseVelocity=vMax;
    cruiseDuration=distance/cruiseVelocity-rampDuration;
else
    cruiseVelocity=distance/rampDuration;
    cruiseDuration=0.0;
end
duration=2.0*rampDuration+cruiseDuration;
profile=[xStart,xGoal,direction,cruiseVelocity,rampDuration,cruiseDuration];
ok=duration<=maxTime;
end

function [profile,duration] = stretchCruiseProfile(profile,scale,maxTime)
oldDuration=2.0*profile(5)+profile(6);
newDuration=min(maxTime,scale*oldDuration);
actualScale=max(1.0,newDuration/max(oldDuration,1.0e-9));
profile(4)=profile(4)/actualScale;
profile(5)=profile(5)*actualScale;
profile(6)=profile(6)*actualScale;
duration=2.0*profile(5)+profile(6);
end

function [position,velocity,acceleration] = evaluateCruiseProfile(profile,time,duration)
xStart=profile(1); xGoal=profile(2); direction=profile(3);
vCruise=profile(4); rampDuration=profile(5);
cruiseDuration=profile(6);
if duration<=0.0 || direction==0.0
    position=xGoal; velocity=0.0; acceleration=0.0; return;
end
t=min(duration,max(0.0,time));
if t<rampDuration
    angle=pi*t/rampDuration;
    travelled=0.5*vCruise*(t-rampDuration*sin(angle)/pi);
    speed=0.5*vCruise*(1.0-cos(angle));
    accel=0.5*vCruise*pi*sin(angle)/rampDuration;
elseif t<rampDuration+cruiseDuration
    travelled=0.5*vCruise*rampDuration+vCruise*(t-rampDuration);
    speed=vCruise; accel=0.0;
elseif t<duration
    tau=t-rampDuration-cruiseDuration;
    angle=pi*tau/rampDuration;
    travelled=0.5*vCruise*rampDuration+vCruise*cruiseDuration+...
        0.5*vCruise*(tau+rampDuration*sin(angle)/pi);
    speed=0.5*vCruise*(1.0+cos(angle));
    accel=-0.5*vCruise*pi*sin(angle)/rampDuration;
else
    position=xGoal; velocity=0.0; acceleration=0.0; return;
end
position=xStart+direction*travelled;
velocity=direction*speed; acceleration=direction*accel;
end

function [coef,duration,ok] = makeMinimumTimeQuintic( ...
    p0,v0,a0,pf,vf,af,vMax,aMax,jMax,Ts,maxTime)

if abs(pf-p0) < 1.0e-10 && abs(v0-vf) < 1.0e-8 && ...
        abs(a0-af) < 1.0e-7
    coef = [pf,0.0,0.0,0.0,0.0,0.0];
    duration = 0.0;
    ok = true;
    return;
end

durationHigh = max(10.0*Ts,0.05);
coef = quinticCoefficients(p0,v0,a0,pf,vf,af,durationHigh);

while ~profileWithinLimits(coef,durationHigh,vMax,aMax,jMax) && ...
        durationHigh < maxTime
    durationHigh = min(maxTime,2.0*durationHigh);
    coef = quinticCoefficients(p0,v0,a0,pf,vf,af,durationHigh);
end

ok = profileWithinLimits(coef,durationHigh,vMax,aMax,jMax);
if ~ok
    duration = durationHigh;
    return;
end

durationLow = max(Ts,0.001);
for iteration = 1:48
    durationMid = 0.5*(durationLow+durationHigh);
    coefMid = quinticCoefficients(p0,v0,a0,pf,vf,af,durationMid);
    if profileWithinLimits(coefMid,durationMid,vMax,aMax,jMax)
        durationHigh = durationMid;
        coef = coefMid;
    else
        durationLow = durationMid;
    end
end

duration = durationHigh;
end

function coef = quinticCoefficients(p0,v0,a0,pf,vf,af,T)
if T <= 0.0
    coef = [pf,0.0,0.0,0.0,0.0,0.0];
    return;
end

T2 = T*T;
T3 = T2*T;
T4 = T3*T;
T5 = T4*T;

c0 = p0;
c1 = v0;
c2 = 0.5*a0;
c3 = (20.0*(pf-p0) - (8.0*vf+12.0*v0)*T ...
      - (3.0*a0-af)*T2)/(2.0*T3);
c4 = (30.0*(p0-pf) + (14.0*vf+16.0*v0)*T ...
      + (3.0*a0-2.0*af)*T2)/(2.0*T4);
c5 = (12.0*(pf-p0) - (6.0*vf+6.0*v0)*T ...
      - (a0-af)*T2)/(2.0*T5);

coef = [c0,c1,c2,c3,c4,c5];
end

function [position,velocity,acceleration] = evaluateQuintic(coef,time,duration)
if duration <= 0.0
    position = coef(1);
    velocity = 0.0;
    acceleration = 0.0;
    return;
end

t = clampValue(time,0.0,duration);
c0 = coef(1);
c1 = coef(2);
c2 = coef(3);
c3 = coef(4);
c4 = coef(5);
c5 = coef(6);

position = c0+t*(c1+t*(c2+t*(c3+t*(c4+t*c5))));
velocity = c1+t*(2.0*c2+t*(3.0*c3+t*(4.0*c4+t*5.0*c5)));
acceleration = 2.0*c2+t*(6.0*c3+t*(12.0*c4+t*20.0*c5));
end

function jerk = evaluateJerk(coef,time,duration)
if duration <= 0.0
    jerk = 0.0;
    return;
end
t = clampValue(time,0.0,duration);
jerk = 6.0*coef(4)+t*(24.0*coef(5)+t*60.0*coef(6));
end

function ok = profileWithinLimits(coef,duration,vMax,aMax,jMax)
if duration <= 0.0
    ok = true;
    return;
end

ok = true;
for sample = 0:240
    t = duration*double(sample)/240.0;
    [~,velocity,acceleration] = evaluateQuintic(coef,t,duration);
    jerk = evaluateJerk(coef,t,duration);
    if abs(velocity) > vMax*(1.0+1.0e-8) || ...
       abs(acceleration) > aMax*(1.0+1.0e-8) || ...
       abs(jerk) > jMax*(1.0+1.0e-8)
        ok = false;
        return;
    end
end
end

function safe = trajectoryClearsObstacle( ...
    xCoef,xDuration,yCoef,yDuration,yHold, ...
    obstacleMin,obstacleMax,obstacleProfile, ...
    containerHeight,cableStretch,verticalMargin)

safe = true;
for sample = 0:400
    t = xDuration*double(sample)/400.0;
    [x,~,~] = evaluateCruiseProfile(xCoef,t,xDuration);

    if x >= obstacleMin && x <= obstacleMax && abs(x-xCoef(1))>0.02 && abs(x-xCoef(1))>0.02 && abs(x-xCoef(1))>0.02 && abs(x-xCoef(1))>0.02 && abs(x-xCoef(1))>0.02 && abs(x-xCoef(1))>0.02 && abs(x-xCoef(1))>0.02
        if t < yDuration
            [y,~,~] = evaluateQuintic(yCoef,t,yDuration);
        else
            y = yHold;
        end

        obstacleHeight=maximumProfileBetween(obstacleProfile,x,x);
        bottomHeight = y-cableStretch-containerHeight;
        if bottomHeight < obstacleHeight+verticalMargin-1.0e-8
            safe = false;
            return;
        end
    end
end
end

function crossingTime = findCrossingTime(coef,duration,position,positiveDirection)
crossingTime = duration;
if duration <= 0.0
    return;
end

previousTime = 0.0;
[previousPosition,~,~] = evaluateCruiseProfile(coef,0.0,duration);

for sample = 1:400
    currentTime = duration*double(sample)/400.0;
    [currentPosition,~,~] = evaluateCruiseProfile( ...
        coef,currentTime,duration);

    if positiveDirection
        crossed = previousPosition < position && currentPosition >= position;
    else
        crossed = previousPosition > position && currentPosition <= position;
    end

    if crossed
        low = previousTime;
        high = currentTime;
        for iteration = 1:32
            middle = 0.5*(low+high);
            [middlePosition,~,~] = evaluateCruiseProfile(coef,middle,duration);
            if positiveDirection
                if middlePosition >= position
                    high = middle;
                else
                    low = middle;
                end
            else
                if middlePosition <= position
                    high = middle;
                else
                    low = middle;
                end
            end
        end
        crossingTime = high;
        return;
    end

    previousTime = currentTime;
    previousPosition = currentPosition;
end
end


function vMax = hoistSpeedLimit(totalMassKg,loaded)
if loaded
    massUse=clampValue(totalMassKg,15000.0,65000.0);
    vMax=min(3.0,max(1.5,97500.0/massUse));
else
    vMax=3.0;
end
end
