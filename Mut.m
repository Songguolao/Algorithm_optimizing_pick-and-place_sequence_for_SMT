% 参数说明：个体、扰动概率、元件数量、吸头数量
function li0 = Mut(lif,p_n,nc,head_num)
    li0 = lif;
    R = length(li0.pc(:,1));
    for lic = 1:R
        li0.pc(lic,:) = Noise(li0.pc(lic,:),p_n,length(li0.pc(lic,:)));
        li0.gc(lic,:) = Noise(li0.gc(lic,:),p_n,length(li0.gc(lic,:)));
    end
    li0.fc = Noise(li0.fc,p_n,length(li0.fc));
    for ceq1 = 1:nc
        if unifrnd (0,1) < p_n
            ceq2 = randi([ceq1,nc]);%ceq1~nc的1个随机整数作为变异的交换对象
            r1 = floor(ceq1/head_num);%要变异的元件在第几次循环
            if r1 == 0 
                r1 = 1; %防止为0
            end
            r2 = floor(ceq2/head_num);%
            if r2 == 0
                r2 = 1;
            end
            i1 = rem(ceq1,head_num);
            if i1 == 0
                i1 = 1;
            end
            i2 = rem(ceq2,head_num);
            if i2 == 0
                i2 = 1;
            end
            temp = li0.pc(r2,i2);
            li0.pc(r2,i2) = li0.pc(r1,i1);
            li0.pc(r1,i1) = temp; %变异本质上也是交换两个序号
        end
    end
end
            
            
            