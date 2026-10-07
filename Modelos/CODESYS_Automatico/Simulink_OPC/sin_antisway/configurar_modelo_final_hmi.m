%% Configuración de la visualización 2D para el modelo final
% Este script se ejecuta después de los parámetros de planta y control.
% No modifica ninguna señal dinámica: solo arma la estructura gráfica Pvis.

requiredVariables = {'Y_t0','H_c','W_c','x_tmin','x_tmax', ...
    'x_tminU','x_tmaxU','y_hminU','Y_c0','nLevels0', ...
    'Zbase','slotBlock','slotZone'};
for variableIndex = 1:numel(requiredVariables)
    assert(exist(requiredVariables{variableIndex}, 'var') == 1, ...
        'Visualizacion:VariableFaltante', ...
        'Falta la variable requerida %s.', requiredVariables{variableIndex});
end

Pvis = struct();
Pvis.nombreFigura = 'Grúa Portuaria STS - Modelo final';
Pvis.Ts_viz = 0.04;
Pvis.enable = true;
Pvis.keepFigureOnTerminate = true;

% Panel HMI. Los controles graficos solo generan solicitudes crudas; la
% validacion/enclavamiento definitivo debe realizarse en una interfaz de
% mando separada antes de ingresar al supervisor o al nivel de seguridad.
Pvis.hmi = struct();
Pvis.hmi.enable = true;
Pvis.hmi.panelWidth = 0.285;
Pvis.hmi.pulseSamples = 1;
Pvis.hmi.colors = struct( ...
    'background', [0.10 0.12 0.15], ...
    'panel',      [0.16 0.18 0.22], ...
    'text',       [0.93 0.95 0.97], ...
    'muted',      [0.65 0.69 0.74], ...
    'ok',         [0.18 0.68 0.36], ...
    'warning',    [0.95 0.64 0.12], ...
    'alarm',      [0.85 0.16 0.16], ...
    'inactive',   [0.35 0.38 0.42], ...
    'accent',     [0.10 0.55 0.85]);

% Geometría usada por visualizacion_sistema.m.
Pvis.geo = struct();
Pvis.geo.Yt0 = Y_t0;
Pvis.geo.Hc = H_c;
Pvis.geo.Wc = W_c;
Pvis.geo.Hs = 0.55;
Pvis.geo.Ws = 3.00;
Pvis.geo.Wt = 4.20;
Pvis.geo.Ht = 2.00;
Pvis.geo.Ytop = 60.0;
Pvis.geo.xLS = -30.0;
Pvis.geo.xWS = -5.0;
Pvis.geo.xBoomL = -36.0;
Pvis.geo.xBoomR = 56.0;

% Ventana gráfica: cubre muelle, barco y toda la estructura de la grúa.
Pvis.view = struct();
Pvis.view.xMin = x_tminU - 20.0;
Pvis.view.xMax = x_tmaxU + 10.0;
Pvis.view.yMin = y_hminU - 4.5;
Pvis.view.yMax = max(Y_t0 + 3.0, Pvis.geo.Ytop + 4.0);

% Perfil inicial y geometría horizontal de los slots.
Pvis.obs = struct();
Pvis.obs.Y_c0 = Y_c0(:);
Pvis.obs.nLevels0 = nLevels0(:);
Pvis.obs.Zbase = Zbase(:);
Pvis.obs.slotBlock = logical(slotBlock(:));
Pvis.obs.slotZone = int32(slotZone(:));
Pvis.obs.Nslots = numel(Pvis.obs.Y_c0);
Pvis.obs.h_std = H_c;
Pvis.obs.slotWidth = W_c;
Pvis.obs.x0_slot_left = x_tmin;

slotIndices = (1:Pvis.obs.Nslots).';
Pvis.obs.xLeft = x_tmin + double(slotIndices - 1) * W_c;
Pvis.obs.xRight = x_tmin + double(slotIndices) * W_c;
Pvis.obs.xCenters = 0.5 * (Pvis.obs.xLeft + Pvis.obs.xRight);
Pvis.obs.blockedSlots = int32(find(Pvis.obs.slotZone == 0));
Pvis.obs.dockSlots = int32(find(Pvis.obs.slotZone == 1));
Pvis.obs.shipSlots = int32(find(Pvis.obs.slotZone == 2));

% Objetivo inicial de la HMI: slot operable mas cercano a la consigna
% horizontal que usa actualmente la interfaz del supervisor (23 m).
operableSlots = find(~Pvis.obs.slotBlock);
[~, nearestOperableIndex] = min(abs(Pvis.obs.xCenters(operableSlots) - 23.0));
Pvis.hmi.defaultTargetSlot = operableSlots(nearestOperableIndex);
Pvis.hmi.defaultTargetX = Pvis.obs.xCenters(Pvis.hmi.defaultTargetSlot);
Pvis.hmi.defaultTargetY = 0.0;

% Barco simplificado, derivado directamente del perfil de slots.
assert(~isempty(Pvis.obs.shipSlots), 'Visualizacion:SinBarco', ...
    'El perfil no contiene slots de barco.');
Pvis.ship = struct();
Pvis.ship.firstSlot = Pvis.obs.shipSlots(1);
Pvis.ship.lastSlot = Pvis.obs.shipSlots(end);
Pvis.ship.xLeft = Pvis.obs.xLeft(double(Pvis.ship.firstSlot));
Pvis.ship.xRight = Pvis.obs.xRight(double(Pvis.ship.lastSlot));
Pvis.ship.yBase = min(Pvis.obs.Zbase(double(Pvis.obs.shipSlots)));
Pvis.ship.yDeck = 0.0;
Pvis.ship.faceColor = [0.18 0.23 0.28];
Pvis.ship.edgeColor = [0.05 0.07 0.09];

% Comprobaciones mínimas para evitar errores al iniciar la S-Function.
profileLengths = [numel(Pvis.obs.Y_c0), numel(Pvis.obs.nLevels0), ...
    numel(Pvis.obs.Zbase), numel(Pvis.obs.slotBlock), ...
    numel(Pvis.obs.slotZone)];
assert(all(profileLengths == Pvis.obs.Nslots), ...
    'Visualizacion:PerfilInconsistente', ...
    'Los vectores del perfil deben tener la misma longitud.');


Pvis.safetyLine = struct('y', HMI.manualToAutoHeight, 'offsetContainers', 2);
Pvis.nombreFigura = 'Modelo Final HMI';

