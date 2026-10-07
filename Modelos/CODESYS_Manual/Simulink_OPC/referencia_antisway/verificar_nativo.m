function verificar_nativo(folder,out)
if nargin<2,R=load(fullfile(folder,'datos_brutos.mat'),'output');out=R.output;end
p=load(fullfile(folder,'preflight.mat'),'preflight');p=p.preflight;
S=load(fullfile(folder,'datos_derivados.mat'),'S','t');
C=readtable(fullfile(folder,'criterios.csv'),'TextType','string');
a=out.logsout.get('mc_diag_vref_input').Values;b=out.logsout.get('v_cmd').Values;
c=out.logsout.get('antisway_efectiva').Values;
assert(isequal(a.Time,b.Time),'v_ref y v_cmd tienen tiempos distintos; requiere interpolacion por tiempo.');
native=struct('correccionMaxima',max(abs(c.Data(:))), ...
    'diferenciaMaxima',max(abs(double(b.Data(:))-double(a.Data(:)))), ...
    'muestras',numel(c.Time),'tiempoFinal',c.Time(end),'tiemposIguales',true);
if strcmp(p.variante,'sin_antisway')
    add('Antisway cero en TODAS muestras nativas',native.correccionMaxima,1e-10,'Sin remuestreo');
    add('v_cmd igual v_ref en TODAS muestras nativas',native.diferenciaMaxima,1e-10,'Vectores de tiempo nativos identicos');
end
mass=out.logsout.get('masa_fisica_suspendida').Values;
native.masaFisicaFinal=double(mass.Data(end));
profile=S.S.mon_obstacleProfile;
native.perfilFisicoInicial=profile(1,:).';native.perfilFisicoFinal=profile(end,:).';
native.cambioSlot2=profile(end,2)-profile(1,2);
native.cambioSlot22=profile(end,22)-profile(1,22);
if ismember(p.variante,{'sin_antisway','referencia_antisway'})
    add('Masa fisica final vacia',abs(native.masaFisicaFinal-p.masaSpreader),1e-6,'Medicion fisica de planta, ultima muestra nativa');
    add('Retiro fisico slot 2',abs(native.cambioSlot2+2.59),1e-9,'Perfil fisico de planta');
    add('Entrega fisica slot 22',abs(native.cambioSlot22-2.59),1e-9,'Perfil fisico de planta, incremento de un contenedor');
end
env=out.logsout.get('grupo1_Outport_44').Values;
z=squeeze(double(env.Data));if size(z,1)==numel(env.Time),z=z(1,:).';else,z=z(:,1);end
expected=zeros(33,1);for k=1:33,expected(k)=max(p.perfilInicial(max(1,k-1):min(33,k+1)));end
native.errorEnvolventeInicial=max(abs(z-expected));
add('Envolvente inicial coherente',native.errorEnvolventeInicial,1e-9,'Primera muestra del PLC frente a maximo de tres slots fisicos');
save(fullfile(folder,'verificacion_nativa.mat'),'native');
writetable(C,fullfile(folder,'criterios.csv'));
meta=jsondecode(fileread(fullfile(folder,'metadatos.json')));meta.verificacionNativa=native;
fid=fopen(fullfile(folder,'metadatos.json'),'w');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);
fprintf('VERIFICACION NATIVA %s muestras=%d vsw=%.9g delta=%.9g masaFinal=%.0f deltaSlots=[%.2f %.2f] envError=%.3g\n',p.variante,native.muestras,native.correccionMaxima,native.diferenciaMaxima,native.masaFisicaFinal,native.cambioSlot2,native.cambioSlot22,native.errorEnvolventeInicial);
    function add(label,value,threshold,reason)
        result="NO_APROBADO";if value<=threshold,result="APROBADO";end
        C(end+1,:)={string(label),value,threshold,result,string(reason)};
    end
end

