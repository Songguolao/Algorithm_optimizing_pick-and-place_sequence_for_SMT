%len一般是index的长度，即染色体长度，通常每次输入一段序列(4吸头len则为4),解码喂料器时输入喂料槽的数量len=nS
%% 后面发现喂料器序列其实可以不用解码，直接用序列作为染色体进行遗传操作
% 输入参数：ce、pc/gc、pc/gc列数
function decode_ = decode(code,index)
    for i = 1:length(index(:,1))
        decode_temp = zeros(1,length(index(1,:))); %必须先添上和index列数一样的0，防止下面的数组越界
        for ii=1:length(index(i,:))
            n=index(i,ii); %插入的位置a
            if n==1
                decode_temp=[code(i,ii),decode_temp(1:end)]; %后面的数后移一位
            end
            if n~=1
                decode_temp = [decode_temp(1:n-1),code(i,ii),decode_temp(n:length(decode_temp))]; 
            end
        end
        %find(decode_temp == 0)
        %decode_temp;
        decode_temp(find(decode_temp == 0)) = [];%将最初添加的0再全部删掉
        % ##############################################
        for j = length(decode_temp):length(index(i,:))-1
            decode_temp(j+1) = 0;%最后一个循环会有0序号的元件，由于上面把0都删掉了，导致长度不等于code的长度，因此添0补齐
        end
        decode_temp;
        decode_(i,:) = decode_temp;
    end
        
end
