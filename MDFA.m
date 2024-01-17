%% 输入的个体PC、gc分组内组间
function [life,dis] = MDFA(Smt,life_parent1,life_parent2)
    child_life = life_parent1;
    row = length(life_parent1.pc(:,1));
    col = length(life_parent1.pc(1,:));
    pc1 = life_parent1.pc;
    gc1 = life_parent1.gc;
    pc2 = life_parent2.pc;
    gc2 = life_parent2.gc;
    fc1 = life_parent1.fc;
    fc2 = life_parent2.gc;
    D = col;
    PC_Dij = zeros(row,col);%Di,j(t)
    PC_AV = zeros(row,col);%PC_AVj,k(t)
    PC_delta_D = pc2;%△Di,j(t)
    PC_R1 = PC_AV;%PC_R1i,j(t)
    %% 计算pc
    % 计算pc的Di,j(t)
    for i = 1:row
        for j = 1:col
            if pc1(i,j) == pc2(i,j)
                PC_Dij(i,j) = 0;
            else
                PC_Dij(i,j) = pc2(i,j);
            end
        end
    end
    % 计算PC_R1i,j(t)
    for i = 1:row
        for j = 1:col
            if PC_delta_D(i,j) > 2
                PC_R1(i,j) = (PC_delta_D(i,j) - 2)/D;
            else
                PC_R1(i,j) = 0;
            end
        end
    end
    
    % 计算PC_AVj,k(t)
    for i = 1:row
        for j = 1:col
            R = rand();
            if R >= PC_R1(i,j)
                PC_AV(i,j) = 0;
            else
                PC_AV(i,j) = 1;
            end
        end
    end
    % 计算△Di,j(t)
    for i = 1:row
        for j = 1:col
            if PC_AV(i,j) == 1
                PC_delta_D(i,j) = PC_Dij(i,j);
            else
                PC_delta_D(i,j) = 0;
            end
        end
    end
    % 计算Xj(t+1)
    for i = 1:row
        for j = 1:col
                if PC_delta_D(i,j)~= 0 
                    child_life.pc(i,j) = PC_delta_D(i,j);
                end
        end
    end
    %% 计算gc
    GC_Dij = zeros(row,col);%Di,j(t)
    GC_AV = zeros(row,col);%GC_AVj,k(t)
    GC_delta_D = gc2;%△Di,j(t)
    GC_R1 = GC_AV;%GC_R1i,j(t)
    % 计算gc的Di,j(t)
    for i = 1:row
        for j = 1:col
            if gc1(i,j) == gc2(i,j)
                GC_Dij(i,j) = 0;
            else
                GC_Dij(i,j) = gc2(i,j);
            end
        end
    end
    % 计算GC_R1i,j(t)
    for i = 1:row
        for j = 1:col
            if GC_delta_D(i,j) > 2
                GC_R1(i,j) = (GC_delta_D(i,j) - 2)/D;
            else
                GC_R1(i,j) = 0;
            end
        end
    end
    
    % 计算GC_AVj,k(t)
    for i = 1:row
        for j = 1:col
            R = rand();
            if R >= GC_R1(i,j)
                GC_AV(i,j) = 0;
            else
                GC_AV(i,j) = 1;
            end
        end
    end
    % 计算△Di,j(t)
    for i = 1:row
        for j = 1:col
            if GC_AV(i,j) == 1
                GC_delta_D(i,j) = GC_Dij(i,j);
            else
                GC_delta_D(i,j) = 0;
            end
        end
    end
    % 计算Xj(t+1)
    for i = 1:row
        for j = 1:col
                if GC_delta_D(i,j)~= 0 
                    child_life.gc(i,j) = GC_delta_D(i,j);
                end
        end
    end
    %% 计算fc
    FeCrossNum = 4;
    sel = randperm(3,1);
    % 喂料器交叉
    if sel == 1
        fs = randperm(length(life_parent1.fc),FeCrossNum);
        for i = 1:FeCrossNum
            temp = child_life.fc(fs(i));
            child_life.fc(fs(i)) = life_parent1.fc(fs(i));
            life_parent1.fc(fs(i)) = temp;
        end
     end 
   %% 喂料器变异
    if sel == 2
        ss = randperm(Smt.nK,1);
        child_life.fc(ss) = randperm(ss,1);
    end
    % 扰动
    p_n = 0.05;%扰动概率
    if sel == 3
        child_life.fc = Noise(child_life.fc,p_n,length(child_life.fc));
    end
    [life_parent1.fitness,life_parent1.dis_sum] = Count_Fit(Smt,life_parent1);
    [child_life.fitness,child_life.dis_sum] = Count_Fit(Smt,child_life);%调用Count_Fit将会解码个体序列以及计算距离和适应值
    if life_parent1.dis_sum <= child_life.dis_sum
        child_life = life_parent1;
    else

    end
   if child_life.fitness > Smt.best_fit
        Smt.best_life = child_life;
        Smt.best_fit = child_life.fitness;
        Smt.best_dis = child_life.dis_sum;
        disp("得到新的优代")
        Smt.best_dis
   end
   life = child_life;
   dis = Smt.best_dis;
end