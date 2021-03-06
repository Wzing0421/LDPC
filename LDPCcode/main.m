load H_index.mat;
load H_index_len.mat;
load Hst.mat;
load H_ldpc.mat;
load H_var.mat;
load H_var_len.mat

error_framerate = zeros(1,7);
error_bitrate = zeros(1,7);
error_limit = [50,40,30,20,10,10,5];

%itertimes = 30;%最多循环迭代30次就结束
for snr = -4:0.5:-1
    
    %错误帧数量
    totalerror_framenum = 0;
    %错误比特数量
    totalerror_bitnum = 0;
    lp = 0; %记录总的循环次数
    while 1
        lp = lp+1;
        %产生随机序列1x1008
        Input = ceil(rand(1,1008)*2)-1;
        %将1x1008位信息序列编码成1x2016位
        LDPCEnCode = Encode(Input,Hst);

        %BPSK调制
        LDPCSend = 1-2*LDPCEnCode;
        %经过RsChannel信道加噪声,SNR = EbN0+10lg(2);
        LDPCRecv = awgn(LDPCSend,snr+3);
       
        
        %接收之后的第一步，初始化,获得初始的软信息
        y_snr = 10^(snr/10);
        LDPCRecv = 4 * LDPCRecv * y_snr;
        
        u = zeros(1008,2016);
        v = zeros(2016,1008);
        %第一种算法，和积算法
        %[isSuc, errorframenum, errorbitnum] = Decode_SumMul( LDPCRecv, H_index, H_index_len, H_var, H_var_len, u, v, H_ldpc, LDPCEnCode, 0.5 );
        %第二种算法，最小和算法，和第三种算法相比相当于设置α=1
        %[isSuc, errorframenum, errorbitnum] = Decode_MinSum( LDPCRecv, H_index, H_index_len, H_var, H_var_len, u, v, H_ldpc, LDPCEnCode, 1 );
        %第三种算法，归一化最小和算法，将α设置为0.7
        %[isSuc, errorframenum, errorbitnum] = Decode_MinSum( LDPCRecv, H_index, H_index_len, H_var, H_var_len, u, v, H_ldpc, LDPCEnCode, 0.7 );
        %第四种算法，偏置最小和算法，将β设置为0.5
        [isSuc, errorframenum, errorbitnum] = Decode_MinSumBeta( LDPCRecv, H_index, H_index_len, H_var, H_var_len, u, v, H_ldpc, LDPCEnCode, 0.5 );
        
        totalerror_framenum = totalerror_framenum + errorframenum;
        totalerror_bitnum = totalerror_bitnum + errorbitnum;
        
        if(isSuc ==0) %译码中出现了错误
            fprintf('第 %d 帧出现了错误！\n',lp);
            fprintf('snr = %d 错误帧数 ：%d\n', snr,totalerror_framenum);
            fprintf('snr = %d 错误比特数 ：%d\n', snr,totalerror_bitnum);
        else
            fprintf('第 %d 帧没出现错误！\n',lp);
            fprintf('snr = %d 错误帧数 ：%d\n', snr,totalerror_framenum);
            fprintf('snr = %d 错误比特数 ：%d\n', snr,totalerror_bitnum);
        end
        
        %循环退出的判决条件
        if(totalerror_framenum > error_limit(1,round(2 * snr + 9))) 
            break;
        end
        
    end
    
    error_framerate(1,round(2 * snr + 9)) = totalerror_framenum/lp;
    error_bitrate(1,round(2 * snr + 9)) = totalerror_bitnum/(lp*1008);
    
end

%将误比特率和误码率存储起来
save('MinSum_biasBeta_error_framerate','error_framerate')
save('MinSum_biasBeta_error_bitrate','error_bitrate')
x = -1:0.5:2;
semilogy(x,error_framerate,'-*r', x,error_bitrate,'-ob' );
title ('LDPCCode Performace');
xlabel('Eb/N0'); 
ylabel('误符号率/误帧率');
legend('Error Frame Ratio','Error Symbol Ratio');
grid on;




