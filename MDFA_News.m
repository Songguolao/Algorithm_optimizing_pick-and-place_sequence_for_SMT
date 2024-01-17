% 函数说明：输入种群进行遗传操作，SMT对象（包含最优个体及其适应值、距离）、返回MDFA操作后的种群live、种群更新的所有best_dis(用来画图)
% 参数：SMT对象、种群、当前迭代次数、总迭代次数
function [smt,live,best_dis,num,dis_] = MDFA_News(self,lives,t,T,numm,dis)
    pop_size = length(lives);
    P = T;
    S = 1;
    for li = 1:pop_size/2
%         %% 计算最小准则MC
%         self.MC_par = Count_Mc(self);
        %% 多群体MDFA（实际上GA_MC和多领域GA也能用）
%         S = round(log(sqrt(P))+log(sqrt(P))/2-t*log(sqrt(P))/T);%每一代的群体数量计算
        %产生多种群的子代
        for j = 1:S
            child(j) = MDFA(self,lives(li),lives(pop_size-li));
            for lli = 1:pop_size
                if lives(lli).fitness == child(j).fitness
                    break
                end
                lives(end+1) = child(j);
                lives(1) = [];
            end  
        end
        %适应度降序排列
        for j = 1:S-1
            if child(j).fitness < child(j+1).fitness
                temp = child(j);
                child(j) = child(j+1);
                child(j+1) = temp;
            end
        end
        child1 = child(1);%选出适应度最大的子代
%         child1 = MDFA(self,lives(li),lives(pop_size-li));
        [child1.fitness,child1.dis_sum] = Count_Fit(self,child1);%调用Count_Fit将会解码个体序列以及计算距离和适应值
        if child1.fitness > self.best_fit
            self.best_life = child1;
            self.best_fit = child1.fitness;
            self.best_dis = child1.dis_sum;
            disp("得到新的优代")
            best_dis = self.best_dis
            disp("种群数量")
            S
        end
        %% 精英策略，最优个体若在种群中不做处理，若不在，则插入种群，再删掉一个
        % 
        for lli = 1:pop_size
            if lives(lli).fitness == self.best_fit
                break
            end
            lives(end+1) = self.best_life;
            lives(1) = [];
        end    
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
