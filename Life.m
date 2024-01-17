classdef Life 
    properties
        fc
        fe
        ce
        pc
        gc
        nS
        lso_mnsc_sequen
        %% 使用Count_Fit函数可获取以下的数值
        fitness %适应值
        dis_sum %总距离
        alpha %解码的贴放序列（通过ce和pc解码）
        zeta %解码的贴装头元器件分布（ce、gc）
        lamb %解码的喂料器在喂料槽上的分配
        
    end
        % 外部可调用的方法
    methods
        function self = Life(fc,fe,ce,pc,gc,nS)
            % 调用父类构造函数设置参数
             self.fc = fc;%喂料器染色体
             self.fe = fe;%初始解的喂料器序列
             self.ce = ce;%初始解的元件序列（吸嘴元件分配序列）
             self.pc = pc;%贴放元件染色体
             self.gc = gc;%吸头元件分布染色体
             self.fitness = 0;%该个体的适应度值
             self.nS  = nS;%喂料槽数量（喂料器要均匀分布在喂料槽，因此需要知道数量）
        end
    end 
end