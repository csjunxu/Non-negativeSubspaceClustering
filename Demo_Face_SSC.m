
clear ;

load 'C:\Users\csjunxu\Desktop\SC\Datasets\YaleBCrop025.mat';
% load 'C:\Users\csjunxu\Desktop\SC\Datasets\USPS_Crop.mat'   % load USPS dataset
dataset = 'YaleB_SSC';
writefilepath = ['C:/Users/csjunxu/Desktop/SC/Results/' dataset '/'];

%% Subspace segmentation methods
SegmentationMethod = 'SSC' ; addpath('C:\Users\csjunxu\Desktop\SC\2013 PAMI SSC');
% SegmentationMethod = 'LRR' ; addpath('C:\Users\csjunxu\Desktop\SC\LRR ICML2010 NIPS2011 PAMI2013\code\');
% SegmentationMethod = 'LRSC' ; addpath('C:\Users\csjunxu\Desktop\SC\2011 CVPR LRSC\');
% SegmentationMethod = 'LSR1' ; % 4.8
% SegmentationMethod = 'LSR2' ; % 4.6
% SegmentationMethod = 'LSR' ;   % the same with LSR2
% SegmentationMethod = 'LSRd0' ;
% SegmentationMethod = 'SMR' ; addpath('C:\Users\csjunxu\Desktop\SC\SMR_v1.0');
% SegmentationMethod = 'SSCOMP' ;

% SegmentationMethod = 'NNLSR' ;
% SegmentationMethod = 'NNLSRd0' ;
% SegmentationMethod = 'NPLSR' ;
% SegmentationMethod = 'NPLSRd0' ;

% SegmentationMethod = 'ANNLSR' ;
% SegmentationMethod = 'ANNLSRd0' ;
% SegmentationMethod = 'ANPLSR' ;
% SegmentationMethod = 'ANPLSRd0' ;

% SegmentationMethod = 'DANNLSR';
% SegmentationMethod = 'DANNLSRd0';
% SegmentationMethod = 'DANPLSR';
% SegmentationMethod = 'DANPLSRd0';

Repeat = 1; %number of repeations
DR = 1; % dimension reduction
if DR == 0
    dim = size(Y, 1);
elseif DR == 1
    dim = 6;
else
    DR = 1;
    dim = 6;
end
%% Subspace segmentation
for maxIter = [5]
    Par.maxIter = maxIter;
    for mu = [1]
        Par.mu = mu;
        for rho = [1]
            Par.rho = rho;
            for lambda = [5e4 1e5 5e5 1e6]
                Par.lambda = lambda*10^(-0);
                for nSet = [2 3 5 8 10]
                    n = nSet;
                    index = Ind{n};
                    for i = 1:size(index,1)
                        X = [];
                        for p = 1:n
                            X = [X Y(:,:,index(i,p))];
                        end
                        [D,N] = size(X);
                        
                        fea = X ;
                        gnd = s{n} ;
                        
                        redDim = size(fea, 1);
                        if DR == 1
                            %% PCA Projection
                            [ eigvector , eigvalue ] = PCA( fea ) ;
                            maxDim = length(eigvalue);
                            fea = eigvector' * fea ;
                            redDim = min(nSet*dim, size(fea, 1)) ;
                        end
                        
                        % normalize
                        for c = 1 : size(fea,2)
                            fea(:,c) = fea(:,c) /norm(fea(:,c)) ;
                        end
                        missrate = zeros(size(index, 1), Repeat) ;
                        fprintf( 'dimension = %d \n', redDim ) ;
                        Yfea = fea(1:redDim, :) ;
                        for j = 1 : Repeat
                            switch SegmentationMethod
                                case 'SSC'
                                    alpha = Par.lambda;
                                    CMat = admmOutlier_mat_func(Yfea, true, alpha);
                                    N = size(Yfea,2);
                                    C = CMat(1:N,:);
                                case 'LRR'
                                    C = solve_lrr(Yfea, Par.lambda); % without post processing
                                case 'LRSC'
                                    C = lrsc_noiseless(Yfea, Par.lambda);
                                    %  [~, C] = lrsc_noisy(ProjX, Par.lambda);
                                case 'LSR1'
                                    C = LSR1( Yfea , Par.lambda ) ; % proposed by Lu
                                case 'LSR2'
                                    C = LSR2( Yfea , Par.lambda ) ; % proposed by Lu
                                case 'LSR'
                                    C = LSR( Yfea , Par ) ;
                                case 'LSRd0'
                                    C = LSRd0( Yfea , Par ) ; % solved by ADMM
                                case 'SMR'
                                    para.aff_type = 'J1'; % J1 is unrelated to gamma, which is used in J2 and J2_norm
                                    para.gamma = 1;
                                    para.alpha = 20;
                                    para.knn = 4;
                                    para.elpson =0.01;
                                    Yfea = [Yfea ; ones(1,size(ProjX,2))] ;
                                    C = smr(Yfea, para);
                                case 'SSCOMP' % add the path of the SSCOMP method
                                    addpath('C:\Users\csjunxu\Desktop\SC\SSCOMP_Code');
                                    C = OMP_mat_func(Yfea, 9, 1e-6);
                                case 'NNLSR'                   % non-negative
                                    C = NNLSR( Yfea , Par ) ;
                                case 'NNLSRd0'               % non-negative, diagonal = 0
                                    C = NNLSRd0( Yfea , Par ) ;
                                case 'NPLSR'                   % non-positive
                                    C = NPLSR( Yfea , Par ) ;
                                case 'NPLSRd0'               % non-positive, diagonal = 0
                                    C = NPLSRd0( Yfea , Par ) ;
                                case 'ANNLSR'                 % affine, non-negative
                                    C = ANNLSR( Yfea , Par ) ;
                                case 'ANNLSRd0'             % affine, non-negative, diagonal = 0
                                    C = ANNLSRd0( Yfea , Par ) ;
                                case 'ANPLSR'                 % affine, non-positive
                                    C = ANPLSR( Yfea , Par ) ;
                                case 'ANPLSRd0'             % affine, non-positive, diagonal = 0
                                    C = ANPLSRd0( Yfea , Par ) ;
                            end
                            for k = 1 : size(C,2)
                                C(:, k) = C(:, k) / max(abs(C(:, k))) ;
                            end
                            nCluster = length( unique( gnd ) ) ;
                            Z = ( abs(C) + abs(C') ) / 2 ;
                            idx = clu_ncut(Z,nCluster) ;
                            missrate(i, j) = 1 - compacc(idx,gnd');
                            fprintf('%.3f%% \n' , missrate(i, j)*100) ;
                        end
                        missrateTot{n}(i) = mean(missrate(i, :)*100);
                        fprintf('Mean error of %d/%d is %.3f%%.\n ' , i, size(index, 1), missrateTot{n}(i)) ;
                    end
                    avgmissrate(n) = mean(missrateTot{n});
                    medmissrate(n) = median(missrateTot{n});
                    fprintf('Total mean error  is %.3f%%.\n ' , avgmissrate(n)) ;
                    allavgmissrate = mean(avgmissrate(avgmissrate~=0));
                    if strcmp(SegmentationMethod, 'SSC')==1 || strcmp(SegmentationMethod, 'LRR')==1 || strcmp(SegmentationMethod, 'LRSC')==1 || strcmp(SegmentationMethod, 'LSR')==1 || strcmp(SegmentationMethod, 'LSR1')==1 || strcmp(SegmentationMethod, 'LSR2')==1 || strcmp(SegmentationMethod, 'SMR')==1 %|| strcmp(SegmentationMethod, 'SSCOMP')==1
                        matname = sprintf([writefilepath dataset '_' SegmentationMethod '_DR' num2str(DR) '_dim' num2str(dim) '_lambda' num2str(Par.lambda) '.mat']);
                        save(matname,'missrateTot','avgmissrate','medmissrate','allavgmissrate');
                    elseif strcmp(SegmentationMethod, 'NNLSR') == 1 || strcmp(SegmentationMethod, 'NPLSR') == 1 || strcmp(SegmentationMethod, 'ANNLSR') == 1 || strcmp(SegmentationMethod, 'ANPLSR') == 1
                        matname = sprintf([writefilepath dataset '_' SegmentationMethod '_DR' num2str(DR) '_dim' num2str(dim) '_maxIter' num2str(Par.maxIter) '_rho' num2str(Par.rho) '_lambda' num2str(Par.lambda) '.mat']);
                        save(matname,'missrateTot','avgmissrate','medmissrate','allavgmissrate');
                    elseif strcmp(SegmentationMethod, 'DANNLSR') == 1 || strcmp(SegmentationMethod, 'DANPLSR') == 1
                        matname = sprintf([writefilepath dataset '_' SegmentationMethod '_DR' num2str(DR) '_dim' num2str(dim) '_maxIter' num2str(Par.maxIter) '_rho' num2str(Par.rho) '_lambda' num2str(Par.lambda) '_scale' num2str(Par.s) '.mat']);
                        save(matname,'missrateTot','avgmissrate','medmissrate','allavgmissrate');
                    elseif strcmp(SegmentationMethod, 'SSCOMP')==1
                        matname = sprintf([writefilepath dataset '_' SegmentationMethod '_DR' num2str(DR) '_dim' num2str(dim) '_K' num2str(Par.rho) '_thr' num2str(Par.lambda) '.mat']);
                        save(matname,'missrateTot','avgmissrate','medmissrate','allavgmissrate');
                    end
                end
            end
        end
    end
end

