% 函数说明：局部搜索算子，目的是在局部范围内进行交叉/变异，可能获取到更优的个体
function li = Local(Smt,lie)
    lie1 = lie;
    [lie1.fitness,lie1.dis_sum] = Count_Fit(Smt,lie1);% 计算适应度
    lie0 = lie;
    R = randperm(Smt.R,1);% 随机选择一个循环
    sel = randperm(4,1);% 随机选择一个步骤
    %% 放置元件组组交换
    if sel == 1
        w = randperm(length(lie0.ce(R,:)),1);
        lie0.pc(R,w) = randperm(w,1);
    end
    %% 贴头分配元件组内变异
    if sel == 2
        w = randperm(length(lie0.ce(R,:)),1);
        lie0.gc(R,w) = randperm(w,1);
    end
    %% 喂料器变异
    if sel == 3
        ss = randperm(Smt.nK,1);
        lie0.fc(ss) = randperm(ss,1);
    end
    %% 组间交换
    if sel == 4 
        i1 = randperm(Smt.R,1);%随机选择一个循环
        i2 = randperm(Smt.R,1);
        q1 = randperm(length(lie0.pc(i1,:)),1);%随机选择循环内的元件
        q2 = randperm(length(lie0.pc(i2,:)),1);
        temp = lie0.pc(i1,q1);
        if temp == 0 || lie0.pc(i2,q2) == 0
            %！！！有一定概率选到0，选到0就什么也不做
        else 
            lie0.pc(i1,q1) = lie0.pc(i2,q2);
            lie0.pc(i2,q2) = temp;
        end
    end
    [li0.fitness,lie0.dis_sum] = Count_Fit(Smt,lie0);
    if li0.fitness > lie1.fitness
        lie1 = lie0;
    end
    li = lie1;
end