% This is a script to generate a figure on the stability of clustering FIR for
% the BASCFIR paper
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% Gériatrie de Montréal, Département d'informatique et de recherche
% opérationnelle, Université de Montréal, 2010.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : BASCFIR, FIR, paper, figure

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

% 41 34 38
% 32 45 17
clear
clf
path_data = '/home/pbellec/database/stability_fir/';
path_fig  = '/home/pbellec/svn/papers/basc_fir/figures/fig_stability_fir/';

file_tseries = [path_data 'stability_ind' filesep 'tseries2_ALDR.mat'];
load(file_tseries);
file_timing_all = [path_data 'timing' filesep 'ALDR_timing.mat'];
file_timing = [path_data 'timing' filesep 'ALDR_timing_O.mat'];
all = load(file_timing_all);
sel = load(file_timing);
nt = length(tseries);
plot(sel.time_frames(1:nt),tseries,'b-o')
mask_t = (sel.time_frames>=750)&(sel.time_frames<=1010);
maxa = 1.0025*max(tseries(mask_t));
mina = 0.9975*min(tseries(mask_t));
axis([750 1010 mina maxa])

hold on
flag_coul = 0;
for num_a = 1:(length(all.time_events)-1)
    xa = all.time_events(num_a);
    ya = all.time_events(num_a+1);
    if ismember(xa,sel.time_events)
        if flag_coul
            plot([xa ; xa ; ya ; ya; xa],[mina ; maxa ; maxa ; mina ; mina ],'r')
        end
        flag_coul = ~flag_coul;
        plot(xa,(mina+maxa)/2,'ro')
    else
        plot([xa ; xa ; ya ; ya; xa],[mina ; maxa ; maxa ; mina ; mina ],'g')
        plot(xa,(mina+maxa)/2,'go')
    end
end

file_write = [path_fig 'interpolation_fir2.pdf'];
print(gcf,file_write,'-dpdf');

%% FIR mean/var
opt_f.time_frames = sel.time_frames(1:nt);
opt_f.time_events = sel.time_events(1:47);
opt_f.time_window = 20;
opt_f.time_sampling = 0.5;
opt_f.type_norm = 'none';
opt_f.time_norm = 1;
[tmp,tmp2,fir_all,timing] = niak_build_fir(tseries,opt_f);
opt_fir.nb_vol = 2;
fir_all = fir_normalize_fir(fir_all,opt_fir);
figure
fir_mean = mean(fir_all,3);
fir_std = std(fir_all,[],3);
C = niak_build_covariance (squeeze(fir_all)');
plot(timing,fir_mean)
hold on
vx = [timing ; timing(end:-1:1) ; timing(1)];
vy = [fir_mean+fir_std ; fir_mean(end:-1:1)-fir_std(end:-1:1) ; fir_mean(1)+fir_std(1)];
plot(vx,vy)
%axis([0 21 -0.29 0.29])
file_write = [path_fig 'fir_mean_std2.pdf'];
print(gcf,file_write,'-dpdf');

%% Covariance
figure
imagesc(C)
axis square
colorbar
file_write = [path_fig 'fir_cov2.pdf'];
print(gcf,file_write,'-dpdf');

%% Bootstrap sample - time series #2
clear
psom_set_rand_seed(0);
clf
path_data = '/home/pbellec/database/stability_fir/';
path_fig  = '/home/pbellec/svn/papers/basc_fir/figures/fig_stability_fir/';

file_tseries = [path_data 'stability_ind' filesep 'tseries2_ALDR.mat'];
load(file_tseries);
file_timing_all = [path_data 'timing' filesep 'ALDR_timing.mat'];
file_timing = [path_data 'timing' filesep 'ALDR_timing_O.mat'];
all = load(file_timing_all);
sel = load(file_timing);
nt = length(tseries);

opt_f.time_frames = sel.time_frames(1:nt);
opt_f.time_events = sel.time_events(1:47);
opt_f.time_window = 20;
opt_f.time_sampling = 0.5;
opt_f.type_norm = 'none';
opt_f.time_norm = 1;
[tmp,tmp2,fir_all,timing] = niak_build_fir(tseries,opt_f);
opt_fir.nb_vol = 2;
fir_all = fir_normalize_fir(fir_all,opt_fir);

[T,N,ne] = size(fir_all);
mu = mean(fir_all,3);
squares = sum(fir_all.^2,3);
sqrt_sigma = zeros(T,T,N);
for num_r = 1:size(fir_all,2)
    sigma = niak_build_covariance(squeeze(fir_all(:,num_r,:))');
    sqrt_sigma(:,:,num_r) = chol(sigma)';
    sigma = diag(sigma);
    mu(:,num_r) = max(1-(ne-2)*sigma./(squares(:,num_r)),0).*mu(:,num_r); % James-Stein Correction on the mean
end

 fir_all_boot = fir_all;
 for num_r = 1:N
    fir_all_boot(:,num_r,:) = repmat(mu(:,num_r),[1 ne]) + sqrt_sigma(:,:,N) * randn([T ne]);
 end
fir_all_boot = fir_normalize_fir(fir_all_boot,opt_fir);

tseries = squeeze(fir_all_boot);
tseries = tseries(:);
tseries = tseries(1:(10*41));
plot(opt_f.time_sampling*(0:(size(tseries,1)-1)),tseries,'b-o')

hold on
maxa = 1.0025*max(tseries);
mina = 0.9975*min(tseries);
flag_coul = 0;
for num_a = 1:10
    xa = (num_a-1)*41*0.5;
    ya = (num_a)*41*0.5;
    if flag_coul
        plot([xa ; xa ; ya ; ya; xa],[mina ; maxa ; maxa ; mina ; mina ],'r')
    end
    flag_coul = ~flag_coul;
end
axis([0 205 mina maxa])
file_write = [path_fig 'interpolation_fir2_boot2.pdf'];
print(gcf,file_write,'-dpdf');

fir_mean = mean(fir_all,3);
fir_std = std(fir_all,[],3);
plot(timing,mu)
hold on
vx = [timing ; timing(end:-1:1) ; timing(1)];
vy = [mu+fir_std ; mu(end:-1:1)-fir_std(end:-1:1) ; mu(1)+fir_std(1)];
plot(vx,vy)
%axis([0 21 -0.29 0.29])
file_write = [path_fig 'fir_mean_std2.pdf'];
print(gcf,file_write,'-dpdf');

fir_mean = mean(fir_all_boot,3);
fir_std = std(fir_all_boot,[],3);
plot(timing,fir_mean)
hold on
vx = [timing ; timing(end:-1:1) ; timing(1)];
vy = [fir_mean+fir_std ; fir_mean(end:-1:1)-fir_std(end:-1:1) ; fir_mean(1)+fir_std(1)];
plot(vx,vy)
%axis([0 21 -0.29 0.29])
file_write = [path_fig 'fir_mean_std_boot.pdf'];
print(gcf,file_write,'-dpdf');

clf
fir_all_boot = fir_all;
 for num_r = 1:N
    fir_all_boot(:,num_r,:) = repmat(mu(:,num_r),[1 ne]) + sqrt_sigma(:,:,N) * randn([T ne]);
 end
fir_all_boot = fir_normalize_fir(fir_all_boot,opt_fir);

fir_mean = mean(fir_all_boot,3);
fir_std = std(fir_all_boot,[],3);
plot(timing,fir_mean)
hold on
vx = [timing ; timing(end:-1:1) ; timing(1)];
vy = [fir_mean+fir_std ; fir_mean(end:-1:1)-fir_std(end:-1:1) ; fir_mean(1)+fir_std(1)];
plot(vx,vy)
%axis([0 21 -0.29 0.29])
file_write = [path_fig 'fir_mean_std_boo2t.pdf'];
print(gcf,file_write,'-dpdf');

%% Clustering
clear
psom_set_rand_seed(0);
clf
path_data = '/home/pbellec/database/stability_fir/';
path_fig  = '/home/pbellec/svn/papers/basc_fir/figures/fig_stability_fir/';

file_tseries = [path_data 'fir_rois' filesep 'fir_tseries_ALDR_roi.mat'];
load(file_tseries);
opt_fir.nb_vol = 2;
fir_all = fir_normalize_fir(fir_all,opt_fir);

[T,N,ne] = size(fir_all);
mu = mean(fir_all,3);
squares = sum(fir_all.^2,3);
sqrt_sigma = zeros(T,T,N);
for num_r = 1:size(fir_all,2)
    sigma = niak_build_covariance(squeeze(fir_all(:,num_r,:))');
    sqrt_sigma(:,:,num_r) = chol(sigma)';
    sigma = diag(sigma);
    mu(:,num_r) = max(1-(ne-2)*sigma./(squares(:,num_r)),0).*mu(:,num_r); % James-Stein Correction on the mean
end

fir_all_boot = fir_all;
 for num_r = 1:N
    fir_all_boot(:,num_r,:) = repmat(mu(:,num_r),[1 ne]) + sqrt_sigma(:,:,N) * randn([T ne]);
 end
fir_all_boot = fir_normalize_fir(fir_all_boot,opt_fir);

fir_mean = mean(fir_all_boot,3);
fir_std = std(fir_all_boot,[],3);
D = niak_build_distance(fir_mean,'mahalanobis',fir_std);

S = exp(-D.^2/2);
opt_clustering.type = 'spectral';
opt_clustering.opt.type_affinity = 'manual';
opt_clustering.opt.nb_classes = 8;
part = niak_spectral_clustering(S,opt_clustering.opt);

file_group = [path_data 'stability_group' filesep 'stability_group_sci8.mat'];
data = load(file_group,'order','nb_classes');
order = data.order(:,data.nb_classes==6);
%niak_visu_matrix(S(order,order));
mat = niak_part2mat(part,true);
niak_visu_matrix(mat(order,order));
file_part = [path_fig 'part.pdf'];
print(gcf,file_part,'-dpdf');

for num_r = 1:N
    fir_all_boot(:,num_r,:) = repmat(mu(:,num_r),[1 ne]) + sqrt_sigma(:,:,N) * randn([T ne]);
 end
fir_all_boot = fir_normalize_fir(fir_all_boot,opt_fir);
fir_mean = mean(fir_all_boot,3);
fir_std = std(fir_all_boot,[],3);
D = niak_build_distance(fir_mean,'mahalanobis',fir_std);
S = exp(-D.^2/2);
opt_clustering.type = 'spectral';
opt_clustering.opt.type_affinity = 'manual';
opt_clustering.opt.nb_classes = 8;
part = niak_spectral_clustering(S,opt_clustering.opt);
mat = niak_part2mat(part,true);
niak_visu_matrix(mat(order,order));
file_part = [path_fig 'part2.pdf'];
print(gcf,file_part,'-dpdf');