clear;

cd '/Users/xujun/Downloads/Hopkins155/';
addpath '/Users/xujun/Documents/GitHub/SRLSR/';

dataset = 'Hopkins155';
write_results_dir = ['/Users/xujun/Desktop/Results/' dataset '/'];
if ~isdir(write_results_dir)
    mkdir(write_results_dir);
end
maxNumGroup = 5;
for i = 1:maxNumGroup
    num(i) = 0;
end


%% Subspace segmentation methods
% SegmentationMethod = 'SSC' ; addpath('C:\Users\csjunxu\Desktop\CVPR2018 SC\2009 CVPR 2013 PAMI SSC');
% SegmentationMethod = 'LRR' ; addpath('C:\Users\csjunxu\Desktop\CVPR2018 SC\2010 ICML 2013 PAMI LRR\code\');
% SegmentationM ethod = 'LRSC' ; addpath('C:\Users\csjunxu\Desktop\CVPR2018 SC\2011 CVPR LRSC\');
% SegmentationMethod = 'SMR' ; addpath('C:\Users\csjunxu\Desktop\CVPR2018 SC\SMR_v1.0');
% SegmentationMethod = 'RSIM' ; ii = 0;addpath('C:\Users\csjunxu\Desktop\CVPR2018 SC\Ncut_9'); addpath('C:\Users\csjunxu\Desktop\SC\2015 ICCV RSIM');
% SegmentationMethod = 'SSCOMP' ; addpath('C:\Users\csjunxu\Desktop\CVPR2018 SC\SSCOMP_Code');
% SegmentationMethod = 'LSR1' ;
% SegmentationMethod = 'LSR2' ;

% SegmentationMethod = 'LSRd0' ; % the same with LSR1
% SegmentationMethod = 'NNLSRd0';
% SegmentationMethod = 'SALSRd0';
% SegmentationMethod = 'SANNLSRd0';

% SegmentationMethod = 'LSR' ; % the same with LSR2
% SegmentationMethod = 'NLSR';
% SegmentationMethod = 'SLSR';
% SegmentationMethod = 'SRLSR';
SegmentationMethod = 'RSRLSR';

for maxIter = 1:1:5
    Par.maxIter = maxIter;
    for s = [0.9 .5]
        Par.s = s;
        for rho = [.1 .3 .5]
            Par.rho = rho;
            for lambda = [0 .001 .005 .01]
                Par.lambda = lambda;
                maxNumGroup = 5;
                for i = 1:maxNumGroup
                    num(i) = 0;
                end
                %%
                d = dir;
                ii=0;
                alltime = [];
                for i = 1:length(d)
                    if ( (d(i).isdir == 1) && ~strcmp(d(i).name,'.') && ~strcmp(d(i).name,'..') )
                        filepath = d(i).name;
                        eval(['cd ' filepath]);
                        
                        f = dir;
                        foundValidData = false;
                        for j = 1:length(f)
                            if ( ~isempty(strfind(f(j).name,'_truth.mat')) )
                                ind = j;
                                foundValidData = true;
                                break
                            end
                        end
                        eval(['load ' f(ind).name]);
                        cd ..
                        if (foundValidData)
                            gnd = s;
                            clear s;
                            n = max(gnd);
                            N = size(x,2);
                            F = size(x,3);
                            D = 2*F;
                            X = reshape(permute(x(1:2,:,:),[1 3 2]),D,N);
                            ii = ii+1;
                            r = 4*n;
                            t1=clock;
                            Xp = DataProjection(X,r);
                            if strcmp(SegmentationMethod, 'RSIM') == 1
                                [missrate, grp, bestRank, minNcutValue,W] = RSIM(Xp, gnd);
                                disp([filepath ': ' num2str(100*missrate) '%, dim:' num2str(bestRank) ', nMotions: ' num2str(n) ', seq: ' num2str(ii)]);
                            else
                                switch SegmentationMethod
                                    case 'SSC'
                                        alpha = 800;
                                        C = admmLasso_mat_func(Xp, true, alpha);
                                    case 'LRR'
                                        C = solve_lrr(Xp, Par.lambda); % without post processing
                                    case 'LRSC'
                                        C = lrsc_noiseless(Xp, 15);
                                        %  [~, C] = lrsc_noisy(Xp, Par.lambda);
                                    case 'SMR'
                                        para.aff_type = 'J1'; % J1 is unrelated to gamma, which is used in J2 and J2_norm
                                        para.gamma = 1;
                                        para.alpha = 20;
                                        para.knn = 4;
                                        para.elpson =0.01;
                                        Xp = [Xp ; ones(1,size(Xp,2))] ;
                                        C = smr(Xp, para);
                                    case 'SSCOMP' % add the path of the SSCOMP method
                                        C = OMP_mat_func(Xp, 9, 1e-6);
                                    case 'LSR'
                                        C = LSR( Xp , Par ) ;
                                    case 'LSRd0'
                                        C = LSRd0( Xp , Par ) ; % solved by ADMM
                                    case 'LSR1'
                                        C = LSR1( Xp , Par.lambda ) ; % proposed by Lu
                                    case 'LSR2'
                                        C = LSR2( Xp , Par.lambda ) ; % proposed by Lu
                                        %% our methods
                                    case 'NLSR'                   % non-negative
                                        C = NLSR( Xp , Par ) ;
                                    case 'SLSR'
                                        C = SLSR(Xp, Par); % affine
                                    case 'SRLSR'
                                        C = SRLSR( Xp , Par ) ;
                                    case 'SRLSR'
                                        C = SRLSR( Xp , Par ) ;
                                end
                                nCluster = length( unique( gnd ) ) ;
                                Z = ( abs(C) + abs(C') ) / 2 ;
                                idx = clu_ncut(Z,nCluster) ;
                                accuracy = compacc(idx, gnd') ;
                                missrate = 1-accuracy;
                                fprintf('seq %d %f\n', i , missrate ) ;
                            end
                            t2=clock;
                            alltime(ii) = etime(t2,t1);
                            num(n) = num(n) + 1;
                            missrateTot{n}(num(n)) = missrate;
                            eval(['cd ' filepath]);
                            cd ..
                        end
                    end
                end
                L = [2 3];
                allmissrate = [];
                for i = 1:length(L)
                    j = L(i);
                    avgmissrate(j) = mean(missrateTot{j});
                    medmissrate(j) = median(missrateTot{j});
                    allmissrate = [allmissrate missrateTot{j}];
                end
                avgallmissrate = sum(allmissrate)/length(allmissrate);
                medallmissrate = median(allmissrate);
                fprintf('Total mean error  is %.3f%%.\n ' , avgallmissrate*100) ;
                if strcmp(SegmentationMethod, 'SSC')==1
                    matname = sprintf([write_results_dir dataset '_SSCsetting_' SegmentationMethod '_alpha' num2str(alpha) '.mat']);
                    save(matname,'avgallmissrate','medallmissrate','missrateTot','avgmissrate','medmissrate');
                elseif strcmp(SegmentationMethod, 'LRR')==1 || strcmp(SegmentationMethod, 'LRSC')==1 || strcmp(SegmentationMethod, 'LSR')==1 || strcmp(SegmentationMethod, 'LSR1')==1 || strcmp(SegmentationMethod, 'LSR2')==1 || strcmp(SegmentationMethod, 'SMR')==1 %|| strcmp(SegmentationMethod, 'SSCOMP')==1
                    matname = sprintf([write_results_dir dataset '_SSCsetting_' SegmentationMethod '_lambda' num2str(Par.lambda) '.mat']);
                    save(matname,'avgallmissrate','medallmissrate','missrateTot','avgmissrate','medmissrate');
                elseif strcmp(SegmentationMethod, 'NLSR') == 1
                    matname = sprintf([write_results_dir dataset '_SSCsetting_' SegmentationMethod '_maxIter' num2str(Par.maxIter) '_rho' num2str(Par.rho) '_lambda' num2str(Par.lambda) '.mat']);
                    save(matname,'avgallmissrate','medallmissrate','missrateTot','avgmissrate','medmissrate');
                elseif strcmp(SegmentationMethod, 'SRLSR') == 1 || strcmp(SegmentationMethod,'RSRLSR')==1 || strcmp(SegmentationMethod,'SLSR')==1
                    matname = sprintf([write_results_dir dataset '_SSCsetting_' SegmentationMethod '_s' num2str(Par.s) '_maxIter' num2str(Par.maxIter) '_rho' num2str(Par.rho) '_lambda' num2str(Par.lambda) '.mat']);
                    save(matname,'avgallmissrate','medallmissrate','missrateTot','avgmissrate','medmissrate');
                elseif strcmp(SegmentationMethod, 'SSCOMP')==1
                    matname = sprintf([write_results_dir dataset '_SSCsetting_' SegmentationMethod '_K' num2str(Par.rho) '_thr' num2str(Par.lambda) '.mat']);
                    save(matname,'avgallmissrate','medallmissrate','missrateTot','avgmissrate','medmissrate');
                elseif strcmp(SegmentationMethod, 'RSIM')==1
                    matname = sprintf([write_results_dir dataset '_SSCsetting_' SegmentationMethod '.mat']);
                    save(matname,'avgallmissrate','medallmissrate','missrateTot','avgmissrate','medmissrate');
                end
            end
        end
    end
end
