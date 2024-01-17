%% 函数说明：测试狮群算法MNSC，当操作的序列不分为组内、组间，不符合贴片机贴片的实际运况，导致难以产生适应值更高的序列，
%% 因此尝试MNSC操作只改变每组元件的顺序，从1~smt.R编码，最后通过该函数解码获取到真实的组间序列
%% 参数说明：code为smt.R行，smr.head_num列的数组，而index为smt.R个元素的向量
function decode_ = Inter_Group_Decode(code,index)
    decode_temp = zeros(1,length(code(1,:))*length(code(:,1))); %必须先添上和code数量一样的0，防止下面的数组越界
    len = length(decode_temp);
    head_num = length(code(1,:));%记录一组循环的元件数，方便后面移动组
    for i = 1:length(index)
            n=index(i); %插入的位置a
            if n==1
                decode_temp(1:head_num)=code(i,:); %后面的组后移一位
            end
            if n~=1
                length(decode_temp);
                decode_temp = [decode_temp(1:(n-1)*head_num),code(i,:),decode_temp(n*head_num+1:len)]; 

            end
        end
        %find(decode_temp == 0)
        %decode_temp;
        decode_temp(find(decode_temp == 0)) = [];%将最初添加的0再全部删掉
        decode_ = decode_temp;
end