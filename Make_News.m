% 函数说明：输入种群进行遗传操作，SMT对象（包含最优个体及其适应值、距离）、返回遗传操作后的种群live、种群更新的所有best_dis(用来画图)
% 参数：SMT对象、种群、交叉概率、喂料器交叉的元件数量、组内元件交叉数量、扰动概率、变异概率
function [smt,live,best_dis,num,dis_] = Make_News(self,lives,cross_rate,FeCrossNum,InterCrossNum,p_n,p_m,t,T,pop_size,numm,dis)
    for li = 1:pop_size/2
        %% 步骤2：计算最小准则MC
        self.MC_par = Count_Mc(self);
        %% 多群体GA
        P= T;
%         S = round(log(sqrt(P))+log(sqrt(P))/2-t*log(sqrt(P))/T);%每一代的群体数量计算
        S = 1;
        %产生多种群的子代
        for j = 1:S
           %% 步骤3：交叉
             [child1_S(j),child2_S(j)] = Cross(t,T,self,lives(li),lives(pop_size-li),cross_rate,FeCrossNum,InterCrossNum);
%              [child1_S(j),child2_S(j)] = new_cross(self,lives(li),lives(pop_size-li));
            %% 步骤4：变异
            if unifrnd (0,1) < p_m
                child1_S(j) = Mut(lives(li),p_n,self.nC,self.head_num);
                child2_S(j) = Mut(lives(pop_size-li),p_n,self.nC,self.head_num);
            end
            %% 步骤5：局部搜索算子
            % 论文《最小准则遗传算法求解贴片机贴装调度问题_武洪恩》指出：局部搜索在组合优化问题中起着重要的作用，
            % 设计有效的局部搜索算子可以提高子代个体的质量
             child1_S(j) = Local(self,child1_S(j));%若LOCAL产生了更优的子代，则会返回优子代，而cross、Mut内部不会计算适应值
             child2_S(j) = Local(self,child2_S(j));
             %% 2opt更新
             rand_rate = 0.9;
%              child1_S(j) = LSO_2opt_Mut(self,child1_S(j),rand_rate,FeCrossNum);
%              child2_S(j) = LSO_2opt_Mut(self,child2_S(j),rand_rate,FeCrossNum);
             %% 逆转操作
%              child1_S(j) = GA_reverse(child1_S(j));
%              child2_S(j) = GA_reverse(child2_S(j));
             if child1_S(j).fitness < child2_S(j).fitness
                 child1_S(j) = child2_S(j);
             end
            for lli = 1:pop_size
                if lives(lli).fitness == child1_S(j).fitness
                    break
                end
                lives(end+1) = child1_S(j);
                lives(1) = [];
            end  
        end
        %适应度降序排列
        for j = 1:S-1
            if child1_S(j).fitness < child1_S(j+1).fitness
                temp = child1_S(j);
                child1_S(j) = child1_S(j+1);
                child1_S(j+1) = temp;
            end
        end
        child1 = child1_S(1);%选出适应度最大的子代
        child2 = child2_S(1);%选出适应度最大的子代

        [child1.fitness,child1.dis_sum] = Count_Fit(self,child1);
        [child2.fitness,child2.dis_sum] = Count_Fit(self,child2);%调用Count_Fit将会解码个体序列以及计算距离和适应值
        if child1.fitness > self.best_fit
            self.best_life = child1;
            self.best_fit = child1.fitness;
            self.best_dis = child1.dis_sum;
            disp("得到新的优代距离")
            best_dis = self.best_dis
        end

        if (child2.fitness > self.best_fit) && (child2.fitness > child1.fitness)
            self.best_life = child2;
            self.best_fit = child2.fitness;
            self.best_dis = child2.dis_sum;
            disp("得到新的优代")
            best_dis = self.best_dis
        end
        %% 步骤6：选择与淘汰
         % 新产生的子代个体适应值如果大于上一代计算出的最小准则适应值（即认为比上一代大部分个体更优秀）则保留到下一代种群
        if child1.fitness > self.MC_par
            lives(end+1) = child1;
            lives(1) = [];%！！！同时删掉一个不太好的个体保证种群大小不变（其实种群内的个体应该按照适应度从小到大排列，但是计算量太大）
        end
        if child2.fitness > self.MC_par
            lives(end+1) = child2;
            lives(1) = [];
        end
        %% 步骤7：精英策略，最优个体若在种群中不做处理，若不在，则插入种群，再删掉一个
        % 
        for lli = 1:pop_size
            if lives(lli).fitness == self.best_fit
                break
            end
            lives(end+1) = self.best_life;
            lives(1) = [];
        end    
        alpha = decode(self.life.ce,child1.pc);
        dis(numm) = self.best_dis;
        if numm >1
            line([numm - 1, numm], [dis(numm-1), dis(numm)],'color','r'); pause(0.001)
        end
        numm=numm+1;
    end
    live = lives;
    smt = self;
    best_dis = dis;
    num = numm;
    dis_ = dis;
end
