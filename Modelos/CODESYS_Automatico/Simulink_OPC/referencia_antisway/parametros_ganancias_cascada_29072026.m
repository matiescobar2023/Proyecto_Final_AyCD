
% No limpiar el workspace: este archivo se ejecuta desde el InitFcn del
% modelo y debe conservar las variables y objetos que administra Simulink.
%% PARAMETROS Y GANANCIAS - CONTROL EN CASCADA
% Modelo asociado: cascada_29072026.slx
%
% Arquitectura del carro:
%   posicion P -> referencia de velocidad
%   anti-sway -> correccion limitada de velocidad
%   velocidad PI -> correccion de aceleracion
%   aceleracion feedforward + PI -> computed torque
%   modulador de par de la planta
%
% Alcance deliberado:
%   - no hay observador del modo flexible;
%   - no hay notch del cable de carro;
%   - hay anti-windup por limitacion del estado integral de velocidad;
%   - la planta fisica conserva el cable elastico original;
%   - el controlador se sintoniza con la planta rigida equivalente.
%
% El script no ejecuta clear all para poder utilizarse desde InitFcn.

%% 1. Parametros fisicos generales
Y_t0 = 45;             % [m] altura de las poleas de izaje
H_c = 2.59;            % [m] altura de contenedor
W_c = 2.44;            % [m] ancho de contenedor/slot
M_s = 15000;           % [kg] spreader + headblock
M_cmax = 50000;        % [kg] contenedor nominal maximo
M_cmin = 2000;         % [kg] contenedor vacio minimo
g = 9.80665;           % [m/s^2]

%% 2. Contacto carga-apoyo
K_cy = 1.8e9;          % [N/m] rigidez vertical
b_cy = 10.0e6;         % [N.s/m] amortiguamiento vertical
b_cx = 1.0e6;          % [N.s/m] friccion horizontal

%% 3. Cable de izaje
k_wu = 236e6;          % [(N/m).m] rigidez unitaria
b_wu = 150;            % [(N.s/m)/m] amortiguamiento unitario
L_h0 = 110;            % [m] longitud fija desplegada

%% 4. Accionamiento de izaje
r_hd = 0.75;           % [m] radio del tambor
J_hdhEb = 3800;        % [kg.m^2] inercia del eje lento
b_hd = 8.0;            % [N.m/(rad/s)] friccion del eje lento
b_hEb = 2.2e9;         % [N.m/(rad/s)] freno de emergencia
T_hEbMax = 1.1e6;      % [N.m] par maximo freno emergencia
i_h = 22;              % [-] relacion de transmision
J_hmhb = 30.0;         % [kg.m^2] inercia del eje rapido
b_hm = 18.0;           % [N.m/(rad/s)] friccion del eje rapido
b_hb = 100e6;          % [N.m/(rad/s)] freno de operacion
T_hbMax = 50.0e3;      % [N.m] par maximo freno operacion
tau_hm = 1.0e-3;       % [s] modulador de par
T_hmMax = 20.0e3;      % [N.m] par maximo motor

%% 5. Carro y cable de carro
M_t = 30000;           % [kg] masa del carro
b_t = 90.0;            % [N.s/m] friccion del carro
K_tw = 480e3;          % [N/m] rigidez del cable de carro
b_tw = 3.0e3;          % [N.s/m] amortiguamiento del cable

%% 6. Accionamiento del carro
r_td = 0.50;           % [m] radio del tambor
J_td = 1200;           % [kg.m^2] inercia del eje lento
b_td = 1.8;            % [N.m/(rad/s)] friccion del eje lento
i_t = 30.0;            % [-] relacion de transmision
J_tmtb = 7.0;          % [kg.m^2] inercia del eje rapido
b_tm = 6.0;            % [N.m/(rad/s)] friccion del eje rapido
b_tb = 5.0e6;          % [N.m/(rad/s)] freno de operacion
T_tbMax = 5.0e3;       % [N.m] par maximo freno
tau_tm = 1.0e-3;       % [s] modulador de par
T_tmMax = 4.0e3;       % [N.m] par maximo motor

%% 7. Limites operativos
x_tmin = -30.0;        % [m]
x_tminU = -30.5;       % [m]
x_tmax = 50.0;         % [m]
x_tmaxU = 50.5;        % [m]
v_tmax = 4.0;          % [m/s]
dv_tmax = 0.80;        % [m/s^2]

y_hmin = -20.0;        % [m]
y_hminU = -20.5;       % [m]
y_hmax = 40.0;         % [m]
y_hmaxU = 40.50;       % [m]
Y_sb = 5;              % [m]
v_hmaxLoaded = 1.5;    % [m/s]
v_hmaxUnloaded = 3.0;  % [m/s]
dv_hmax = 0.75;        % [m/s^2]

omega_hmRATED = 2*i_h*v_hmaxLoaded/r_hd; % [rad/s]

%% 8. Parametros equivalentes
% Estas expresiones respetan la convencion utilizada por la planta original.
J_teq = (J_tmtb*i_t^2 + J_td)/i_t;
b_teq = (b_tm*i_t^2 + b_td)/i_t;

J_heq = (J_hmhb*i_h^2 + J_hdhEb)/i_h;
b_heq = (b_hm*i_h^2 + b_hd)/i_h;

% Modelo rigido equivalente utilizado por el computed torque del carro.
M_EQt = M_t + J_teq*i_t/r_td^2;       % [kg]
b_EQt = b_t + b_teq*i_t/r_td^2;       % [N.s/m]

% Modelo equivalente de longitud de cable utilizado por izaje.
M_EQh = 2*(J_hdhEb + i_h^2*J_hmhb)/r_hd^2;
b_EQh = 2*(b_hd + i_h^2*b_hm)/r_hd^2;

%% 9. Condiciones iniciales y perfil
l_hi = 20;                            % [m]
[Y_c0, nLevels0, Zbase, slotBlock, slotZone] = perfil_inicial_std();

%% 10. Tiempos de muestreo de la arquitectura jerarquica
% Valores especificados por la guia del proyecto.
T_s = 0.001;                          % [s] Nivel 2 - control regulatorio
T_s1 = 0.020;                         % [s] Nivel 1 - supervisor
T_s0 = 0.020;                         % [s] Nivel 0 - proteccion

%% 10.1 Patron reproducible de masas de contenedores
% La masa pertenece a la planta y no al controlador. El patron incluye
% contenedores vacios, cargas intermedias, carga nominal y sobrecarga para
% permitir ensayos reproducibles de toda la logica de supervision.
rng(317, 'twister');
M_c_profile = M_cmin + (M_cmax-M_cmin).*rand(33,1);
M_c_profile([3 17]) = M_cmin;
M_c_profile([8 24]) = M_cmax;
M_c_profile(30) = 1.08*M_cmax;        % [kg] caso deliberado de sobrecarga
M_c_profile = round(M_c_profile);     % [kg]
M_c_test = M_c_profile(1);            % caso de respaldo/ensayo unitario

%% 10.2 Configuracion de operacion/HMI
% Estas variables reemplazan constantes dispersas y constituyen la interfaz
% de configuracion reproducible. Pueden vincularse a bloques Dashboard sin
% modificar el supervisor ni la planta.
HMI = struct();
HMI.modeAutoReq = false;              % arranque seguro en modo manual
HMI.useJoystick = false;              % true sólo con dispositivo conectado
HMI.configValid = true;
HMI.swayControlSelect = true;
HMI.shipTargetX = 23.0;               % [m], unico destino requerido al automatico
HMI.clearanceOffsetContainers = 2.0;  % linea = max(perfil) + 2 contenedores
HMI.manualToAutoHeight = max(Y_c0) + ...
    HMI.clearanceOffsetContainers*H_c; % [m], valor inicial informativo
HMI.finalApproachDistance = 2.0;      % [m]
HMI.scanProfileReq = false;           % solicita relevamiento LIDAR con spreader vacio
HMI.scanSpeed = 2.0;                  % [m/s], velocidad objetivo del relevamiento
HMI.lidarOffsetX = -3.0;              % [m], delante en el sentido del barrido derecha->izquierda
HMI.watchdogTimeout = 0.10;           % [s], > 2 ciclos de Nivel 1

%% 11. Trayectoria suave del carro
% Selector de destino:
%   1 -> recorrido corto:   5.0 m
%   2 -> recorrido actual: 10.2 m
%   3 -> recorrido largo:  20.0 m
%
% El generador usa el polinomio normalizado de septimo orden:
%   sigma(s) = 35*s^4 - 84*s^5 + 70*s^6 - 20*s^7,  0 <= s <= 1
%
% Este perfil impone velocidad, aceleracion y jerk nulos en los extremos.
% La duracion se calcula para respetar simultaneamente los limites elegidos.
trayectoria_carro_opcion = 2;         % {1,2,3}; 2 conserva el destino actual
trayectoria_carro_objetivos = [5.0 10.2 20.0]; % [m]

assert(isscalar(trayectoria_carro_opcion) && ...
    any(trayectoria_carro_opcion == 1:3), ...
    'trayectoria_carro_opcion debe ser 1, 2 o 3.');

traj_x_start = 0.0;                   % [m]
traj_x_target = trayectoria_carro_objetivos(trayectoria_carro_opcion); % [m]
traj_v_max = 2.5;                     % [m/s], limite de diseño del perfil
traj_a_max = dv_tmax;                 % [m/s^2]
traj_j_max = 0.8;                     % [m/s^3]
traj_time_margin = 1.10;              % [-], evita operar justo en los limites

% Maximos de las derivadas del polinomio normalizado:
%   max|sigma'|   = 2.1875
%   max|sigma''|  = 7.513188...
%   max|sigma'''| = 52.5
traj_delta_x = abs(traj_x_target-traj_x_start);
traj_T_v = 2.1875*traj_delta_x/traj_v_max;
traj_T_a = sqrt(7.5131884044*traj_delta_x/traj_a_max);
traj_T_j = nthroot(52.5*traj_delta_x/traj_j_max, 3);
traj_duration_raw = max([traj_T_v traj_T_a traj_T_j]);
traj_duration = ceil(traj_time_margin*traj_duration_raw/T_s)*T_s;

TRAJ_TROLLEY = struct();
TRAJ_TROLLEY.option = trayectoria_carro_opcion;
TRAJ_TROLLEY.targets_m = trayectoria_carro_objetivos;
TRAJ_TROLLEY.x_start_m = traj_x_start;
TRAJ_TROLLEY.x_target_m = traj_x_target;
TRAJ_TROLLEY.duration_s = traj_duration;
TRAJ_TROLLEY.v_limit_mps = traj_v_max;
TRAJ_TROLLEY.a_limit_mps2 = traj_a_max;
TRAJ_TROLLEY.j_limit_mps3 = traj_j_max;
TRAJ_TROLLEY.profile = 'septimo orden, v/a/jerk nulos en extremos';

%% 12. Lazo externo de posicion P
% v_pos = v_ff + K_x_cas*(x_ref - x_td)
%
% Se realimenta x_td porque es la variable disponible desde el encoder.
% No se estima la posicion real x_t en esta version.
% Se conserva el valor 0.05 1/s que estaba configurado al introducir la
% trayectoria suave. La sintonia del controlador se mantiene fuera del
% alcance de este cambio.
K_x_cas = 0.2;                      % [1/s]

%% 13. Lazo interno de velocidad PI
% Para la planta compensada v/a_cmd ~= 1/s:
%   a_PI = K_pv_cas*e_v + K_iv_cas*integral(e_v)
%   s^2 + K_pv_cas*s + K_iv_cas
%
% Sintonia seleccionada luego de barridos sobre la maniobra completa de 60 s.
% Se reduce deliberadamente Ki porque esta version no tiene anti-windup:
% una integral rapida acumulaba error durante los transitorios y aumentaba
% el sobrepaso. La pareja resultante es sobreamortiguada.
K_pv_cas = 2.40;                      % [1/s]
K_iv_cas = 0.20;                      % [1/s^2]
omega_v_cas = sqrt(K_iv_cas);         % [rad/s], frecuencia natural equivalente
zeta_v_cas = K_pv_cas/(2*omega_v_cas); % [-], amortiguamiento equivalente
p_v_cas = roots([1 K_pv_cas K_iv_cas]); % polos nominales del lazo de velocidad

%% 14. Anti-sway sobre referencia de velocidad
% theta_ref = atan2(-a_ff_limitada,g)
% v_sw = 2*zita_sw*sqrt(g*l_h)*(theta_l-theta_ref)
%
% El valor se limita antes de sumarlo a la referencia de velocidad.
% Con l_h = 20 m, zita_sw = 1.4 produce una accion de amortiguamiento
% suficientemente fuerte sin llevar el par al limite de 4000 N*m.
zita_sw = 1.4;                        % [-]
v_sw_max_cas = 1.4;                   % [m/s]
% Tiempo de incorporacion lineal del SW aplicado en el R2 actual.
T_SW_on = 2.0;                       % [s], desde E=1 y orden de freno abierto

%% 15. Feedforward de aceleracion
% La aceleracion de trayectoria se limita cinematicamente antes de:
%   - calcular theta_ref;
%   - sumarse a la salida del PI de velocidad.
%
% Esta version no implementa aun un reference governor dependiente de par.
a_ff_max_cas = dv_tmax;               % [m/s^2]

%% 16. Control de izaje conservado
% Se mantiene la sintonia de la version grua_debbug_28072026.
n_h = 2.7;
omega_posh = 1.8;                     % [rad/s]
K_hp = -(r_hd*M_EQh*n_h*omega_posh^2)/i_h;
K_hi = -(r_hd*M_EQh*omega_posh^3)/i_h;
K_hd = (r_hd/i_h)*(b_EQh-M_EQh*n_h*omega_posh);

%% 17. Resumen de la sintonia de cascada
CASCADE_INFO = struct();
CASCADE_INFO.K_x = K_x_cas;
CASCADE_INFO.omega_v = omega_v_cas;
CASCADE_INFO.zeta_v = zeta_v_cas;
CASCADE_INFO.K_pv = K_pv_cas;
CASCADE_INFO.K_iv = K_iv_cas;
CASCADE_INFO.velocity_poles = p_v_cas;
CASCADE_INFO.zeta_sw = zita_sw;
CASCADE_INFO.v_sw_max = v_sw_max_cas;
CASCADE_INFO.a_ff_max = a_ff_max_cas;
CASCADE_INFO.antiwindup_implemented = true;
CASCADE_INFO.flexible_mode_controller = false;
CASCADE_INFO.angular_rate_antisway = false;
CASCADE_INFO.tuning_note = ...
    ['Seleccion conservadora: menor integral y mayor amortiguamiento ' ...
     'anti-sway, validada en la maniobra nominal de 60 s.'];
