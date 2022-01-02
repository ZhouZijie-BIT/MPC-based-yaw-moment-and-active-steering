function [sys,x0,str,ts] = chapter5_2_2(t,x,u,flag)
 
switch flag
 case 0
  [sys,x0,str,ts] = mdlInitializeSizes; % Initialization
  
 case 2
  sys = mdlUpdates(t,x,u); % Update discrete states
  
 case 3
  sys = mdlOutputs(t,x,u); % Calculate outputs
 
%  case 4
%   sys = mdlGetTimeOfNextVarHit(t,x,u); % Get next sample time 
 
 case {1,4,9} % Unused flags
  sys = [];
  
 otherwise
  error(['unhandled flag = ',num2str(flag)]); % Error handling
end
% End of dsfunc.
 
%==============================================================
% Initialization
%==============================================================
 
function [sys,x0,str,ts] = mdlInitializeSizes
 
% Call simsizes for a sizes structure, fill it in, and convert it 
% to a sizes array.
 
sizes = simsizes;
sizes.NumContStates  = 0;
sizes.NumDiscStates  = 6;
sizes.NumOutputs     = 6;%%%%%
sizes.NumInputs      = 8;
sizes.DirFeedthrough = 1; % Matrix D is non-empty.
sizes.NumSampleTimes = 1;
sys = simsizes(sizes); 
x0 =[0.001;0.0001;0.0001;0.00001;0.00001;0.00001];    
global U;%UΪ���ǵĿ�����
global cost;
cost = 0;
U=[0;0];%��������ʼ��,���������һ�������켣����������ȥ����UΪһά��
 
% Initialize the discrete states.
str = [];             % Set str to an empty matrix.
 ts  = [0.025 0];       % sample time: [period, offset]������ʱ��Ӱ�����
% ts  = [0.1 0];       % sample time: [period, offset]������ʱ��Ӱ�����
%End of mdlInitializeSizes
		      
%==============================================================
% Update the discrete states
%==============================================================
function sys = mdlUpdates(t,x,u)
  
sys = x;

 
%==============================================================
% Calculate outputs
%==============================================================
function sys = mdlOutputs(t,x,u)
    global a b;
    global U;
%     global cost;
    tic
    Nx=6;
    Nu=2;%%%%%
    Ny=3;%%%%%
    Np =10;%%%%%
    Nc=8;%%%%%
    Row=1000;%�ɳ�����Ȩ�� %%%%%
    fprintf('Update start, t=%6.3f\n',t)
   
   %����Ϊ���ǵ�״̬���������������ǵĳ�ʼֵ���ĺ�С���������Ժ���
    y_dot=u(1)/3.6; %�����ٶȻ�Ϊm/s
    x_dot=u(2)/3.6+0.0001;%CarSim�������km/h��ת��Ϊm/s
    phi=u(3)*3.141592654/180; %CarSim�����Ϊ�Ƕȣ��Ƕ�ת��Ϊ���ȣ����ʱ���Ƕ���ʹ�û���
    phi_dot=u(4)*3.141592654/180;
    Y=u(5);%��λΪm
    X=u(6);%��λΪ��
    %Y_dot=u(7);
    %X_dot=u(8);
%% ������������
%syms sfΪǰ�ֻ����ʣ�srΪ���ֻ�����
    Sf=0.2; Sr=0.2;
%syms lf%ǰ�־��복�����ĵľ��룬lrΪ���־��복�����ĵľ���
    lf=1.232;lr=1.468;
%syms C_cfǰ�����Ժ����ƫ�նȣ� C_cr�������Ժ����ƫ�ն� ��C_lf ǰ�������ƫ�նȣ� C_lr ���������ƫ�ն�
    Ccf=66900;Ccr=62700;Clf=66900;Clr=62700;
%syms m g I;%mΪ����������gΪ�������ٶȣ�IΪ������Z���ת���������������в���
    m=1723;g=9.8;I=4175;
   
 
%% �ο��켣����
    shape=2.4;%�������ƣ����ڲο��켣����
    dx1=25;dx2=21.95;%û���κ�ʵ�����壬ֻ�ǲ�������
    dy1=4.05;dy2=5.7;%û���κ�ʵ�����壬ֻ�ǲ�������
    Xs1=27.19;Xs2=56.46;%�������ƣ����ϲ�����Ϊ���������ǵ�˫����
    X_predict=zeros(Np,1);%���ڱ���Ԥ��ʱ���ڵ�����λ����Ϣ�����Ǽ��������켣�Ļ���
    phi_ref=zeros(Np,1);%���ڱ���Ԥ��ʱ���ڵĲο���ڽ���Ϣ
    Y_ref=zeros(Np,1);%���ڱ���Ԥ��ʱ���ڵĲο�����λ����Ϣ
    phi_dot_ref = zeros(Np,1);
  
    %  ���¼���kesi,��״̬�������������һ��   
    kesi=zeros(Nx+Nu,1);
    kesi(1)=y_dot;
    kesi(2)=x_dot;
    kesi(3)=phi; 
    kesi(4)=phi_dot;
    kesi(5)=Y;
    kesi(6)=X; 
    kesi(7)=U(1); 
    kesi(8)=U(2);%%%%%
    delta_f=U(1);
    M=U(2);%%%%%
    fprintf('Update start, u(1)=%4.10f\n',U(1));
    fprintf('Update start, u(2)=%4.10f\n',U(2));
 
    T=0.025;%���沽��
    T_all=20;%�ܵķ���ʱ�䣬��Ҫ�����Ƿ�ֹ���������켣Խ��
     
    %Ȩ�ؾ������� 
    Q_cell=cell(Np,Np);
    for i=1:1:Np
        for j=1:1:Np
            if i==j
                %Q_cell{i,j}=[200 0;0 100;];
                Q_cell{i,j}=[300 0 0;0 1000 0;0 0 300];%%%%%
            else 
                Q_cell{i,j}=zeros(Ny,Ny);      
            end
        end 
    end 
    R=5*10^4*eye(Nu*Nc);%%%%%
    %�����Ҳ����Ҫ�ľ����ǿ������Ļ��������ö���ѧģ�ͣ��þ����복������������أ�ͨ���Զ���ѧ��������ſ˱Ⱦ���õ���aΪ6*6��bΪ6*2
%     a=[                 1 - (259200*T)/(1723*x_dot),                                                         -T*(phi_dot + (2*((460218*phi_dot)/5 - 62700*y_dot))/(1723*x_dot^2) - (133800*((154*phi_dot)/125 + y_dot))/(1723*x_dot^2)),                                    0,                     -T*(x_dot - 96228/(8615*x_dot)), 0, 0
%         T*(phi_dot - (133800*delta_f)/(1723*x_dot)),                                                                                                                  (133800*T*delta_f*((154*phi_dot)/125 + y_dot))/(1723*x_dot^2) + 1,                                    0,           T*(y_dot - (824208*delta_f)/(8615*x_dot)), 0, 0
%                                                   0,                                                                                                                                                                                  0,                                    1,                                                   T, 0, 0
%             (33063689036759*T)/(7172595384320*x_dot), T*(((2321344006605451863*phi_dot)/8589934592000 - (6325188028897689*y_dot)/34359738368)/(4175*x_dot^2) + (5663914248162509*((154*phi_dot)/125 + y_dot))/(143451907686400*x_dot^2)),                                   0, 1 - (813165919007900927*T)/(7172595384320000*x_dot), 0, 0
%                                           T*cos(phi),                                                                                                                                                                         T*sin(phi),  T*(x_dot*cos(phi) - y_dot*sin(phi)),                                                   0, 1, 0
%                                          -T*sin(phi),                                                                                                                                                                         T*cos(phi), -T*(y_dot*cos(phi) + x_dot*sin(phi)),                                                   0, 0, 1];
   
    a=[
                 1 - (259200*T)/(1723*x_dot),                                                         -T*(phi_dot + (2*((460218*phi_dot)/5 - 62700*y_dot))/(1723*x_dot^2) - (133800*((154*phi_dot)/125 + y_dot))/(1723*x_dot^2)),                                    0,                     -T*(x_dot - 96228/(8615*x_dot)), 0, 0
 T*(phi_dot - (133800*delta_f)/(1723*x_dot)),                                                                                                                  (133800*T*delta_f*((154*phi_dot)/125 + y_dot))/(1723*x_dot^2) + 1,                                    0,           T*(y_dot - (824208*delta_f)/(8615*x_dot)), 0, 0
                                           0,                                                                                                                                                                                  0,                                    1,                                                   T, 0, 0
    (33063689036759*T)/(7172595384320*x_dot), T*(((2321344006605451863*phi_dot)/8589934592000 - (6325188028897689*y_dot)/34359738368)/(4175*x_dot^2) + (5663914248162509*((154*phi_dot)/125 + y_dot))/(143451907686400*x_dot^2)),                                    0, 1 - (813165919007900927*T)/(7172595384320000*x_dot), 0, 0
                                  T*cos(phi),                                                                                                                                                                         T*sin(phi),  T*(x_dot*cos(phi) - y_dot*sin(phi)),                                                   0, 1, 0
                                 -T*sin(phi),                                                                                                                                                                         T*cos(phi), -T*(y_dot*cos(phi) + x_dot*sin(phi)),                                                   0, 0, 1];

    b=[                                                               133800*T/1723,0
       T*((267600*delta_f)/1723 - (133800*((154*phi_dot)/125 + y_dot))/(1723*x_dot)),0
                                                                                 0,0
                                                5663914248162509*T/143451907686400,T/4175
                                                                                 0,0
                                                                                 0,0];  
%      b=[                                                               133800*T/1723
%        T*((267600*delta_f)/1723 - (133800*((154*phi_dot)/125 + y_dot))/(1723*x_dot))
%                                                                                  0
%                                                 5663914248162509*T/143451907686400
%                                                                                  0
%                                                                                  0];  
    d_k=zeros(Nx,1);
    state_k1=zeros(Nx,1);
    %���¼�Ϊ������ɢ������ģ��Ԥ����һʱ��״̬��
    %ע�⣬Ϊ����ǰ�����ı��ʽ��a,b�����������a,b�����ͻ����ǰ�����ı��ʽ��Ϊlf��lr
    state_k1(1,1)=y_dot+T*(-x_dot*phi_dot+2*(Ccf*(delta_f-(y_dot+lf*phi_dot)/x_dot)+Ccr*(lr*phi_dot-y_dot)/x_dot)/m);
    state_k1(2,1)=x_dot+T*(y_dot*phi_dot+2*(Clf*Sf+Clr*Sr+Ccf*delta_f*(delta_f-(y_dot+phi_dot*lf)/x_dot))/m);
    state_k1(3,1)=phi+T*phi_dot;
    state_k1(4,1)=phi_dot+T*((2*lf*Ccf*(delta_f-(y_dot+lf*phi_dot)/x_dot)-2*lr*Ccr*(lr*phi_dot-y_dot)/x_dot+M)/I);
    state_k1(5,1)=Y+T*(x_dot*sin(phi)+y_dot*cos(phi));
    state_k1(6,1)=X+T*(x_dot*cos(phi)-y_dot*sin(phi));
    d_k=state_k1-a*kesi(1:6,1)-b*kesi(7:8,1); %  state_k1Ϊ�÷�����ģ��Ԥ�������
    d_piao_k=zeros(Nx+Nu,1);
    d_piao_k(1:6,1)=d_k; 
%     d_piao_k(7,1)=0;
%     d_piao_k(8,1)=0;
    
    A_cell=cell(2,2);
    B_cell=cell(2,1);
    A_cell{1,1}=a;
    A_cell{1,2}=b;
    A_cell{2,1}=zeros(Nu,Nx);
    A_cell{2,2}=eye(Nu);
    B_cell{1,1}=b;
    B_cell{2,1}=eye(Nu);
    A=cell2mat(A_cell);
    B=cell2mat(B_cell);
    C=[0 0 1 0 0 0 0 0;0 0 0 0 1 0 0 0;0 0 0 1 0 0 0 0];
    PSI_cell=cell(Np,1);
    THETA_cell=cell(Np,Nc);
    GAMMA_cell=cell(Np,Np);%ά�� 20*20
    PHI_cell=cell(Np,1);%ά�� 20*1
    for p=1:1:Np
        PHI_cell{p,1}=d_piao_k;
        for q=1:1:Np
            if q<=p  %�����Ǿ���
                GAMMA_cell{p,q}=C*A^(p-q); 
            else 
                GAMMA_cell{p,q}=zeros(Ny,Nx+Nu);
            end 
        end
    end 
    for j=1:1:Np 
     PSI_cell{j,1}=C*A^j; 
        for k=1:1:Nc
            if k<=j
                THETA_cell{j,k}=C*A^(j-k)*B;
            else 
                THETA_cell{j,k}=zeros(Ny,Nu);
            end
        end
    end
    PSI=cell2mat(PSI_cell);
    THETA=cell2mat(THETA_cell);
    GAMMA=cell2mat(GAMMA_cell);
    PHI=cell2mat(PHI_cell);
    Q=cell2mat(Q_cell);
    H_cell=cell(2,2);
    H_cell{1,1}=THETA'*Q*THETA+R;
    H_cell{1,2}=zeros(Nu*Nc,1);
    H_cell{2,1}=zeros(1,Nu*Nc);
    H_cell{2,2}=Row;
    H=cell2mat(H_cell);
%     H=(H+H')/2;
    error_1=zeros(Ny*Np,1);%40*7*7*1=40*1
    Yita_ref_cell=cell(Np,1);%�ο���Ԫ������Ϊ20*1
    for p=1:1:Np
        if t+p*T>T_all %��ֹԽ��
            X_DOT=x_dot*cos(phi)-y_dot*sin(phi);
            X_predict(Np,1)=X+X_DOT*Np*T;
            z1=shape/dx1*(X_predict(Np,1)-Xs1)-shape/2;
            z2=shape/dx2*(X_predict(Np,1)-Xs2)-shape/2;
            Y_ref(p,1)=dy1/2*(1+tanh(z1))-dy2/2*(1+tanh(z2));
            phi_ref(p,1)=atan(dy1*(1/cosh(z1))^2*(1.2/dx1)-dy2*(1/cosh(z2))^2*(1.2/dx2));
            m = dy1.*(1./cosh(z1)).^2*(1.2/dx1)-dy2.*(1./cosh(z2)).^2*(1.2/dx2);
            phi_dot_ref(p,1)= 1./(1+m.^2).*(-2.4.*shape).*((cosh(z1)).^(-3).*sinh(z1)*dy1/dx1^2-cosh(z2).^(-3).*sinh(z2)*dy2/dx2^2)*X_DOT;
            Yita_ref_cell{p,1}=[phi_ref(p,1);Y_ref(p,1);phi_dot_ref(p,1)];
            
        else
            X_DOT=x_dot*cos(phi)-y_dot*sin(phi);
            X_predict(p,1)=X+X_DOT*p*T;
            z1=shape/dx1*(X_predict(p,1)-Xs1)-shape/2;
            z2=shape/dx2*(X_predict(p,1)-Xs2)-shape/2;
            Y_ref(p,1)=dy1/2*(1+tanh(z1))-dy2/2*(1+tanh(z2));
            phi_ref(p,1)=atan(dy1*(1/cosh(z1))^2*(1.2/dx1)-dy2*(1/cosh(z2))^2*(1.2/dx2));
            m = dy1.*(1./cosh(z1)).^2*(1.2/dx1)-dy2.*(1./cosh(z2)).^2*(1.2/dx2);
            phi_dot_ref(p,1)= 1./(1+m.^2).*(-2.4.*shape).*((cosh(z1)).^(-3).*sinh(z1)*dy1/dx1^2-cosh(z2).^(-3).*sinh(z2)*dy2/dx2^2)*X_DOT;
            Yita_ref_cell{p,1}=[phi_ref(p,1);Y_ref(p,1);phi_dot_ref(p,1)];
 
        end
    end
    Yita_ref=cell2mat(Yita_ref_cell);%�����ǵõ������Ԫ������ת��Ϊ����
    error_1=Yita_ref-PSI*kesi-GAMMA*PHI; %��ƫ��
    f_cell=cell(1,2);
    f_cell{1,1}=2*error_1'*Q*THETA;
    f_cell{1,2}=0;
%     f=(cell2mat(f_cell))';
    f=-cell2mat(f_cell);
    
 %% ����ΪԼ����������
 %������Լ��
    A_t=zeros(Nc,Nc);%��falcone���� P181
    for p=1:1:Nc
        for q=1:1:Nc
            if q<=p %�����Ǿ�������Խ���
                A_t(p,q)=1;
            else 
                A_t(p,q)=0;
            end
        end 
    end 
    A_I=kron(A_t,eye(Nu));%������ڿ˻�
%     Ut=kron(ones(Nc,1),U(1));
    Ut=kron(ones(Nc,1),U);%%%%%
    umin=[-0.1744;-1000];%ά������Ʊ����ĸ�����ͬ��ǰ��ƫ�ǵ���Լ�� %%%%%
    umax=[0.1744;1000];%ǰ��ƫ�ǵ���Լ�� %%%%%
    delta_umin=[-0.0148*0.4;-50];%ǰ��ƫ�Ǳ仯������Լ�� %%%%%
    delta_umax=[0.0148*0.4;50];%ǰ��ƫ�Ǳ仯������Լ�� %%%%%
    Umin=kron(ones(Nc,1),umin);%%%%%
    Umax=kron(ones(Nc,1),umax);%%%%%
    
    %�����Լ��
%     ycmax=[0.21;5];  %��ڽǺ�����λ�Ƶ�Լ��
%     ycmin=[-0.3;-3];
%     Ycmax=kron(ones(Np,1),ycmax);
%     Ycmin=kron(ones(Np,1),ycmin);
    
    %��Ͽ�����Լ���������Լ��
    A_cons_cell={A_I zeros(Nu*Nc,1);-A_I zeros(Nu*Nc,1)};
    b_cons_cell={Umax-Ut;-Umin+Ut};
%   A_cons_cell={A_I zeros(Nu*Nc,1);-A_I zeros(Nu*Nc,1);THETA zeros(Ny*Np,1);-THETA zeros(Ny*Np,1)};
%   b_cons_cell={Umax-Ut;-Umin+Ut;Ycmax-PSI*kesi-GAMMA*PHI;-Ycmin+PSI*kesi+GAMMA*PHI};
    A_cons=cell2mat(A_cons_cell);
    b_cons=cell2mat(b_cons_cell);
    
    %��������Լ��
    e_M=10; 
    delta_Umin=kron(ones(Nc,1),delta_umin);
    delta_Umax=kron(ones(Nc,1),delta_umax);
    lb=[delta_Umin;0];
    ub=[delta_Umax;e_M];
    
    %% ��ʼ������
       options = optimset('Algorithm','interior-point-convex');
       x_start=zeros(Nc*Nu+1,1);%����һ����ʼ�� %%%%%
      [X,fval,exitflag]=quadprog(2*H,f',A_cons,b_cons,[],[],lb,ub,x_start,options);
%       cost = cost + fval;
      fprintf('exitflag=%d\n',exitflag);
      if t == 0.025
          save("out.mat",'H','f','A_cons','b_cons','lb','ub');
      end
%       fprintf('H=%4.6f\n',H(1,1));
%       fprintf('f=%4.6f\n',f(1,1));
      fprintf('X(1)=%4.6f\n',X(1));
      fprintf('X(2)=%4.10f\n',X(2));
      fprintf('fval=%4.6f\n',fval);
    %% �������
    u_piao(1)=X(1);
    u_piao(2)=X(2);%%%%%
    U(1)=kesi(7,1)+u_piao(1);%%%%%
    U(2)=kesi(8,1)+u_piao(2);%%%%%
    
    
%     alphaf = (y_dot+lf*phi_dot)/x_dot-delta_f;
%     alphar = (y_dot-lr*phi_dot)/x_dot;
    alphaf = abs(atan((y_dot+lf*phi_dot)/x_dot)-delta_f);
    alphar = abs(atan((y_dot-lr*phi_dot)/x_dot));
    r=0.36;
    c=0.7;
    [Tbfl,Tbfr,Tbrl,Tbrr]=braking_cal(U(2),alphaf,alphar,r,c);
%     [Tbfl,Tbfr,Tbrl,Tbrr]=[1000,0,1000,0];
    sys= [U(1),U(2),Tbfl,Tbfr,Tbrl,Tbrr]; %%%%%
%     sys= [0,0,100,100,100,100]; %%%%%
    toc
% End of mdlOutputs.