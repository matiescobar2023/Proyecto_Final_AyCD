function [Y_c0, nLevels, Zbase, isBlocked, zone] = perfil_inicial_std()
%PERFIL_INICIAL_STD
% Genera un perfil inicial de la PLANTA con una única altura STD.
%
% Salidas:
%   Y_c0      : (33x1) altura absoluta del tope por slot [m]
%   nLevels  : (33x1) cantidad de contenedores por slot
%   Zbase    : (33x1) base vertical por slot [m]
%   isBlocked: (33x1) mascara logica de slots no operables
%   zone     : (33x1) codigo de zona:
%              0 = bloqueado / no operable
%              1 = muelle operable
%              2 = barco operable
%
% Convenciones:
% - x in [-30, 50] m
% - slotWidth = 2.44 m
% - Slots 1-10  : muelle
% - Slots 11-13 : inaccesibles
% - Slots 14-32 : barco
% - Slot 33     : inaccesible
% - Altura única: STD = 2.59 m

%% ---------------- Discretizacion horizontal ----------------
x_min = -30;
x_max =  50;
slotWidth = 2.44;

L = x_max - x_min;
Nslots = ceil(L/slotWidth);    % 33

%% ---------------- Zonas por indice ----------------
pier_operable = 1:10;
ship_operable = 14:32;
blocked = [11 12 13 33];

%% ---------------- Altura unica ----------------
h_std = 2.59;   % [m]

%% ---------------- Inicializacion ----------------
nLevels   = zeros(Nslots,1);
Zbase     = zeros(Nslots,1);
Y_c0      = zeros(Nslots,1);
isBlocked = false(Nslots,1);
zone      = zeros(Nslots,1);

%% ---------------- Definicion de zonas ----------------
zone(pier_operable) = 1;
zone(ship_operable) = 2;
zone(blocked)       = 0;

isBlocked(blocked) = true;

%% ---------------- Base vertical ----------------
% Muelle operable: base en y = 0
Zbase(pier_operable) = 0;

% Barco operable: base en y = -20
Zbase(ship_operable) = -20;

% Slots bloqueados:
% No representan una superficie fisica de operacion.
% Se deja Zbase = 0 por neutralidad, pero NO se debe usar para contacto,
% pick/place ni planificacion.
Zbase(blocked) = 0;

%% ---------------- Parametros aleatorios ----------------
%rng('shuffle'); %aleatorio
rng(50);
maxLevels_pier = 4;
maxLevels_ship = 15;

%% ---------------- Generacion de niveles ----------------
for k = 1:Nslots

    if zone(k) == 1
        % Muelle
        nLevels(k) = randi([0 maxLevels_pier]);

    elseif zone(k) == 2
        % Barco
        nLevels(k) = randi([0 maxLevels_ship]);

    else
        % Bloqueado
        nLevels(k) = 0;
    end

end

%% ---------------- Perfil absoluto ----------------
Y_c0 = Zbase + nLevels*h_std;

%% ---------------- Correccion final de bloqueados ----------------
% Importante:
% No se usa -1 como marca sentinela dentro de Y_c0.
% El estado bloqueado viaja por isBlocked y zone.
Y_c0(blocked) = 0;
nLevels(blocked) = 0;

%% ---------------- Asegurar vectores columna ----------------
Y_c0      = Y_c0(:);
nLevels  = nLevels(:);
Zbase    = Zbase(:);
isBlocked = isBlocked(:);
zone      = zone(:);

end
