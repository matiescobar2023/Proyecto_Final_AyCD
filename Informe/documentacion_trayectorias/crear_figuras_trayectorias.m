function crear_figuras_trayectorias
% Ejemplo del planificador existente, sin simulacion de planta.
root='C:/Users/tinch/OneDrive/Desktop/overhead crane - local/chatgpt/OCTUBRE/Informe_Combinado_07102026/Informe_Proyecto_Grua';
a=[root '/documentacion_trayectorias'];out=[root '/imagenes_informe/trayectorias'];addpath(a);
D=readtable([root '/documentacion_prueba_completa_CODESYS/perfiles.csv']);profile=D.relevado_m';profile(6)=profile(6)-2.59;
x0=-16.58;xf=24.9;y0=15;yf=.85;mass=50990;Ts=.001;
clear generador_ejemplo_informe
[~,~,~,~,~,~,P]=generador_ejemplo_informe(true,false,x0,0,0,y0,0,0,xf,yf,profile,mass,true,0,0,Ts);
assert(P.validPlan,'El plan es inviable');T=max(P.xDuration,P.yDownStart+P.yDownDuration);t=unique([linspace(0,T,6001),P.xCoef(5),P.xDuration-P.xCoef(5),P.xDuration,P.yUpDuration,P.yDownStart])';
N=numel(t);x=zeros(N,1);v=x;acc=x;jx=x;y=x;vy=x;ay=x;jy=x;
for k=1:N
 [x(k),v(k),acc(k)]=evaluateCruiseProfile(P.xCoef,t(k),P.xDuration);
 if t(k)<P.xCoef(5),jx(k)=.5*P.xCoef(4)*pi^2/P.xCoef(5)^2*cos(pi*t(k)/P.xCoef(5));
 elseif t(k)>P.xDuration-P.xCoef(5) && t(k)<P.xDuration,jx(k)=-.5*P.xCoef(4)*pi^2/P.xCoef(5)^2*cos(pi*(t(k)-P.xDuration+P.xCoef(5))/P.xCoef(5));end
 if t(k)<P.yDownStart
  [y(k),vy(k),ay(k)]=evaluateQuintic(P.yUpCoef,t(k),P.yUpDuration);if t(k)<P.yUpDuration,jy(k)=evaluateJerk(P.yUpCoef,t(k),P.yUpDuration);end;
 else
  [y(k),vy(k),ay(k)]=evaluateQuintic(P.yDownCoef,t(k)-P.yDownStart,P.yDownDuration);if t(k)-P.yDownStart<P.yDownDuration,jy(k)=evaluateJerk(P.yDownCoef,t(k)-P.yDownStart,P.yDownDuration);end;
 end
end
limitsX=[NaN 2.5 .3 .5];limitsY=[NaN P.vyMax .25 .1];
sets={ [x v acc jx],[y vy ay jy] };units={'Posición [m]','Velocidad [m/s]','Aceleración [m/s^2]','Jerk [m/s^3]'};
for axisIndex=1:2
 f=figure('Visible','off','Color','w','Position',[60 60 1100 1000]);tl=tiledlayout(f,4,1,'TileSpacing','compact','Padding','compact');
 if axisIndex==1,lim=limitsX;st=[0 P.xCoef(5) P.xDuration-P.xCoef(5) P.xDuration T];names={'Aceleración','Crucero','Frenado','Retención'};else,lim=limitsY;st=[0 P.yUpDuration P.yDownStart T];names={'Ascenso','Altura de cruce','Descenso'};end
 for row=1:4
  ax=nexttile(tl);hold(ax,'on');plot(ax,t,sets{axisIndex}(:,row),'Color',[.05 .35 .7],'LineWidth',1.5);grid(ax,'on');xlim(ax,[0 T]);ylabel(ax,units{row});set(ax,'FontSize',13,'FontName','Arial');
  if row>1,yline(ax,lim(row),'--','Límite','Color',[.5 .5 .5],'HandleVisibility','off');yline(ax,-lim(row),'--','Color',[.5 .5 .5],'HandleVisibility','off');ylim(ax,1.15*[-lim(row) lim(row)]);end
  for z=2:numel(st)-1,xline(ax,st(z),':','Color',[.55 .55 .55],'HandleVisibility','off');end
  if row==1
   values=sets{axisIndex}(:,row);span=max(values)-min(values);ylim(ax,[min(values)-.08*span max(values)+.22*span]);
   yy=ylim(ax);for z=1:numel(names),if st(z+1)-st(z)>.5,text(ax,(st(z)+st(z+1))/2,yy(2)-.07*diff(yy),names{z},'HorizontalAlignment','center','VerticalAlignment','top','FontSize',11,'BackgroundColor','w');end;end
  end
  if row==4,xlabel(ax,'Tiempo desde el inicio del plan [s]');end
 end
 if axisIndex==1,name='perfil_horizontal';else,name='perfil_vertical';end
 exportgraphics(f,[out '/' name '.pdf'],'ContentType','vector');exportgraphics(f,[out '/' name '.png'],'Resolution',180);close(f);
end
base=y-P.cableStretch-2.59;
f=figure('Visible','off','Color','w','Position',[60 60 1150 650]);ax=axes(f);hold(ax,'on');
for k=1:33
 left=-30+(k-1)*2.44;right=left+2.44;
 if right>=x0-4 && left<=xf+4
  patch(ax,[left right right left],[-20 -20 profile(k) profile(k)],[.80 .82 .84],'EdgeColor','none','HandleVisibility','off');
  plot(ax,[left right],profile(k)*[1 1],'Color',[.3 .3 .3],'LineWidth',1.2,'HandleVisibility','off');
 end
end
h1=plot(ax,x,base,'Color',[.05 .35 .7],'LineWidth',2.3);required=zeros(size(x));for k=1:N,required(k)=maximumProfileBetween(profile,x(k),x(k))+2.59;end
h2=plot(ax,x,required,'--','Color',[.15 .55 .30],'LineWidth',1.5);
inst=[0 P.xDuration T];
for k=1:numel(inst)
 xx=interp1(t,x,inst(k));bb=interp1(t,base,inst(k));rectangle(ax,'Position',[xx-1.22 bb 2.44 2.59],'FaceColor',[1 .66 .28 .32],'EdgeColor',[.75 .35 .06],'LineWidth',1);
 if k==numel(inst),dx=3;else,dx=0;end
 text(ax,xx+dx,bb+3.5,sprintf('%.1f s',inst(k)),'HorizontalAlignment','center','FontSize',11,'BackgroundColor','w');
end
text(ax,x0,-17,'Origen: slot 6','HorizontalAlignment','center','FontSize',12);text(ax,xf,-17,'Destino: slot 23','HorizontalAlignment','center','FontSize',12);
legend(ax,[h1 h2],{'Base estimada del contenedor','Perfil bajo la envolvente + margen de 2,59 m'},'Location','northoutside','FontSize',11);
xlim(ax,[x0-4 xf+6]);ylim(ax,[-20 P.yClear+5]);grid(ax,'on');xlabel(ax,'Posición horizontal [m]');ylabel(ax,'Altura [m]');set(ax,'FontSize',13,'FontName','Arial');
exportgraphics(f,[out '/coordinacion_xy.pdf'],'ContentType','vector');exportgraphics(f,[out '/coordinacion_xy.png'],'Resolution',180);close(f);
metrics=struct('x0',x0,'xf',xf,'y0',y0,'yf',yf,'massKg',mass,'Ts',Ts,'durationS',T,'horizontalDurationS',P.xDuration,'rampS',P.xCoef(5),'upDurationS',P.yUpDuration,'downStartS',P.yDownStart,'downDurationS',P.yDownDuration,'crossingHeightM',P.yClear,'stretchM',P.cableStretch,'maxVX',max(abs(v)),'maxAX',max(abs(acc)),'maxJX',max(abs(jx)),'maxVY',max(abs(vy)),'maxAY',max(abs(ay)),'maxJY',max(abs(jy)),'vyLimit',P.vyMax,'minMarginTransportM',min(base(t<=P.xDuration)-required(t<=P.xDuration)));
fid=fopen([a '/ejemplo_trayectoria.json'],'w','n','UTF-8');fwrite(fid,jsonencode(metrics,PrettyPrint=true),'char');fclose(fid);
writetable(table(t,x,v,acc,jx,y,vy,ay,jy,base),[a '/referencias_ejemplo.csv']);disp(metrics);
end
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

