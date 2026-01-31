%% This function computes the following regularization:
% F(x) = min ||y - x ||^2 + lambda * ||Op{x}||_1, where Op is the gradient
% operator using the 3D extension of the FISTA:
% Beck, A., & Teboulle, M. (2009). A fast iterative shrinkage-thresholding 
% algorithm for linear inverse problems. 
% SIAM journal on imaging sciences, 2(1), 183-202.
%
% Inputs:
% - y : 3D or 4D volume % If y is 4D, a 3D algorithm is applied to the 
% first 3 components in parallel
% - param: structure containing required TA parameters
%
% Outputs:
% - x_out : denoised output
%
% Implemented by Younes Farouj, 10.03.2016
function x_out = MyProx(x,Op,Adj_Op,evaluate_norm,param)

    L = param.Lip; 
    tol=param.tol;
    lambda=param.LambdaSpat;
    iter=param.NitSpat;

    % Initializing solution
    [u, v, w] = Op(x*0);
    u_old = u; 
    v_old = v; 
    w_old = w;


    % Initializing algorithm
    NRJ_old = 0;
    residual = tol+1;
    t_old = 1;
    k=1; 
 
     while (k<=iter && residual > tol)

        % Backward step
        x_out = x + lambda * Adj_Op(u, v, w);


        % Evaluate the functional to be minimzed
        NRJ = lambda * evaluate_norm(x_out) + .5*norm(x(:)-x_out(:), 2)^2 ;
        residual = abs(NRJ-NRJ_old)/NRJ;
        NRJ_old = NRJ;

        % Prox operator argument 
        [dx, dy, dz] = Op(x_out);
        u = u - 1/(L*lambda) * dx;
        v = v - 1/(L*lambda) * dy;
        w = w - 1/(L*lambda) * dz;

        % Soft thresholding
        proj_amplitude = max(1, sqrt(abs(u).^2+abs(v).^2+abs(w).^2));
        u_temp = u./proj_amplitude;
        v_temp = v./proj_amplitude;
        w_temp = w./proj_amplitude;

        % FISTA Acceleration 
        t = (1+sqrt(4*t_old^2))/2;
        u = u_temp + (t_old-1)/t * (u_temp - u_old); u_old = u_temp;
        v = v_temp + (t_old-1)/t * (v_temp - v_old); v_old = v_temp;
        w = w_temp + (t_old-1)/t * (w_temp - w_old); w_old = w_temp;
        t_old = t;

        % Next iteration
        k=k+1;
     end 
end