% EJEMPLO_ANALISIS: datos guardados; no conecta al PLC ni simula.
carpeta=fileparts(mfilename('fullpath'));
R=load(fullfile(carpeta,'datos_derivados.mat'),'t','S');
C=readtable(fullfile(carpeta,'cobertura_registro.csv'),'TextType','string');
% Limitar a la cobertura comun evita mostrar extrapolaciones como mediciones.
ends=C.tiempoFinal_s(C.muestras>1);
finComun=min(ends); idx=R.t<=finComun; t=R.t(idx); S=R.S;
figure('Name','Dinamica: cobertura comun');tiledlayout(4,2,'TileSpacing','compact');
reales={'x_carro_fisica','y_carga_fisica','v_carro_fisica','v_izaje_fisica','ax','ay','angulo_fisico','velocidad_angular_fisica'};
refs={'mon_xRef','mon_yRef','mon_vxRef','mon_vyRef','mon_axRef','mon_ayRef','angulo_referencia','omega_referencia'};
unidades={'Carro [m]','Izaje [m]','vx [m/s]','vy [m/s]','ax [m/s^2]','ay [m/s^2]','Angulo [rad]','Omega [rad/s]'};
for k=1:8
 a=S.(reales{k}); b=S.(refs{k});nexttile;plot(t,a(idx),t,b(idx));grid on;axis padded;xlim([0 finComun]);ylabel(unidades{k});xlabel('Tiempo [s]');legend('Fisica / derivada','Referencia','Location','best');
end
figure('Name','Actuacion: cobertura comun');tiledlayout(3,1);
nexttile;plot(t,S.torque_carro_consigna_controlador(idx),t,S.torque_carro_fisico_motor(idx));grid on;axis padded;ylabel('Carro [Nm]');legend('Consigna','Fisico');
nexttile;plot(t,S.torque_izaje_consigna_controlador(idx),t,S.torque_izaje_fisico_motor(idx));grid on;axis padded;ylabel('Izaje [Nm]');legend('Consigna','Fisico');
nexttile;plot(t,S.v_ref(idx),t,S.v_cmd(idx),t,S.antisway_efectiva(idx));grid on;axis padded;ylabel('Velocidad [m/s]');xlabel('Tiempo [s]');legend('Referencia MC','Comando MC','Antisway efectiva');
E=readtable(fullfile(carpeta,'eventos_modo.csv'));M=readtable(fullfile(carpeta,'eventos_maniobra.csv'),'TextType','string');
figure('Name','Modos efectivos');stairs(E.tiempo_s,E.modo_codigo);grid on;xlabel('Tiempo [s]');ylabel('Modo PLC');
duraciones=table(M.descripcion(1:end-1),M.tiempo_s(1:end-1),M.tiempo_s(2:end),diff(M.tiempo_s),'VariableNames',{'evento','inicio_s','fin_s','duracion_s'});disp(duraciones);
disp(readtable(fullfile(carpeta,'metricas_etapas.csv')));
fprintf('Figuras limitadas a cobertura comun %.3f s. Datos originales en datos_brutos.mat; derivadas segun metodo de datos_derivados.mat.\n',finComun);
