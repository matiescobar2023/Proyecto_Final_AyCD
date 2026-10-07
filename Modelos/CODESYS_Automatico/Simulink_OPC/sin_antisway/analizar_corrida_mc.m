function analizar_corrida_mc(folder,out,q)
% Solo posprocesado; no se conecta al PLC ni modifica la corrida original.
if nargin<1,folder=getappdata(0,'MedioCicloCarpeta');end
if nargin<2,R=load(fullfile(folder,'datos_brutos.mat'),'output','q');out=R.output;q=R.q;end
catalogar_mc(folder,out);
completar_eventos(folder);
completar_criterios(folder,out);
metadata=jsondecode(fileread(fullfile(folder,'metadatos.json')));
metadata.modeloFuente='Grua_MC_R2_FFLimitado_06102026.slx';
metadata.control='MC R2, observadores Tustin, FF antisway limitado en derivada a 0.25 m/s^2';
metadata.transferenciaSupervisorNueva=false;
metadata.colisionMensajeHMI='Oculto; canal y diagnosticos conservados';
run(fullfile(folder,'parametros_ganancias_cascada_29072026.m'));
run(fullfile(folder,'configurar_parametros_variadores.m'));
metadata.parametrosMC=MC_FF;
videos=dir(fullfile(folder,'Video_prueba_conjunta','*.mp4'));
metadata.video='';
if ~isempty(videos)
 [~,vi]=max([videos.datenum]);metadata.video=fullfile(videos(vi).folder,videos(vi).name);
 try
  reader=VideoReader(metadata.video);metadata.videoDuracion_s=reader.Duration;
  metadata.videoFPS=reader.FrameRate;reader.CurrentTime=max(0,reader.Duration-1/reader.FrameRate);
  frame=readFrame(reader);imwrite(frame,fullfile(folder,'hmi_final_video.png'));
 catch ex
  metadata.videoVerificacionError=ex.message;
 end
end
fid=fopen(fullfile(folder,'metadatos.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(metadata,PrettyPrint=true));fclose(fid);
fid=fopen(fullfile(folder,'README.md'),'w','n','UTF-8');
fprintf(fid,'# Corrida %s\n\nResultado completo: %d. Tiempo final: %.2f s.\n\nCausa: %s.\n\nDatos brutos y buses en datos_brutos.mat, con tiempos nativos; derivados separados. El catalogo de hojas de los buses es catalogo_senales_mc.csv.\n\nVideo: %s.\n\nVer README del banco para las adaptaciones y la diferencia de transferencia del supervisor.\n',metadata.modelo,metadata.completo,metadata.tiempoFinal_s,metadata.causaTerminacion,metadata.video);
fclose(fid);
end

