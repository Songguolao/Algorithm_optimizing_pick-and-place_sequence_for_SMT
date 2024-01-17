%% SMT类
classdef SMT
    properties
        %元件种类及该种类的数量
        type_num
        %元件类型数量
        nK
        %元件坐标
        pos
        %元件号
        Designator
        %元件数量
        nC
        %贴片机原点坐标
        O_x
        O_y
        %喂料器坐标
        fe_pos
        %喂料器数量
        nS
        %贴片头坐标
        head_pos
        %贴片头数量
        head_num
        %移动速度
        v
        %贴片的周期
        R
        %元件型号（10uf、10k等，可能和论文不一致，论文可能指封装）
        K
        %种群（狮群算法使用）
        lives
        %个体（遗传算法中包含染色体（元件序列）、狮群算法中指狮子个体（元件序列））
        life
        %最好的个体
        best_life
        %最好的适应度值
        best_fit
        %最短距离
        best_dis
        % 最小准则系数
        eit
        % 第n代
        n
        % 最小准则
        MC_par
    end
    
    methods
        function self = Unit()
        end
    end
    
end