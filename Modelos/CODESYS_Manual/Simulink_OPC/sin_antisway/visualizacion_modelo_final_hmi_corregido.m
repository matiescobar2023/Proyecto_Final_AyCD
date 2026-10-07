function visualizacion_modelo_final_hmi_corregido(block)
% VISUALIZACION_MODELO_FINAL_HMI_CORREGIDO - Level-2 S-Function
% Visualización dinámica de grúa STS con soporte de perfil de contenedores (Y_c).

setup(block);
end

% -------------------------------------------------------------------------
function setup(block)
  block.NumDialogPrms  = 0;
  % Entradas 1:9: animacion existente.
  % 10 modeCode; 11 contacto; 12 masa estimada [kg]; 13 masa valida;
  % 14 antisway; 15/16/17 frenos carro/izaje/emergencia abiertos;
  % 18/19 joystick carro/izaje [-1,1]; 20/21 velocidades manuales [m/s];
  % 22 emergencia; 23 sobrecarga; 24..27 limites normales
  % Xmin/Xmax/Ymin/Ymax; 28 colision; 29 watchdog; 30 solicitud de modo
  % automatico; 31..34 limites ultimos Xmin/Xmax/Ymin/Ymax.
  block.NumInputPorts  = 42;
  % 35 linea de seguridad; 36 Y objetivo; 37 perfil valido; 38 barrido;
  % 39 trackingFault; 40 faultCode; 41 barrido terminado;
  % 42 envolvente local de seguridad (33 slots, sin margen).
  % Solicitudes crudas de HMI: start, stop, e-stop, relevamiento,
  % slot objetivo, x/y objetivo, aplicar, modo, inicio automatico y reset.
  % Deben pasar por una interfaz de mando con enclavamientos.
  block.NumOutputPorts = 15;
  for i = 1:5
    block.InputPort(i).Dimensions        = 1;
    block.InputPort(i).DatatypeID        = 0;     % double
    block.InputPort(i).DirectFeedthrough = false;
    block.InputPort(i).SamplingMode      = 'Sample';
  end
  block.InputPort(6).Dimensions        = -1;      % Heredado (33 elementos)
  block.InputPort(6).DatatypeID        = 0;
  block.InputPort(6).DirectFeedthrough = false;
  block.InputPort(6).SamplingMode      = 'Sample';
  for i = 7:8
    block.InputPort(i).Dimensions        = 1;
    block.InputPort(i).DatatypeID        = -1;    % Heredado
    block.InputPort(i).DirectFeedthrough = false;
    block.InputPort(i).SamplingMode      = 'Sample';
  end
  block.InputPort(9).Dimensions        = 1;
  block.InputPort(9).DatatypeID        = -1;    % heredado
  block.InputPort(9).DirectFeedthrough = false;
  block.InputPort(9).SamplingMode      = 'Sample';

  for i = 10:41
    block.InputPort(i).Dimensions        = 1;
    block.InputPort(i).DatatypeID        = -1;    % heredado
    block.InputPort(i).DirectFeedthrough = false;
    block.InputPort(i).SamplingMode      = 'Sample';
  end
  block.InputPort(42).Dimensions        = 33;
  block.InputPort(42).DatatypeID        = 0;
  block.InputPort(42).DirectFeedthrough = false;
  block.InputPort(42).SamplingMode      = 'Sample';
  for i = 1:15
    block.OutputPort(i).Dimensions   = 1;
    block.OutputPort(i).DatatypeID   = 0;         % double
    block.OutputPort(i).SamplingMode = 'Sample';
  end
  
  try
    Pvis = evalin('base', 'Pvis');
    Ts   = Pvis.Ts_viz;
  catch
    Ts = 0.05;
  end
  block.SampleTimes = [Ts 0];
  block.RegBlockMethod('SetInputPortDimensions', @SetDims);
  block.RegBlockMethod('Start',     @Start);
  block.RegBlockMethod('Outputs',   @Outputs);
  block.RegBlockMethod('Update', @Update);
  block.RegBlockMethod('Terminate', @Terminate);
end

% -------------------------------------------------------------------------
function SetDims(block, idx, di)
  block.InputPort(idx).Dimensions = di;
end

% -------------------------------------------------------------------------
function Start(block)
  Pvis = evalin('base', 'Pvis');
  
  geo = struct( ...
      'Wt',     4.2, ...      
      'Ht',     2.0, ...      
      'Ws',     2.44, ...     
      'Hs',     0.75, ...     
      'Hc',     2.59, ...     
      'Yt0',    45.0, ...     
      'Ytop',   60.0, ...     
      'xLS',   -30.0, ...     
      'xWS',    -5.0, ...     
      'xBoomL', -36.0, ...
      'xBoomR',  56.0);
  if isfield(Pvis, 'geo')
      f = fieldnames(Pvis.geo);
      for i = 1:length(f)
          geo.(f{i}) = Pvis.geo.(f{i});
      end
  end
  
  fig = figure('Name', 'Grúa STS - Visualizacion + HMI', ...
               'NumberTitle', 'off', ...
               'Position', [35 35 1450 780], ...
               'Tag', 'ModeloFinalHMI', ...
               'Color', [0.94 0.96 0.98]);
  ax = axes('Parent', fig, 'Units', 'normalized', ...
            'Position', [0.045 0.075 0.645 0.865], ...
            'Color', [0.94 0.96 0.98], ...
            'XColor', [0.15 0.18 0.22], 'YColor', [0.15 0.18 0.22]);
  hold(ax, 'on');
  grid(ax, 'on');
  box(ax, 'on');
  ax.GridColor = [0.65 0.65 0.65];
  ax.GridAlpha = 0.35;
  ax.Layer = 'top';
  xlabel(ax, 'x [m]');
  ylabel(ax, 'y [m]');
  title(ax, 'Visualizacion 2D - Grua STS / carro / spreader', 'Color', [0.15 0.18 0.22]);
  
  v_xMin = -40;
  v_xMax = 60;
  v_yMin = -25;
  v_yMax = max(65, geo.Ytop + 4);
  if isfield(Pvis, 'view')
      v_xMin = Pvis.view.xMin;
      v_xMax = Pvis.view.xMax;
      v_yMin = Pvis.view.yMin;
      v_yMax = max(Pvis.view.yMax, geo.Ytop + 4);
  end
  axis(ax, [v_xMin v_xMax v_yMin v_yMax]);
  axis(ax, 'manual');
  
  % ENTORNO
  patch(ax, [v_xMin, 0, 0, v_xMin], [v_yMin, v_yMin, 0, 0], [0.70 0.70 0.70], 'EdgeColor', [0.25 0.25 0.25], 'LineWidth', 1.0);
  patch(ax, [v_xMin, 0, 0, v_xMin], [v_yMin, v_yMin, v_yMin + 3, v_yMin + 3], [0.58 0.58 0.58], 'EdgeColor', 'none', 'FaceAlpha', 0.65);
  patch(ax, [0, v_xMax, v_xMax, 0], [v_yMin, v_yMin, -2, -2], [0.20 0.50 0.70], 'EdgeColor', 'none', 'FaceAlpha', 0.35);
    
  if isfield(Pvis, 'ship')
      drawStaticShip(ax, Pvis.ship);
  end
    
  plot(ax, [v_xMin v_xMax], [0 0], 'k-', 'LineWidth', 1.2);
  plot(ax, [0 0], [v_yMin 5], 'k-', 'LineWidth', 1.2);
  text(ax, 0.5, 3.5, 'x = 0 / borde muelle', 'FontSize', 8, 'Color', [0.15 0.15 0.15], 'BackgroundColor', [1 1 1 0.65], 'Margin', 1);

  % GRUA ESTATICA
  drawStaticCrane(ax, geo);
  
  % OBJETOS DINAMICOS
  h = struct();
  h.geo = geo;
  h.safetyLine = plot(ax, [Pvis.obs.xLeft(1) Pvis.obs.xRight(end)], ...
      [Pvis.safetyLine.y Pvis.safetyLine.y], '--', 'Color', [0.95 0.20 0.08], 'LineWidth', 1.7);
  h.safetyLabel = text(ax, -49, Pvis.safetyLine.y+1.7, 'CRUCE ALTO', ...
      'Color', [0.85 0.18 0.08], 'FontSize', 8, 'BackgroundColor', [1 1 1]);
  h.localSafetyLine = plot(ax, nan, nan, '-', 'Color', [1.00 0.55 0.02], ...
      'LineWidth', 2.1, 'Visible', 'off');
  h.localSafetyLabel = text(ax, -49, 21, 'ENV. LOCAL + 1 CONT.', ...
      'Color', [0.75 0.35 0.01], 'FontSize', 8, ...
      'BackgroundColor', [1 1 1], 'Visible', 'off');
  h.obs = Pvis.obs; % Guardamos los metadatos de los slots para Outputs
  
  % =======================================================================
  % INICIALIZACIÓN DE LOS 33 SLOTS DEL PERFIL Y_c
  % =======================================================================
  Nslots = Pvis.obs.Nslots;
  h.slotPatches = gobjects(Nslots, 1);
  for k = 1:Nslots
      xL = h.obs.xLeft(k);
      xR = h.obs.xRight(k);
      yB = h.obs.Zbase(k);
      yT = h.obs.Y_c0(k); % Altura inicial
      
      % Definir color según el tipo de zona para estética industrial
      if h.obs.slotBlock(k)
          fColor = [0.55 0.55 0.55]; % Gris claro (Bloqueado)
          fAlpha = 0.25;
      else
          fColor = [0.72 0.34 0.12]; % Naranja terracota
          fAlpha = 1;
      end
      
      h.slotPatches(k) = patch(ax, [xL xR xR xL], [yB yB yT yT], fColor, ...
          'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.7, 'FaceAlpha', fAlpha);
  end
  % =======================================================================

  % Resto de objetos dinámicos
  h.hoistRope = plot(ax, [0 0], [0 0], '-', 'Color', [0.03 0.03 0.03], 'LineWidth', 1.25);
  h.trolleyBody  = patch(ax, nan, nan, [0.63 0.63 0.63], 'EdgeColor', 'k', 'LineWidth', 1.2);
  h.trolleyTop   = patch(ax, nan, nan, [0.00 0.00 0.50], 'EdgeColor', 'k', 'LineWidth', 1.0);
  h.trolleyCab   = patch(ax, nan, nan, [0.75 0.88 0.95], 'EdgeColor', 'k', 'LineWidth', 1.0);
  
  h.trolleyWheel = gobjects(1,4);
  for i = 1:4
      h.trolleyWheel(i) = rectangle(ax, 'Position', [0 0 0.1 0.1], 'Curvature', [1 1], 'FaceColor', [0.08 0.08 0.08], 'EdgeColor', 'k', 'LineWidth', 0.8);
  end
  h.sheaves = gobjects(1,2);
  for i = 1:2
      h.sheaves(i) = rectangle(ax, 'Position', [0 0 0.1 0.1], 'Curvature', [1 1], 'FaceColor', [0.25 0.25 0.25], 'EdgeColor', 'k', 'LineWidth', 0.8);
  end
  
  h.headblock = patch(ax, nan, nan, [0.22 0.22 0.22], 'EdgeColor', 'k', 'LineWidth', 1.0);
  h.spreader  = patch(ax, nan, nan, [0.95 0.75 0.05], 'EdgeColor', 'k', 'LineWidth', 1.5);
  h.spreaderRail = gobjects(1,2);
  for i = 1:2
      h.spreaderRail(i) = plot(ax, nan, nan, 'k-', 'LineWidth', 1.2);
  end
  h.twistlocks = gobjects(1,4);
  for i = 1:4
      h.twistlocks(i) = patch(ax, nan, nan, [0.05 0.05 0.05], 'EdgeColor', 'none');
  end
  h.container = patch(ax, nan, nan, [0.72 0.34 0.12], ...
      'EdgeColor', [0.12 0.12 0.12], 'LineWidth', 1.4, 'Visible', 'off');
  % El contenedor suspendido se representa con una cara lisa. Las nervaduras
  % verticales se omiten para evitar que se confundan con cables de izaje.
  h.containerRibs = gobjects(1,0);
  h.cargoCouplers = gobjects(1,2);
  for i = 1:2
      h.cargoCouplers(i) = plot(ax, nan, nan, '-', ...
          'Color', [0.15 0.78 0.34], 'LineWidth', 2.5, 'Visible', 'off');
  end
  h.contactFrame = patch(ax, nan, nan, [1 1 1], ...
      'FaceColor', 'none', 'EdgeColor', [1.00 0.72 0.10], 'LineWidth', 2.0, ...
      'LineStyle', '--', 'Visible', 'off');

  h.simTime = text(ax, 0.018, 0.968, 'SIMULACIÓN  00:00.0', ...
      'Units', 'normalized', 'VerticalAlignment', 'top', ...
      'FontSize', 11, 'FontWeight', 'bold', 'FontName', 'Monospaced', ...
      'Color', [0.95 0.97 1.00], 'BackgroundColor', [0.10 0.14 0.19], ...
      'EdgeColor', [0.10 0.55 0.85], 'LineWidth', 1.2, 'Margin', 6);
  setappdata(fig, 'CraneVisualState', struct( ...
      'wasCarrying', false, 'pickupUntil', -inf, 'releaseUntil', -inf, ...
      'lastCargoX', 0.0, 'lastCargoY', 0.0));
  h.hmi = createHMIPanel(fig, Pvis);
  if isfield(Pvis.hmi, 'testDriver'), h.testDriver = Pvis.hmi.testDriver; end
  if isfield(Pvis.hmi, 'captureFolder'), h.captureFolder = Pvis.hmi.captureFolder; end
  set(fig, 'WindowKeyPressFcn', @hmiKeyPress, ...
      'WindowKeyReleaseFcn', @hmiKeyRelease);
  set_param(block.BlockHandle, 'UserData', h);
end

% -------------------------------------------------------------------------
function Outputs(block)
  % Publicar las solicitudes de la interfaz aun cuando la figura haya sido
  % cerrada. En ese caso todas las ordenes vuelven a un estado seguro.
  for outputIndex = 1:15
      block.OutputPort(outputIndex).Data = 0.0;
  end
  h = get_param(block.BlockHandle, 'UserData');
  if isempty(h) || ~isfield(h, 'hoistRope') || ~ishandle(h.hoistRope)
      block.OutputPort(2).Data = 1.0; % Cerrar la ventana solicita parada.
      return;
  end
  publishHMICommands(block, h);
end

function Update(block)
  h = get_param(block.BlockHandle, 'UserData');
  if isempty(h) || ~isfield(h, 'hoistRope') || ~isgraphics(h.hoistRope), return; end
  fig = ancestor(h.hoistRope, 'figure');
  state = getappdata(fig, 'CraneHMIState');
  state.startPending = false; state.stopPending = false;
  state.surveyPending = false; state.targetPending = false;
  state.resetPending = false; state.twistPulsePending = false;
  setappdata(fig, 'CraneHMIState', state);
  safetyY = double(block.InputPort(35).Data);
  % Solo en pruebas sin video: omitir animacion, conservando el panel que
  % actualiza el estado efectivo y los callbacks del operador cada 0.20 s.
  if isfield(h.hmi,'fastDiagnostic') && h.hmi.fastDiagnostic
      updateHMIPanel(h,block,double(block.InputPort(1).Data), ...
          double(block.InputPort(2).Data),double(block.InputPort(3).Data), ...
          double(block.InputPort(5).Data));
      if isfield(h,'testDriver'), h.testDriver(block,h); end
      drawnow limitrate;
      return;
  end
  set(h.safetyLine, 'YData', [safetyY safetyY]);
  set(h.safetyLabel, 'Position', [-49 safetyY+1.7 0], ...
      'String', sprintf('CRUCE ALTO %.2f m', safetyY));
  if block.InputPort(37).Data > 0.5
      localProfile = double(block.InputPort(42).Data(:)) + 2.59;
      nLocal = min(numel(localProfile),numel(h.obs.xLeft));
      xLocal = reshape([h.obs.xLeft(1:nLocal) h.obs.xRight(1:nLocal)].',1,[]);
      yLocal = reshape([localProfile(1:nLocal) localProfile(1:nLocal)].',1,[]);
      set(h.localSafetyLine,'XData',xLocal,'YData',yLocal,'Visible','on');
      set(h.localSafetyLabel,'Position',[-49 max(localProfile)-2.0 0], ...
          'Visible','on');
  else
      set(h.localSafetyLine,'Visible','off');
      set(h.localSafetyLabel,'Visible','off');
  end
  xt    = block.InputPort(1).Data;
  xl    = block.InputPort(2).Data;
  yl    = block.InputPort(3).Data;
  tlk   = block.InputPort(5).Data;
  Y_c   = block.InputPort(6).Data; % Vector dinámico real de perfiles
  carga_tomada = block.InputPort(9).Data;
  contact = block.InputPort(11).Data > 0.5;
  t     = block.CurrentTime;
  geo = h.geo;
  
  % =======================================================================
  % NUEVO: ACTUALIZACIÓN DINÁMICA DE ALTURAS DEL PERFIL EN SIMULACIÓN
  % =======================================================================
  if isfield(h, 'slotPatches') && isfield(h, 'obs')
      for k = 1:min(length(Y_c), length(h.slotPatches))
          if ishandle(h.slotPatches(k))
              yB = h.obs.Zbase(k);
              yT = Y_c(k); % Cota superior dinámica actual de este slot
              
              % Calculamos cuántos contenedores hay en la pila
              n_blocks = round((yT - yB) / geo.Hc);
              
              xL = h.obs.xLeft(k);
              xR = h.obs.xRight(k);
              
              if n_blocks > 0
                  % Matrices 4xN para dibujar múltiples rectángulos en 1 solo patch
                  X_faces = zeros(4, n_blocks);
                  Y_faces = zeros(4, n_blocks);
                  
                  for b = 1:n_blocks
                      y_bottom = yB + (b-1)*geo.Hc;
                      y_top    = yB + b*geo.Hc - 0.05; % El -0.05 es el margen para ver el bloque
                      
                      X_faces(:, b) = [xL; xR; xR; xL];
                      Y_faces(:, b) = [y_bottom; y_bottom; y_top; y_top];
                  end
                  
                  % Actualizamos el parche pasándole las matrices
                  set(h.slotPatches(k), 'XData', X_faces, 'YData', Y_faces);
              else
                  % Si la pila está vacía, colapsamos el parche al fondo
                  set(h.slotPatches(k), 'XData', [xL; xR; xR; xL], 'YData', [yB; yB; yB; yB]);
              end
          end
      end
  end

  % =======================================================================
  
  % 1. CARRO / TROLLEY
  Wt = geo.Wt; Ht = geo.Ht; yRail = geo.Yt0;
  setPatchRect(h.trolleyBody, xt - Wt/2,    yRail + 0.15,    Wt,      Ht*0.65);
  setPatchRect(h.trolleyTop,  xt - Wt*0.32, yRail + Ht*0.82, Wt*0.64, Ht*0.45);
  setPatchRect(h.trolleyCab,  xt + Wt*0.10, yRail + Ht*0.55, Wt*0.35, Ht*0.45);
  wheelR = 0.28; wheelX = xt + [-0.42 -0.18 0.18 0.42]*Wt;
  for i = 1:4
      set(h.trolleyWheel(i), 'Position', [wheelX(i)-wheelR, yRail-wheelR*0.65, 2*wheelR, 2*wheelR]);
  end
  sheaveR = 0.22; sheaveX = xt + [-0.22 0.22]*Wt;
  for i = 1:2
      set(h.sheaves(i), 'Position', [sheaveX(i)-sheaveR, yRail - 0.72, 2*sheaveR, 2*sheaveR]);
  end
  
  % 2. SPREADER / HEADBLOCK
  % El spreader coincide con el ancho del contenedor para que el acople
  % quede visualmente centrado y los twistlocks caigan sobre sus esquinas.
  Ws_visual = geo.Wc*1.04; Hs = geo.Hs;
  ySpBot = yl; ySpTop = yl + Hs; % yl es el plano inferior del spreader.
  setPatchRect(h.headblock, xl - Ws_visual*0.22, ySpTop + 0.10, Ws_visual*0.44, 0.45);
  setPatchRect(h.spreader,  xl - Ws_visual/2,    ySpBot,        Ws_visual,      Hs);
  set(h.spreaderRail(1), 'XData', xl + [-Ws_visual/2, Ws_visual/2], 'YData', [ySpTop-0.18, ySpTop-0.18]);
  set(h.spreaderRail(2), 'XData', xl + [-Ws_visual/2, Ws_visual/2], 'YData', [ySpBot+0.18, ySpBot+0.18]);
  tlW = 0.15; tlH = 0.16;
  tlx = xl + geo.Wc*[-0.44, -0.36, 0.36, 0.44];
  tly = repmat(ySpBot - tlH*0.35, 1, 4);
  lockColor = [0.10 0.10 0.10];
  if tlk > 0.5, lockColor = [0.12 0.72 0.30]; end
  for i = 1:4
      setPatchRect(h.twistlocks(i), tlx(i)-tlW/2, tly(i)-tlH/2, tlW, tlH);
      set(h.twistlocks(i), 'FaceColor', lockColor);
  end
  
  % 3. CABLE DE IZAJE EQUIVALENTE
  set(h.hoistRope, 'XData', [xt, xl], 'YData', [yRail - 0.50, ySpTop + 0.10]);
  
  % 4. CONTAINER
  xC = xl - geo.Wc/2;
  yC = ySpBot - geo.Hc;
  fig = ancestor(h.container, 'figure');
  visualState = getappdata(fig, 'CraneVisualState');
  carrying = carga_tomada > 0.5;
  if carrying && ~visualState.wasCarrying
      visualState.pickupUntil = t + 0.35;
  elseif ~carrying && visualState.wasCarrying
      visualState.releaseUntil = t + 0.40;
  end
  if carrying
      visualState.lastCargoX = xC;
      visualState.lastCargoY = yC;
  end
  visualState.wasCarrying = carrying;

  releasing = ~carrying && t < visualState.releaseUntil;
  if releasing
      xDraw = visualState.lastCargoX;
      yDraw = visualState.lastCargoY;
      alpha = max(0.0, min(1.0, (visualState.releaseUntil-t)/0.40));
  else
      xDraw = xC;
      yDraw = yC;
      alpha = 1.0;
  end
  showCargo = carrying || releasing;
  updateCarriedContainer(h, xDraw, yDraw, geo, showCargo, alpha);

  showContact = contact && ~carrying;
  setPatchRect(h.contactFrame, xC-0.04, yC-0.04, ...
      geo.Wc+0.08, geo.Hc+0.08);
  set(h.contactFrame, 'Visible', ternaryText(showContact, 'on', 'off'));
  showCouplers = carrying || contact;
  couplerX = xl + geo.Wc*[-0.40 0.40];
  for i = 1:2
      set(h.cargoCouplers(i), 'XData', [couplerX(i) couplerX(i)], ...
          'YData', [ySpBot ySpBot-0.14], ...
          'Visible', ternaryText(showCouplers, 'on', 'off'));
  end
  if carrying && t < visualState.pickupUntil
      set(h.container, 'EdgeColor', [0.12 0.78 0.34], 'LineWidth', 2.4);
  else
      set(h.container, 'EdgeColor', [0.12 0.12 0.12], 'LineWidth', 1.4);
  end
  setappdata(fig, 'CraneVisualState', visualState);
    
  set(h.simTime, 'String', formatSimulationTime(t));
  updateHMIPanel(h, block, xt, xl, yl, tlk);
  if isfield(h, 'testDriver'), h.testDriver(block, h); end
  drawnow limitrate;
end

% -------------------------------------------------------------------------
function hmi = createHMIPanel(fig, Pvis)
  hmi.fastDiagnostic = isfield(Pvis.hmi,'fastDiagnostic') && Pvis.hmi.fastDiagnostic;
  c = Pvis.hmi.colors;
  hmi.colors = c;
  hmi.panel = uipanel('Parent', fig, 'Units', 'normalized', ...
      'Position', [0.705 0.025 0.285 0.95], 'Title', ' HMI - OPERADOR ', ...
      'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', c.text, ...
      'BackgroundColor', c.panel, 'HighlightColor', c.muted);

  hmiText(hmi.panel, [0.04 0.956 0.92 0.024], ...
      'MODO EFECTIVO', 8, 'bold', c.accent, c.panel);
  modeNames = {'APAGADO','MANUAL','AUTOMATICO','PARADA/FALLA'};
  modeX = [0.04 0.275 0.510 0.745];
  hmi.modeBoxes = gobjects(1,4);
  for modeIndex = 1:4
      hmi.modeBoxes(modeIndex) = hmiText(hmi.panel, ...
          [modeX(modeIndex) 0.908 0.215 0.043], modeNames{modeIndex}, ...
          7, 'bold', c.text, c.inactive);
      set(hmi.modeBoxes(modeIndex), 'HorizontalAlignment', 'center');
  end
  hmi.system = hmiText(hmi.panel, [0.04 0.878 0.92 0.038], ...
      'Estado: esperando simulacion', 9, 'normal', c.muted, c.panel);

  hmi.startButton = uicontrol(hmi.panel, 'Style', 'pushbutton', ...
      'Units', 'normalized', 'Position', [0.04 0.815 0.44 0.052], ...
      'String', 'ENCENDER SISTEMA', 'FontWeight', 'bold', ...
      'Callback', @(src,~)queueHMIPulse(src, 'startPending'));
  hmi.stopButton = uicontrol(hmi.panel, 'Style', 'pushbutton', ...
      'Units', 'normalized', 'Position', [0.52 0.815 0.44 0.052], ...
      'String', 'PARAR', 'FontWeight', 'bold', ...
      'Callback', @queueHMIStop);
  hmi.autoStartButton = uicontrol(hmi.panel, 'Style', 'pushbutton', ...
      'Units', 'normalized', 'Position', [0.04 0.755 0.44 0.052], ...
      'String', 'INICIAR MANIOBRA AUTO', 'FontWeight', 'bold', ...
      'Callback', @(src,~)queueHMIPulse(src, 'autoStartPending'));
  hmi.resetButton = uicontrol(hmi.panel, 'Style', 'pushbutton', ...
      'Units', 'normalized', 'Position', [0.52 0.755 0.20 0.052], ...
      'String', 'RESET', 'FontWeight', 'bold', ...
      'Callback', @queueHMIReset);
  hmi.estopButton = uicontrol(hmi.panel, 'Style', 'togglebutton', ...
      'Units', 'normalized', 'Position', [0.74 0.755 0.22 0.052], ...
      'String', 'E-STOP', 'FontWeight', 'bold', ...
      'ForegroundColor', [1 1 1], 'BackgroundColor', c.alarm, ...
      'Callback', @toggleHMIEStop);
  hmi.modeButton = uicontrol(hmi.panel, 'Style', 'togglebutton', ...
      'Units', 'normalized', 'Position', [0.04 0.695 0.34 0.048], ...
      'Tag', 'HMIModeButton', ...
      'String', 'PEDIR AUTO', 'FontWeight', 'bold', ...
      'Callback', @toggleHMIMode);
  hmi.surveyButton = uicontrol(hmi.panel, 'Style', 'pushbutton', ...
      'Units', 'normalized', 'Position', [0.40 0.695 0.27 0.048], ...
      'String', 'RELEVAR', 'FontWeight', 'bold', ...
      'Callback', @(src,~)queueHMIPulse(src, 'surveyPending'));
  hmi.twistlockButton = uicontrol(hmi.panel, 'Style', 'togglebutton', ...
      'Units', 'normalized', 'Position', [0.69 0.695 0.27 0.048], ...
      'String', 'CERRAR TLK', 'FontWeight', 'bold', ...
      'Callback', @toggleHMITwistlock);

  hmiSection(hmi.panel, 0.657, 'OBJETIVO DE MANIOBRA', c);
  hmiText(hmi.panel, [0.04 0.607 0.16 0.036], 'Slot:', 9, 'normal', c.text, c.panel);
  hmi.slotEdit = uicontrol(hmi.panel, 'Style', 'edit', 'Units', 'normalized', ...
      'Position', [0.18 0.605 0.20 0.043], 'Tag', 'HMISlotEdit', ...
      'String', sprintf('%d', Pvis.hmi.defaultTargetSlot), ...
      'Enable', 'off', 'BackgroundColor', [1 1 1], 'ForegroundColor', [0.12 0.15 0.18], ...
      'Callback', @applyHMISlot);
  hmiText(hmi.panel, [0.43 0.607 0.20 0.036], 'Y auto [m]:', 9, 'normal', c.text, c.panel);
  hmi.targetYEdit = uicontrol(hmi.panel, 'Style', 'text', 'Units', 'normalized', ...
      'Position', [0.62 0.605 0.34 0.043], 'Tag', 'HMITargetYEdit', ...
      'String', sprintf('%.2f', Pvis.hmi.defaultTargetY), ...
      'BackgroundColor', [1 1 1], 'ForegroundColor', [0.12 0.15 0.18], ...
      'Enable', 'on');
  hmi.applySlot = uicontrol(hmi.panel, 'Style', 'pushbutton', ...
      'Units', 'normalized', 'Position', [0.04 0.551 0.92 0.043], ...
      'String', 'APLICAR OBJETIVO', 'Enable', 'off', 'Callback', @applyHMISlot);
  hmi.target = hmiText(hmi.panel, [0.04 0.511 0.92 0.035], ...
      sprintf('X: %.2f m  |  Y: %.2f m', Pvis.hmi.defaultTargetX, Pvis.hmi.defaultTargetY), ...
      9, 'normal', c.text, c.panel);
  hmi.targetStatus = hmiText(hmi.panel, [0.04 0.480 0.92 0.030], ...
      'Edicion disponible solo en MANUAL', 8, 'normal', c.muted, c.panel);

  hmiSection(hmi.panel, 0.451, 'POSICION Y CARGA', c);
  hmi.position = hmiText(hmi.panel, [0.04 0.406 0.92 0.036], ...
      'Carro --  |  Carga (--, --)', 9, 'normal', c.text, c.panel);
  hmi.mass = hmiText(hmi.panel, [0.04 0.374 0.92 0.032], ...
      'Masa estimada: -- t  [NO VALIDA]', 9, 'normal', c.text, c.panel);

  hmiSection(hmi.panel, 0.347, 'ESTADOS', c);
  hmi.tlk = hmiText(hmi.panel, [0.04 0.305 0.28 0.032], 'TLK: --', 8, 'bold', c.text, c.inactive);
  hmi.contact = hmiText(hmi.panel, [0.36 0.305 0.28 0.032], 'CONTACTO: --', 8, 'bold', c.text, c.inactive);
  hmi.antisway = hmiText(hmi.panel, [0.68 0.305 0.28 0.032], 'ANTISWAY: --', 8, 'bold', c.text, c.inactive);
  hmi.brakes = hmiText(hmi.panel, [0.04 0.271 0.92 0.030], ...
      'Frenos  Carro: --  Izaje: --  Emerg.: --', 8, 'normal', c.text, c.panel);
  hmiSection(hmi.panel, 0.235, 'FALLAS ACTIVAS', c);
  hmi.faults = uicontrol(hmi.panel, 'Style', 'edit', 'Units', 'normalized', ...
      'Position', [0.04 0.018 0.92 0.208], 'String', {'Sin fallas activas'}, ...
      'FontName', 'Consolas', 'FontSize', 9, 'ForegroundColor', c.text, ...
      'BackgroundColor', c.background, 'Enable', 'inactive', ...
      'HorizontalAlignment', 'left', 'Max', 20, 'Min', 0);

  state = struct('startPending', false, 'stopPending', false, ...
      'autoStartPending', false, 'resetPending', false, ...
      'surveyPending', false, 'targetPending', false, ...
      'eStop', false, 'modeAutoReq', false, 'manualEnabled', false, ...
      'effectiveModeCode', 0, ...
      'twistlockCloseReq', false, 'twistPulsePending', false, ...
      'keyLeft', false, 'keyRight', false, 'keyUp', false, 'keyDown', false, ...
      'keyboardTrolley', 0.0, 'keyboardHoist', 0.0, ...
      'keyboardCommandValue', 0.25, 'lastKeyEvent', now, ...
      'targetSlot', double(Pvis.hmi.defaultTargetSlot), ...
      'targetX', double(Pvis.hmi.defaultTargetX), ...
      'targetY', double(Pvis.hmi.defaultTargetY), ...
      'xCenters', double(Pvis.obs.xCenters(:)), ...
      'slotBlock', logical(Pvis.obs.slotBlock(:)));
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function control = hmiText(parent, position, value, fontSize, fontWeight, foreground, background)
  control = uicontrol(parent, 'Style', 'text', 'Units', 'normalized', ...
      'Position', position, 'String', value, 'HorizontalAlignment', 'left', ...
      'FontSize', fontSize, 'FontWeight', fontWeight, ...
      'ForegroundColor', foreground, 'BackgroundColor', background);
end

% -------------------------------------------------------------------------
function hmiSection(parent, y, value, colors)
  hmiText(parent, [0.04 y 0.92 0.027], value, 8, 'bold', colors.accent, colors.panel);
end

% -------------------------------------------------------------------------
function queueHMIPulse(source, fieldName)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.(fieldName) = true;
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function queueHMIStop(source, ~)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.stopPending = true;
  state.autoStartPending = false;
  state = releaseHMIKeys(state);
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function queueHMIReset(source, ~)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.resetPending = true;
  state.autoStartPending = false;
  state = releaseHMIKeys(state);
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function toggleHMIEStop(source, ~)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.eStop = logical(get(source, 'Value'));
  if state.eStop
      state.autoStartPending = false;
      state = releaseHMIKeys(state);
      set(source, 'String', 'E-STOP ACTIVO');
  else
      set(source, 'String', 'E-STOP');
  end
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function toggleHMIMode(source, ~)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.modeAutoReq = logical(get(source, 'Value'));
  if state.modeAutoReq
      state = releaseHMIKeys(state);
      set(source, 'String', 'PEDIR MANUAL');
  else
      state.autoStartPending = false;
      set(source, 'String', 'PEDIR AUTO');
  end
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function hmiKeyPress(fig, event)
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  if isEditingHMITarget(fig), return; end
  key = lower(string(event.Key));
  if ~any(key == ["leftarrow","rightarrow","uparrow","downarrow"]), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.(['key' keyName(key)]) = true;
  state.lastKeyEvent = now;
  state.modeAutoReq = false;
  state.autoStartPending = false;
  state = calculateHMIKeyCommands(state);
  modeButton = findobj(fig, 'Tag', 'HMIModeButton');
  if ~isempty(modeButton)
      set(modeButton(1), 'Value', 0, 'String', 'PEDIR AUTO');
  end
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function hmiKeyRelease(fig, event)
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  key = lower(string(event.Key));
  if ~any(key == ["leftarrow","rightarrow","uparrow","downarrow"]), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.(['key' keyName(key)]) = false;
  state.lastKeyEvent = now;
  state = calculateHMIKeyCommands(state);
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function name = keyName(key)
  switch key
      case "leftarrow",  name = 'Left';
      case "rightarrow", name = 'Right';
      case "uparrow",    name = 'Up';
      otherwise,         name = 'Down';
  end
end

% -------------------------------------------------------------------------
function editing = isEditingHMITarget(fig)
  editing = false;
  control = get(fig, 'CurrentObject');
  if isempty(control) || ~isgraphics(control), return; end
  try
      editing = strcmp(get(control, 'Type'), 'uicontrol') && ...
          strcmp(get(control, 'Style'), 'edit');
  catch
      editing = false;
  end
end

% -------------------------------------------------------------------------
function state = calculateHMIKeyCommands(state)
  state.keyboardTrolley = state.keyboardCommandValue * ...
      (double(state.keyRight) - double(state.keyLeft));
  state.keyboardHoist = state.keyboardCommandValue * ...
      (double(state.keyUp) - double(state.keyDown));
end

% -------------------------------------------------------------------------
function state = releaseHMIKeys(state)
  state.keyLeft = false;
  state.keyRight = false;
  state.keyUp = false;
  state.keyDown = false;
  state.keyboardTrolley = 0.0;
  state.keyboardHoist = 0.0;
end

% -------------------------------------------------------------------------
function toggleHMITwistlock(source, ~)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  state.twistlockCloseReq = logical(get(source, 'Value'));
  state.twistPulsePending = true;
  if state.twistlockCloseReq
      set(source, 'String', 'ABRIR TLK');
  else
      set(source, 'String', 'CERRAR TLK');
  end
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function applyHMISlot(source, ~)
  fig = ancestor(source, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  panel = ancestor(source, 'uipanel');
  editControl = findobj(panel, 'Tag', 'HMISlotEdit');
  yEditControl = findobj(panel, 'Tag', 'HMITargetYEdit');
  statusControl = findobj(panel, 'String', 'Edicion disponible solo en MANUAL');
  if ~state.manualEnabled
      if ~isempty(statusControl), set(statusControl(1), 'String', 'Bloqueado: el modo efectivo no es MANUAL'); end
      return;
  end
  requestedSlot = str2double(get(editControl(1), 'String'));
  requestedY = state.targetY; % Solo lectura: la calcula el supervisor.
  isInteger = isfinite(requestedSlot) && requestedSlot == round(requestedSlot);
  isInRange = isInteger && requestedSlot >= 1 && requestedSlot <= numel(state.xCenters);
  isYValid = true;
  if ~isInRange || ~isYValid
      set(editControl(1), 'String', sprintf('%d', state.targetSlot));
      set(yEditControl(1), 'String', sprintf('%.2f', state.targetY));
      return;
  end
  requestedSlot = round(requestedSlot);
  if state.slotBlock(requestedSlot)
      set(editControl(1), 'String', sprintf('%d', state.targetSlot));
      return;
  end
  state.targetSlot = requestedSlot;
  state.targetX = state.xCenters(requestedSlot);
  state.targetY = requestedY;
  state.targetPending = true;
  % Un objetivo nuevo prepara un ciclo nuevo, pero no lo inicia.
  state.autoStartPending = false;
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function publishHMICommands(block, h)
  if ~isfield(h, 'hmi') || ~ishandle(h.hmi.panel), return; end
  fig = ancestor(h.hmi.panel, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  if (state.keyboardTrolley ~= 0.0 || state.keyboardHoist ~= 0.0) && ...
          (now - state.lastKeyEvent) * 86400.0 > 1.5
      state = releaseHMIKeys(state);
  end
  block.OutputPort(1).Data = double(state.startPending);
  block.OutputPort(2).Data = double(state.stopPending);
  block.OutputPort(3).Data = double(state.eStop);
  block.OutputPort(4).Data = double(state.surveyPending);
  block.OutputPort(5).Data = double(state.targetSlot);
  block.OutputPort(6).Data = double(state.targetX);
  block.OutputPort(7).Data = double(state.targetY);
  block.OutputPort(8).Data = double(state.targetPending);
  block.OutputPort(9).Data = double(state.modeAutoReq);
  block.OutputPort(10).Data = double(state.autoStartPending);
  block.OutputPort(11).Data = double(state.resetPending);
  block.OutputPort(12).Data = double(state.twistPulsePending);
  block.OutputPort(13).Data = double(~state.twistlockCloseReq);
  block.OutputPort(14).Data = double(state.keyboardTrolley);
  block.OutputPort(15).Data = double(state.keyboardHoist);
  setappdata(fig, 'CraneHMIState', state);
end

% -------------------------------------------------------------------------
function updateHMIPanel(h, block, xt, xl, yl, tlk)
  if ~isfield(h, 'hmi') || ~ishandle(h.hmi.panel), return; end
  ui = h.hmi;
  fig = ancestor(ui.panel, 'figure');
  if isempty(fig) || ~isappdata(fig, 'CraneHMIState'), return; end
  state = getappdata(fig, 'CraneHMIState');
  colors = ui.colors;

  modeCode = round(block.InputPort(10).Data);
  contact = block.InputPort(11).Data > 0.5;
  estimatedMass = block.InputPort(12).Data;
  massValid = block.InputPort(13).Data > 0.5;
  antisway = block.InputPort(14).Data > 0.5;
  brakeTrolleyOpen = block.InputPort(15).Data > 0.5;
  brakeHoistOpen = block.InputPort(16).Data > 0.5;
  brakeEmergencyOpen = block.InputPort(17).Data > 0.5;
  emergency = block.InputPort(22).Data > 0.5;
  overload = block.InputPort(23).Data > 0.5;
  limitXMin = block.InputPort(24).Data > 0.5;
  limitXMax = block.InputPort(25).Data > 0.5;
  limitYMin = block.InputPort(26).Data > 0.5;
  limitYMax = block.InputPort(27).Data > 0.5;
  collision = block.InputPort(28).Data > 0.5;
  watchdogFault = block.InputPort(29).Data > 0.5;
  ultimateXMin = block.InputPort(31).Data > 0.5;
  ultimateXMax = block.InputPort(32).Data > 0.5;
  ultimateYMin = block.InputPort(33).Data > 0.5;
  ultimateYMax = block.InputPort(34).Data > 0.5;

  modeLabels = {'APAGADO','ARRANQUE','LISTO','MANUAL', ...
      'AUTOMATICO','PARADA','FALLA','TRANSICION A MANUAL','TRANSICION A AUTO','BARRIDO LIDAR'};
  if modeCode >= 0 && modeCode <= 9
      modeLabel = modeLabels{modeCode + 1};
  else
      modeLabel = sprintf('DESCONOCIDO (%d)', modeCode);
  end
  activeModeBox = 0;
  if modeCode == 0
      activeModeBox = 1;
  elseif modeCode == 3
      activeModeBox = 2;
  elseif modeCode == 4
      activeModeBox = 3;
  elseif any(modeCode == [5 6])
      activeModeBox = 4;
  end
  if emergency, activeModeBox = 4; end
  setModeBoxes(ui.modeBoxes, activeModeBox, colors);
  if emergency
      set(ui.system, 'String', 'Sistema detenido por emergencia');
  elseif modeCode == 6
      set(ui.system, 'String', 'Sistema retenido por falla');
  elseif modeCode == 1
      set(ui.system, 'String', 'Inicializando sistema');
  elseif modeCode == 2
      set(ui.system, 'String', 'Sistema listo');
  elseif any(modeCode == [7 8])
      set(ui.system, 'String', 'Confirmando modo solicitado');
  elseif modeCode == 5
      set(ui.system, 'String', 'Deteniendo sistema');
  else
      set(ui.system, 'String', ['Sistema operativo - ' modeLabel]);
  end

  state.manualEnabled = (modeCode == 3);
  state.effectiveModeCode = modeCode;
  targetEnable = ternaryText(state.manualEnabled, 'on', 'off');
  set(ui.slotEdit, 'Enable', targetEnable);
  set(ui.targetYEdit, 'Enable', 'on', 'String', sprintf('%.2f', double(block.InputPort(36).Data)));
  state.targetY = double(block.InputPort(36).Data);
  if modeCode == 4, state.autoStartPending = false; end
  set(ui.applySlot, 'Enable', targetEnable);
  if state.manualEnabled
      set(ui.targetStatus, 'String', 'Edicion habilitada - ingrese un slot operable');
  else
      set(ui.targetStatus, 'String', 'Edicion disponible solo en MANUAL');
  end
  set(ui.target, 'String', sprintf('Slot %d  ->  X: %.2f m  |  Y: %.2f m', ...
      state.targetSlot, state.targetX, state.targetY));
  setappdata(fig, 'CraneHMIState', state);

  set(ui.position, 'String', sprintf('Carro x_t: %7.2f m  |  Carga (x,y): (%7.2f, %7.2f) m', xt, xl, yl));
  if ~isfinite(estimatedMass)
      set(ui.mass, 'String', 'Masa estimada: -- t  [RESERVA NO CONECTADA]');
  elseif massValid
      set(ui.mass, 'String', sprintf('Masa estimada: %.2f t  [VALIDA]', estimatedMass/1000.0));
  else
      set(ui.mass, 'String', sprintf('Masa estimada: %.2f t  [NO VALIDA]', estimatedMass/1000.0));
  end

  setStatusLabel(ui.tlk, tlk > 0.5, 'TLK: CERRADO', 'TLK: ABIERTO', colors);
  % Mostrar la accion disponible segun el estado real, no la orden rechazada.
  set(ui.twistlockButton, 'Value', double(tlk > 0.5), ...
      'String', ternaryText(tlk > 0.5, 'ABRIR TLK', 'CERRAR TLK'));
  setStatusLabel(ui.contact, contact, 'CONTACTO: SI', 'CONTACTO: NO', colors);
  setStatusLabel(ui.antisway, antisway, 'ANTISWAY: ACTIVO', 'ANTISWAY: INACTIVO', colors);
  set(ui.brakes, 'String', sprintf('Frenos  Carro: %s  Izaje: %s  Emerg.: %s', ...
      brakeText(brakeTrolleyOpen), brakeText(brakeHoistOpen), brakeText(brakeEmergencyOpen)));

  faults = {};
  if overload, faults{end+1} = 'SOBRECARGA'; end
  if limitXMin, faults{end+1} = 'FIN DE CARRERA X MIN'; end
  if limitXMax, faults{end+1} = 'FIN DE CARRERA X MAX'; end
  if limitYMin, faults{end+1} = 'FIN DE CARRERA Y MIN'; end
  if limitYMax, faults{end+1} = 'FIN DE CARRERA Y MAX'; end
  if ultimateXMin, faults{end+1} = 'LIMITE ULTIMO X MIN'; end
  if ultimateXMax, faults{end+1} = 'LIMITE ULTIMO X MAX'; end
  if ultimateYMin, faults{end+1} = 'LIMITE ULTIMO Y MIN'; end
  if ultimateYMax, faults{end+1} = 'LIMITE ULTIMO Y MAX'; end
  % Mensaje de colision oculto por solicitud del ensayo.
  if emergency, faults{end+1} = 'PARADA DE EMERGENCIA'; end
  if watchdogFault, faults{end+1} = 'WATCHDOG'; end
  if block.InputPort(39).Data > 0.5, faults{end+1} = 'ERROR DE SEGUIMIENTO'; end
  if block.InputPort(40).Data ~= 0, faults{end+1} = sprintf('FALLA SUPERVISOR %g', double(block.InputPort(40).Data)); end
  if block.InputPort(38).Data > 0.5
      set(ui.targetStatus, 'String', 'BARRIDO LIDAR EN CURSO');
  elseif block.InputPort(37).Data < 0.5
      set(ui.targetStatus, 'String', 'PERFIL SIN RELEVAR - solicitar relevamiento');
  end
  if isempty(faults)
      faults = {'Sin fallas activas'};
      set(ui.faults, 'ForegroundColor', colors.text);
  else
      set(ui.faults, 'ForegroundColor', [1.0 0.55 0.55]);
  end
  % Canal conservado en los datos; no se muestra en el alarmero.
  set(ui.faults, 'String', faults);
end

% -------------------------------------------------------------------------
function setStatusLabel(control, active, activeText, inactiveText, colors)
  if active
      set(control, 'String', activeText, 'BackgroundColor', colors.ok);
  else
      set(control, 'String', inactiveText, 'BackgroundColor', colors.inactive);
  end
end

% -------------------------------------------------------------------------
function setModeBoxes(boxes, activeIndex, colors)
  for index = 1:numel(boxes)
      if index == activeIndex
          if index == 4
              background = colors.alarm;
          else
              background = colors.ok;
          end
      else
          background = colors.inactive;
      end
      set(boxes(index), 'BackgroundColor', background);
  end
end

function value = ternaryText(condition, whenTrue, whenFalse)
  if condition, value = whenTrue; else, value = whenFalse; end
end

function value = brakeText(isOpen)
  value = ternaryText(isOpen, 'LIBRE', 'APLICADO');
end

function value = trolleyDirection(joy)
  if joy > 0.05, value = 'BARCO'; elseif joy < -0.05, value = 'MUELLE'; else, value = 'NEUTRO'; end
end

function value = hoistDirection(joy)
  if joy > 0.05, value = 'SUBIR'; elseif joy < -0.05, value = 'BAJAR'; else, value = 'NEUTRO'; end
end

function messages = limitMessages(xMin, xMax, yMin, yMax, isUltimate)
  messages = {};
  prefix = ternaryText(isUltimate, 'ULT ', '');
  if xMin, messages{end+1} = [prefix 'X MIN']; end
  if xMax, messages{end+1} = [prefix 'X MAX']; end
  if yMin, messages{end+1} = [prefix 'Y MIN']; end
  if yMax, messages{end+1} = [prefix 'Y MAX']; end
end

% -------------------------------------------------------------------------
function Terminate(~)
end

% =========================================================================
% FUNCIONES AUXILIARES DE DIBUJO
% =========================================================================
function drawStaticCrane(ax, geo)
  craneColor = [0.00 0.62 0.78];   
  craneLight = [0.28 0.82 0.95];   
  craneDark  = [0.00 0.32 0.45];   
  steel      = [0.18 0.18 0.18];
  rail       = [0.10 0.10 0.10];
  xLS = geo.xLS; xWS = geo.xWS; y0 = 0; yG = geo.Yt0; yT = geo.Ytop;
  xBoomL = geo.xBoomL; xBoomR = geo.xBoomR; xTower = xWS - 7.5;
  
  drawBogie(ax, xLS, y0, craneColor, steel, craneDark);
  drawBogie(ax, xWS, y0, craneColor, steel, craneDark);
  
  patch(ax, xLS + [-1.7 1.7 1.05 -1.05], [0 0 yG-1.2 yG-1.2], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.2);
  patch(ax, xWS + [-1.55 1.55 1.00 -1.00], [0 0 yG-1.2 yG-1.2], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.2);
  patch(ax, [xLS-3.0, xWS+2.0, xWS+2.0, xLS-3.0], [15.0 15.0 17.0 17.0], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.0);
  patch(ax, [xLS-2.0, xWS+1.2, xWS+1.2, xLS-2.0], [29.0 29.0 31.0 31.0], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.0);
  
  % El portico inferior se representa solamente con pilares y vigas
  % horizontales; se eliminan los arriostramientos diagonales marcados.
  
  patch(ax, [xBoomL xBoomR xBoomR xBoomL], [yG-1.2 yG-1.2 yG+0.15 yG+0.15], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.2);
  patch(ax, [xBoomL xBoomR xBoomR xBoomL], [yG+0.45 yG+0.45 yG+1.10 yG+1.10], craneLight, 'EdgeColor', craneDark, 'LineWidth', 0.9);
  plot(ax, [xBoomL xBoomR], [yG yG], '-', 'Color', rail, 'LineWidth', 2.0);
  patch(ax, [xBoomR-5 xBoomR xBoomR xBoomR-5], [yG-1.2 yG-0.8 yG+0.4 yG+0.15], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.0);
  
  patch(ax, xTower + [-1.1 1.1 0.65 -0.65], [yG-1.2 yG-1.2 yT yT], craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.2);
  patch(ax, xTower + [-2.0 2.0 2.0 -2.0], [yT-0.2 yT-0.2 yT+1.0 yT+1.0], craneLight, 'EdgeColor', craneDark, 'LineWidth', 1.0);
  drawMember(ax, xBoomL+8.0, yG+0.6, xTower-0.6, yT-0.1, 0.55, craneColor, craneDark);
  drawMember(ax, xTower+0.7, yT-0.1, xWS+0.5,   yG+0.2, 0.55, craneColor, craneDark);
  
  % Tensores principales: uno hacia la punta de la pluma y otro hacia el
  % contrapeso. Se omiten los dos tirantes intermedios para evitar el
  % entramado cruzado y dar a la silueta una apariencia STS mas realista.
  tensorColor = craneDark;
  plot(ax, [xTower, xBoomR-3], [yT+0.3, yG+0.4], '-', ...
      'Color', tensorColor, 'LineWidth', 1.3);
  plot(ax, [xTower, xBoomL+3], [yT+0.1, yG+0.5], '-', ...
      'Color', tensorColor, 'LineWidth', 1.2);
  
  hMachine = patch(ax, nan, nan, craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.1);
  setPatchRect(hMachine, xBoomL+2.0, yG+1.0, 11.0, 5.8);
  hVent = patch(ax, nan, nan, [0.12 0.12 0.12], 'EdgeColor', 'k', 'LineWidth', 0.8);
  setPatchRect(hVent, xBoomL+3.0, yG+2.2, 2.0, 2.6);
  hWindow = patch(ax, nan, nan, [0.35 0.55 0.65], 'EdgeColor', 'k', 'LineWidth', 0.7);
  setPatchRect(hWindow, xBoomL+9.0, yG+3.2, 1.1, 1.2);
  
  drawRailing(ax, xBoomL+1, xBoomR-2, yG+1.25, 1.1);
  drawRailing(ax, xLS-4.0, xWS+4.0, 17.2, 1.0);
  drawRailing(ax, xTower-2.0, xTower+2.0, yT+1.05, 1.0);
  drawLadder(ax, xLS-2.7, 3.0, yG+0.5);
  drawLadder(ax, xTower+1.2, yG+1.0, yT+0.5);
  drawSheaveStatic(ax, xBoomL+1.0, yG+0.2, 0.55);
  drawSheaveStatic(ax, xBoomR-1.0, yG+0.2, 0.55);
  plot(ax, [xBoomL+1, xBoomR-1], [yG+0.9, yG+0.9], '-', 'Color', [0.20 0.20 0.20], 'LineWidth', 0.9);
end

% -------------------------------------------------------------------------
function drawMember(ax, x1, y1, x2, y2, w, face, edge)
  dx = x2 - x1; dy = y2 - y1; L = hypot(dx, dy);
  if L < eps, return; end
  nx = -dy/L; ny =  dx/L;
  X = [x1+nx*w/2, x2+nx*w/2, x2-nx*w/2, x1-nx*w/2];
  Y = [y1+ny*w/2, y2+ny*w/2, y2-ny*w/2, y1-ny*w/2];
  patch(ax, X, Y, face, 'EdgeColor', edge, 'LineWidth', 0.8);
end

% -------------------------------------------------------------------------
function drawBogie(ax, xc, y0, craneColor, steel, craneDark)
  hBase = patch(ax, nan, nan, craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.0);
  setPatchRect(hBase, xc-2.4, y0+0.6, 4.8, 1.6);
  hTop = patch(ax, nan, nan, craneColor, 'EdgeColor', craneDark, 'LineWidth', 1.0);
  setPatchRect(hTop, xc-1.6, y0+2.2, 3.2, 1.0);
  r = 0.42; wx = xc + [-1.55 -0.55 0.55 1.55];
  for k = 1:4
      rectangle(ax, 'Position', [wx(k)-r, y0+0.05, 2*r, 2*r], 'Curvature', [1 1], 'FaceColor', steel, 'EdgeColor', craneDark, 'LineWidth', 0.8);
  end
end

% -------------------------------------------------------------------------
function drawStaticShip(ax, ship)
  % Dibuja la bodega/casco del barco
  patch(ax, [ship.xLeft, ship.xRight, ship.xRight, ship.xLeft], ...
            [ship.yBase, ship.yBase, ship.yDeck, ship.yDeck], ...
            ship.faceColor, 'EdgeColor', ship.edgeColor, 'LineWidth', 1.5);
end

% -------------------------------------------------------------------------
function drawRailing(ax, x1, x2, y, h)
  plot(ax, [x1, x2], [y, y], 'k-', 'LineWidth', 0.8);
  plot(ax, [x1, x2], [y+h, y+h], 'k-', 'LineWidth', 0.8);
  step = 4.0;
  xs = x1:step:x2;
  for i = 1:length(xs)
      plot(ax, [xs(i), xs(i)], [y, y+h], 'k-', 'LineWidth', 0.6);
  end
end

% -------------------------------------------------------------------------
function drawLadder(ax, x, y1, y2)
  plot(ax, [x-0.2, x-0.2], [y1, y2], 'k-', 'LineWidth', 0.8);
  plot(ax, [x+0.2, x+0.2], [y1, y2], 'k-', 'LineWidth', 0.8);
  ys = y1:0.4:y2;
  for i = 1:length(ys)
      plot(ax, [x-0.2, x+0.2], [ys(i), ys(i)], 'k-', 'LineWidth', 0.6);
  end
end

% -------------------------------------------------------------------------
function drawSheaveStatic(ax, xc, yc, r)
  rectangle(ax, 'Position', [xc-r, yc-r, 2*r, 2*r], 'Curvature', [1 1], 'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
end

% -------------------------------------------------------------------------
% FUNCIONES DE UTILIDAD EXTRA (Aseguran que no falle la compilación)
% -------------------------------------------------------------------------
function setPatchRect(hPatch, x, y, w, h)
  % Modifica de forma rápida las esquinas de un objeto patch rectangular
  set(hPatch, 'XData', [x, x+w, x+w, x], 'YData', [y, y, y+h, y+h]);
end

% -------------------------------------------------------------------------
function updateCarriedContainer(h, x, y, geo, visible, alpha)
  visibility = ternaryText(visible, 'on', 'off');
  setPatchRect(h.container, x, y, geo.Wc, geo.Hc - 0.05);
  set(h.container, 'Visible', visibility, 'FaceAlpha', alpha);
end

% -------------------------------------------------------------------------
function value = formatSimulationTime(t)
  minutes = floor(max(0.0, t)/60.0);
  seconds = max(0.0, t) - 60.0*minutes;
  value = sprintf('SIMULACIÓN  %02d:%04.1f', minutes, seconds);
end
