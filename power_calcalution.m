clc; clear; close all;

%% --- Simulation setup (unchanged) -----------------------
MODEL_NAME   = 'PFC_PID_Control_2_';
SIM_DURATION = 0.1;
STEP_SIZE    = 1e-6;

open_system(MODEL_NAME);
set_param(MODEL_NAME,'StopTime',num2str(SIM_DURATION),'SolverType','Fixed-step',...
          'FixedStep',num2str(STEP_SIZE),'ReturnWorkspaceOutputs','on');

fprintf("\n Created by Kesava D Raj\n");
fprintf('\n>>> Running simulation ...\n');
simOut = sim(MODEL_NAME);
fprintf('>>> Done.\n\n');

t      = simOut.tout;
Vout   = simOut.pfc_Vout(:);
iL     = simOut.pfc_iL(:);
iref   = simOut.pfc_iref(:);
Vs     = simOut.pfc_Vs(:);
Verror = simOut.pfc_Verror(:);
Ierror = simOut.pfc_Ierror(:);
Vpid   = simOut.pfc_Vpid(:);
Ipid   = simOut.pfc_Ipid(:);

%% --- Parameters -----------------------------------------
Vs_pk    = 325.27; f_line = 50; f_sw = 100e3;
L_boost  = 1e-3;   C_out  = 470e-6;
R_load   = 200;    Vout_ref = 400;
Kpv=0.15; Kiv=8.0; Kdv=0.0; Nv=10;
Kpc=2.5;  Kic=500; Kdc=0.0; Nc=1000;

%% --- Steady-state window --------------------------------
ss = t >= SIM_DURATION - 2/f_line;
t_ss   = t(ss);   Vs_ss  = Vs(ss);
iL_ss  = iL(ss);  Vout_ss = Vout(ss);

%% --- Power quality metrics ------------------------------
N_pts  = length(t_ss);
Fs_eff = 1/mean(diff(t_ss));
f_vec  = (0:N_pts-1)*Fs_eff/N_pts;
I_fft  = fft(iL_ss)/N_pts;
V_fft  = fft(Vs_ss)/N_pts;
[~,f1] = min(abs(f_vec - f_line));
phi    = angle(V_fft(f1)) - angle(I_fft(f1));
DPF    = cos(phi);
Irms   = sqrt(mean(iL_ss.^2));
I1_rms = 2*abs(I_fft(f1))/sqrt(2);
THD_i  = sqrt(max(Irms^2 - I1_rms^2,0))/I1_rms*100;
PF     = (I1_rms/Irms)*DPF;
Vrip   = max(Vout_ss) - min(Vout_ss);
Vmean  = mean(Vout_ss);
Vereg  = abs(Vmean-Vout_ref)/Vout_ref*100;

fprintf('PF=%.4f  DPF=%.4f  THD=%.2f%%  Vrip=%.3fV  VErr=%.3f%%\n',...
        PF,DPF,THD_i,Vrip,Vereg);

%% --- Color palette (dark lines, white axes) -------------
C.navy   = [0.02  0.27  0.49];   % primary signal
C.steel  = [0.24  0.47  0.71];   % secondary signal
C.teal   = [0.06  0.43  0.32];   % voltage-loop
C.amber  = [0.39  0.31  0.04];   % current-loop / ref
C.crimson= [0.63  0.11  0.11];   % reference dashed lines
C.gray   = [0.45  0.45  0.45];   % zero lines
LW=2.0; LWr=1.3; FSt=11; FSl=9;

applyAx = @(ax,xl,yl) set(ax,...
    'Color','white',...
    'XColor',[0.2 0.2 0.2],'YColor',[0.2 0.2 0.2],...
    'GridColor',[0.78 0.78 0.78],'GridAlpha',1,...
    'MinorGridAlpha',0.4,'Box','off',...
    'FontSize',FSl,'LineWidth',0.6,...
    'TickDir','out','XLabel',xlabel(ax,xl,'FontSize',FSl),...
    'YLabel',ylabel(ax,yl,'FontSize',FSl));

fig = figure('Name','PFC Boost Converter — Dual-Loop PID',...
    'Color','white','NumberTitle','off',...
    'Units','normalized','Position',[0.03 0.04 0.94 0.88]);

tg   = uitabgroup(fig,'Units','normalized','Position',[0 0 1 1]);
tab1 = uitab(tg,'Title','  Page 1 — Waveforms  ','BackgroundColor','white');
tab2 = uitab(tg,'Title','  Page 2 — Analysis  ', 'BackgroundColor','white');

%% =========================================================
%  PAGE 1  |  2×2 grid — waveform plots
% =========================================================

% ── Plot 1 : DC Output Voltage ───────────────────────────
ax1 = subplot(2,2,1,'Parent',tab1);
plot(ax1, t*1e3, Vout, 'Color',C.navy,   'LineWidth',LW); hold(ax1,'on');
plot(ax1, t*1e3, repmat(Vout_ref,size(t)), '--','Color',C.crimson,'LineWidth',LWr);
hold(ax1,'off');
ylim(ax1,[0 Vout_ref*1.2]);
legend(ax1,{'V_{out}','Ref 400 V'},'FontSize',FSl,'Location','southeast');
title(ax1,'① DC Output Voltage','FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax1,'Time  (ms)','V_{out}  (V)'); grid(ax1,'on');
text(ax1,0.03,0.09,sprintf('Mean = %.2f V   Reg. err = %.3f %%',Vmean,Vereg),...
    'Units','normalized','FontSize',8,'Color',C.navy,...
    'BackgroundColor',[0.92 0.95 1.00],'Margin',3);

% ── Plot 2 : Inductor Current Tracking ──────────────────
ax2 = subplot(2,2,2,'Parent',tab1);
plot(ax2, t*1e3, iref, '--','Color',C.amber, 'LineWidth',LWr,'DisplayName','i_{ref}'); hold(ax2,'on');
plot(ax2, t*1e3, iL,        'Color',C.navy,  'LineWidth',LW,  'DisplayName','i_L');
hold(ax2,'off');
legend(ax2,'FontSize',FSl,'Location','best');
title(ax2,'② Inductor Current Tracking','FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax2,'Time  (ms)','Current  (A)'); grid(ax2,'on');
text(ax2,0.03,0.09,sprintf('Kp=%.1f  Ki=%.0f  Kd=%.1f',Kpc,Kic,Kdc),...
    'Units','normalized','FontSize',8,'Color',C.amber,...
    'BackgroundColor',[1.00 0.97 0.89],'Margin',3);

% ── Plot 3 : AC Voltage & Shaped Current ────────────────
ax3 = subplot(2,2,3,'Parent',tab1);
yyaxis(ax3,'left');
plot(ax3, t_ss*1e3, Vs_ss,  'Color',C.teal, 'LineWidth',LW);
ylabel(ax3,'V_s  (V)','FontSize',FSl); ax3.YColor = C.teal;
ylim(ax3,[-Vs_pk*1.3 Vs_pk*1.3]);
yyaxis(ax3,'right');
plot(ax3, t_ss*1e3, iL_ss, 'Color',C.navy, 'LineWidth',LW);
ylabel(ax3,'i_L  (A)','FontSize',FSl); ax3.YColor = C.navy;
title(ax3, sprintf('③ AC Input V & I  |  PF = %.4f',PF),...
    'FontSize',FSt,'FontWeight','bold','Color','k');
xlabel(ax3,'Time  (ms)','FontSize',FSl);
set(ax3,'Color','white','GridColor',[0.78 0.78 0.78],'Box','off','FontSize',FSl);
grid(ax3,'on');
legend(ax3,{'V_s (left)','i_L (right)'},'FontSize',FSl,'Location','best');

% ── Plot 4 : Steady-State Ripple ────────────────────────
ax4 = subplot(2,2,4,'Parent',tab1);
plot(ax4, t_ss*1e3, Vout_ss,         'Color',C.navy,   'LineWidth',LW,  'DisplayName','V_{out}'); hold(ax4,'on');
plot(ax4, t_ss*1e3, repmat(Vout_ref,size(t_ss)),'--','Color',C.crimson,'LineWidth',LWr,'DisplayName','Target 400 V');
plot(ax4, t_ss*1e3, repmat(Vmean,size(t_ss)),   ':' ,'Color',C.teal,  'LineWidth',LWr,'DisplayName',sprintf('Mean %.2f V',Vmean));
hold(ax4,'off');
legend(ax4,'FontSize',FSl,'Location','best');
title(ax4,sprintf('④ Output Ripple  (pk-pk = %.3f V)',Vrip),...
    'FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax4,'Time  (ms)','V_{out}  (V)'); grid(ax4,'on');
text(ax4,0.03,0.09,sprintf('C=%g µF   R=%g Ω   f_{sw}=%g kHz',C_out*1e6,R_load,f_sw/1e3),...
    'Units','normalized','FontSize',8,'Color',C.navy,...
    'BackgroundColor',[0.92 0.95 1.00],'Margin',3);

%% =========================================================
%  PAGE 2  |  Harmonic + Errors + Duty cycles + Summary
% =========================================================

% ── Plot 5 : Harmonic Spectrum ───────────────────────────
ax5 = subplot(3,2,1,'Parent',tab2);
f_half = f_vec(1:floor(N_pts/2));
I_mag  = 2*abs(I_fft(1:floor(N_pts/2)));
stem(ax5, f_half, I_mag, 'filled','Color',C.navy,'MarkerSize',3,'LineWidth',0.9); hold(ax5,'on');
for hf = f_line*(1:2:15)
    xline(ax5,hf,'--','Color',C.amber,'LineWidth',0.9,'Alpha',0.8);
end; hold(ax5,'off');
xlim(ax5,[0 1000]);
legend(ax5,{'|I| spectrum','Odd harmonics'},'FontSize',FSl,'Location','northeast');
title(ax5,sprintf('⑤ Current Spectrum  |  THD = %.2f %%',THD_i),...
    'FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax5,'Frequency  (Hz)','|I|  (A)'); grid(ax5,'on');

% ── Plot 6 : Voltage Loop Error ─────────────────────────
ax6 = subplot(3,2,3,'Parent',tab2);
plot(ax6, t*1e3, Verror,'Color',C.teal,'LineWidth',LW); hold(ax6,'on');
yline(ax6,0,'--','Color',C.gray,'LineWidth',LWr,'Label','Zero error');
hold(ax6,'off');
title(ax6,'⑥ Voltage Loop Error  (V_{ref} − V_{out})',...
    'FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax6,'Time  (ms)','Error  (V)'); grid(ax6,'on');
text(ax6,0.03,0.09,sprintf('Kp=%.2f  Ki=%.1f  Kd=%.1f  N=%g',Kpv,Kiv,Kdv,Nv),...
    'Units','normalized','FontSize',8,'Color',C.teal,...
    'BackgroundColor',[0.88 1.00 0.95],'Margin',3);

% ── Plot 7 : Current Loop Error ─────────────────────────
ax7 = subplot(3,2,5,'Parent',tab2);
plot(ax7, t*1e3, Ierror,'Color',C.amber,'LineWidth',LW); hold(ax7,'on');
yline(ax7,0,'--','Color',C.gray,'LineWidth',LWr,'Label','Zero error');
hold(ax7,'off');
title(ax7,'⑦ Current Loop Error  (i_{ref} − i_L)',...
    'FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax7,'Time  (ms)','Error  (A)'); grid(ax7,'on');
text(ax7,0.03,0.09,sprintf('Kp=%.1f  Ki=%.0f  Kd=%.1f  N=%g',Kpc,Kic,Kdc,Nc),...
    'Units','normalized','FontSize',8,'Color',C.amber,...
    'BackgroundColor',[1.00 0.97 0.89],'Margin',3);

% ── Plot 8 : PID Duty Cycles ────────────────────────────
ax8 = subplot(3,2,[2 4],'Parent',tab2);
plot(ax8, t*1e3, Vpid,'Color',C.navy,  'LineWidth',LW, 'DisplayName','Voltage PID'); hold(ax8,'on');
plot(ax8, t*1e3, Ipid,'Color',C.steel, 'LineWidth',LW, 'DisplayName','Current PID');
yline(ax8,0,':','Color',C.gray,'LineWidth',0.8);
yline(ax8,1,':','Color',C.gray,'LineWidth',0.8);
hold(ax8,'off');
ylim(ax8,[0.0 1.0]);
legend(ax8,'FontSize',FSl,'Location','best');
title(ax8,'⑧ PID Controller Outputs — Duty Cycles',...
    'FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax8,'Time  (ms)','Duty cycle  (–)'); grid(ax8,'on');

% ── Plot 9 : Performance Summary Bar ────────────────────
ax9 = subplot(3,2,6,'Parent',tab2);
mv = [PF, DPF, THD_i/100, 1-Vereg/100];
mc = [C.navy; C.teal; C.amber; [0.24 0.15 0.38]];
ml = {'True PF','Disp. PF','THD÷100','Volt. Reg.'};
b  = bar(ax9, mv,'FaceColor','flat','EdgeColor','none','BarWidth',0.65);
for k=1:4,  b.CData(k,:) = mc(k,:);  end
set(ax9,'XTickLabel',ml,'FontSize',FSl);
yline(ax9,1,'--','Color',C.gray,'LineWidth',1.0,'Label','Ideal');
ylim(ax9,[0 1.22]); grid(ax9,'on');
for k=1:4
    text(ax9,k,mv(k)+0.04,sprintf('%.4f',mv(k)),...
        'HorizontalAlignment','center','FontSize',8,'FontWeight','bold','Color',mc(k,:));
end
if THD_i<8
    text(ax9,0.5,0.06,'IEC 61000-3-2:  PASS (THD < 8%)',...
        'Units','normalized','FontSize',8,'FontWeight','bold',...
        'Color',[0.05 0.40 0.15],'BackgroundColor',[0.88 1.00 0.88],'Margin',3);
else
    text(ax9,0.5,0.06,'IEC 61000-3-2:  FAIL (THD >= 8%)',...
        'Units','normalized','FontSize',8,'FontWeight','bold',...
        'Color',[0.55 0.05 0.05],'BackgroundColor',[1.00 0.88 0.88],'Margin',3);
end
title(ax9,'⑨ PFC Performance Summary','FontSize',FSt,'FontWeight','bold','Color','k');
applyAx(ax9,'Metric','Normalised value');

%% --- Utility --------------------------------------------
function out = ternary(c,a,b)
    if c, out=a; else, out=b; end
end