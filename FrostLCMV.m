close all; 
clear all; 

% This script is an attempt at implementing Otis Lamont Frost III's 1972
% algorithm for adaptive LCMV beamforming. 

plot_txt_size = 20;

% Constants
J = 4; % Number of delay taps
K = 4; % Number of sensors

F_curly = [1, -2, 1.5, 2]'; % The look direction filter
F_curly = F_curly/norm(F_curly);
mu = 0.073; % Step size
Fs = 1; % Sample rate
tau = 1; % The time taken for a sound wave to move directly from one sensor to the next

% Signals
sig_length = 10000; % Note that this is before sampling for observation
s1 = 0.5 * randn(sig_length,1); % Look direction signal
bpFilt = designfilt('bandpassfir', 'FilterOrder', 100, ...
             'CutoffFrequency1', 0.22, 'CutoffFrequency2', 0.28,...
             'SampleRate', 1);
s1 = filter(bpFilt,s1);
s2 = 0.5 * randn(sig_length,1); % Interferer #1
bpFilt = designfilt('bandpassfir', 'FilterOrder', 100, ...
             'CutoffFrequency1', 0.1, 'CutoffFrequency2', 0.12,...
             'SampleRate', 1);
s2 = filter(bpFilt,s2);
s3 = 0.5 * randn(sig_length,1); % Interferer #2
bpFilt = designfilt('bandpassfir', 'FilterOrder', 100, ...
             'CutoffFrequency1', 0.35, 'CutoffFrequency2', 0.4,...
             'SampleRate', 1);
s3 = filter(bpFilt,s3);
% figure; plot(s1); % hold on; plot(s2(100:200)); plot(s3(100:200)); 

% Create observations with delays and noise. Note that the sources are
% currently circularly shifted, is that a problem? 
noise_weight = 0.01; 
tau_1 = 0; % tau_x defines the delay in samples between two neighbouring sensors for signals 1, 2, 3. 
tau_2 = 5; 
tau_3 = 7; 
x1 = s1 + s2 + s3 + noise_weight * randn(length(s1), 1); 
x2 = s1 + s2([end-tau_2+1:end, 1:end-tau_2]) + s3([end-tau_3+1:end, 1:end-tau_3]) + noise_weight * randn(length(s1), 1); 
x3 = s1 + s2([end-2*tau_2+1:end, 1:end-2*tau_2]) + s3([end-2*tau_3+1:end, 1:end-2*tau_3]) + noise_weight * randn(length(s1), 1); 
x4 = s1 + s2([end-3*tau_2+1:end, 1:end-3*tau_2]) + s3([end-3*tau_3+1:end, 1:end-3*tau_3]) + noise_weight * randn(length(s1), 1); 
big_X = [x1, x2, x3, x4];
clear x1; clear x2; clear x3; clear x4; 
% figure; plot(big_X(100:200,1)); hold on; plot(big_X(100:200,2)); plot(big_X(100:200,3)); plot(big_X(100:200,4));

% Algorithm
C = zeros(16,4);
c = ones(4,1);
C(1:4,1) = c; C(5:8,2) = c; C(9:12,3) = c; C(13:16,4) = c;
F = C * inv(C'*C) * F_curly; 
W = F; 
P = eye(16) - C*inv(C'*C)*C';
Y = zeros(sig_length, 1); % The output from the beamformer; i.e. the estimate of the look direction signal. Initialized to zeros.
k = 1; 
X = [big_X(k+3,1:4), big_X(k+2,1:4), big_X(k+1,1:4), big_X(k,1:4)]';
Y(k) = W'*X;
% OutputPower = zeros(sig_length,1);
% W_norm = zeros(sig_length,1);
% Iteration
kk= 1;
for k = 2  : sig_length-3
    if mod(k, 10) == 0
        W = P * (W - mu * Y(k-1) * X) + F; 
        OutputPower(kk) = (Y(k-9:k))'*(Y(k-9:k));
        W_norm(kk) = norm(W);
        kk = kk + 1;
    end    
    X = [big_X(k+3,1:4), big_X(k+2,1:4), big_X(k+1,1:4), big_X(k,1:4)]';
    Y(k) = W'*X;
end

figure;
plot(Y(100:200));
hold on; 
plot(s1(100:200));
legend('Y', 's1');
set(gca,'fontsize',plot_txt_size); 
xlim([0, 100]);
xlabel('Sample number'); ylabel('Amplitude');

% Look direction filter response
figure;
freqz(F_curly,1);
set(gca,'fontsize',plot_txt_size); 

% Find the optimal weight vector using Rxx, the signal covariance
% Rxx = % How can I get a 16x16 ??

% Let's check out the output power of the BF
figure; 
plot(OutputPower, '.');
legend('OutputPower');
% Hmmm, doesn't appear to be doing any converging. 
figure; 
plot(W_norm, '.');
legend('norm(W)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot fft of the three source signals and beamformer output
NFFT = length(s1);
f_s1 = fft(s1,NFFT);
FreqDom = [0 : 0.5/(NFFT/2) : 0.5];
magnitude_f_s1 = abs(f_s1);        % Magnitude of the FFT
phase_f_s1 = unwrap(angle(f_s1));  % Phase of the FFT
figure; 
plot(FreqDom, magnitude_f_s1(1:NFFT/2+1))
% plot(FreqDom, magnitude_f_s1(NFFT/2:end))
hold on;
f_s2 = fft(s2,NFFT);
magnitude_f_s2 = abs(f_s2);        % Magnitude of the FFT
phase_f_s2 = unwrap(angle(f_s2));  % Phase of the FFT
plot(FreqDom, magnitude_f_s2(1:NFFT/2+1)); 
% plot(FreqDom, magnitude_f_s2(NFFT/2:end)); 
hold on;
f_s3 = fft(s3,NFFT);
magnitude_f_s3 = abs(f_s3);        % Magnitude of the FFT
phase_f_s3 = unwrap(angle(f_s3));  % Phase of the FFT
plot(FreqDom, magnitude_f_s3(1:NFFT/2+1))
% plot(FreqDom, magnitude_f_s3(NFFT/2:end))
hold on;
f_Y = fft(Y,NFFT);
magnitude_f_Y = abs(f_Y);        % Magnitude of the FFT
phase_f_Y = unwrap(angle(f_Y));  % Phase of the FFT
plot(FreqDom, magnitude_f_Y(1:NFFT/2+1), '.')
% plot(FreqDom, magnitude_f_Y(NFFT/2:end))
legend('s1', 's2', 's3', 'Y');
% title('Source power vs frequency');
xlabel('Frequency');ylabel('Power');
set(gca,'fontsize',plot_txt_size); 
xlim([0, 0.5]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%