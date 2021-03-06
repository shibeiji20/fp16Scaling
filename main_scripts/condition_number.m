% This script computes the condition number of the scaled matrix and
% measures its effectiveness as a preconditioner by computing the
% condition number of the preconditioned matrix. Generates Table 4.4
% of the manuscript.
%
% Note -- CAUTION!! Read the comments before changing the variables

clear all; close all;
rng(1);

%%% Matlab file containing all the test matrices
load test_mat.mat

%%% prec_set=1 is (half,single,double) in GMRES-IR
%%% prec_set=2 is (half,double,quad  ) in GMRES-IR
prec_set = [1;2];

%%% theta -- Headroom to prevent overflow
theta = 0.1;

%%% dscale=1, uses Algorithm 2.4 as diagonal scaling in either Algorithm
%%%           2.3 
%%% dscale=2, uses Algorithm 2.5 as diagonal scaling in either Algorithm
%%%           2.3 
dscale = [1;2];


%%%%% condtion number of diagonal scaling algorithms
for prec = 1:2
    for alg = 1:2
        for i = 1:length(test_mat)
            
            fprintf('Diagonal scaling part | Matrix %d | Algorithm %d | Precisin %d \n',i,alg,prec);
            
            load(test_mat{i,1});  %%% Load the required matrix
            if (prec_set(prec,1) == 1)
                A = Problem.A;
                A = single(full(A));
                A = single(A);
                n = length(A);
                b = single(randn(n,1));
                u  =  eps('single');
                [u1,rmins,rmin,rmax,p] = ieee_params('h');
                rmax2 = single(rmax)*single(theta);
            else
                A = Problem.A;
                A = single(full(A));
                n = length(A);
                b = (randn(n,1));
                u = eps('double');
                [u1,rmins,rmin,rmax,p] = ieee_params('h');
                rmax2 = rmax*theta;
            end
            Ao = A;
            Cnumber{prec,alg}(i,1) = cond(A,inf);
            [ A,b,R,C,mu ] = Diagonal_Scaling( A,b,dscale(alg,1),rmax2 );
            Cnumber{prec,alg}(i,2) = cond(A,inf);
            B = double(fp16(A));
            Cnumber{prec,alg}(i,3) = cond(B,inf);
%             [L,U] = lu(B);
%             L = fp16(L);
%             U = fp16(U);
            
%%%% Uncomment this if you want to use
%%%% fp16 LU using Cleve's lutx.m. It 
%%%% is extremely slow and the answer will
%%%% not change.
            [L,U,p] = lu(fp16(A));
            p = double(p);
            I = (eye(n)); P = I(p,:);
            U = double(U);
            L = (double(P')*double(L));
            
            L = diag(1./diag(R))*double(L);
            U = double(U)*diag(1./diag(C));
     
            At = double(mu*(double(U))\((double(L))\((double(Ao)))));
            Cnumber{prec,alg}(i,4) = cond((double(At)),'inf');
            
        end
        
    end
end

fid1=fopen('Condition_number.txt','w');

fprintf(fid1,'algorithm 1 -- Un Symmetric diagonal scaling \n');
fprintf(fid1,'algorithm 2 -- Symmetric diagonal scaling \n');
fprintf(fid1,'\n'); fprintf(fid1,'\n');

for prec = 1:2        
        fprintf(fid1,'Condition numbers diagonal scaling algorithm %d for precision %d \n',alg,prec);
        for i=1:length(test_mat)
            t1 = Cnumber{prec,1}(i,1); t2 = Cnumber{prec,1}(i,2);
            t4 = Cnumber{prec,1}(i,4); t5 = Cnumber{prec,2}(i,2);
            t6 = Cnumber{prec,2}(i,4);
            fprintf(fid1,'%d & %6.2e & %6.2e & %6.2e & %6.2e & %6.2e\\\\ \n',i,...
                t1,t2,t4,t5,t6);
        end
        fprintf(fid1,'\n'); fprintf(fid1,'\n');
end

load approx_err_simple app_err_simp
load approx_err_diag app_err_diag
% Print the approximation error into a file
fprintf(fid1,'\n'); fprintf(fid1,'\n');
for prec = 1:2
        fprintf(fid1,'Precision %d \n',prec);
        for i=1:length(test_mat)
            t1 = app_err_simp{prec,1}(i,1); t2 = app_err_simp{prec,2}(i,1);
            t3 = app_err_diag{prec,1}(i,1); t4 = app_err_diag{prec,2}(i,1);
            fprintf(fid1,'%d & %6.2e & %6.2e & %6.2e & %6.2e\\\\ \n',i,...
                t1,t2,t3,t4);
        end
        fprintf(fid1,'\n'); fprintf(fid1,'\n');
end


fclose(fid1);
