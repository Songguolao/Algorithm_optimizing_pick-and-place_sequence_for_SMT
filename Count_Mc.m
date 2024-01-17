%函数说明：计算最小准则函数值
%由于matlab无法实现函数内对参数成员赋值（如SMT.MC_par = MC_par），所以需要返回MC_par给SMT.MC_par赋值
function MC_par = Count_Mc(SMT)
    rou  = 1 - exp(1 - SMT.n^(SMT.eit/exp(1)));
    MC_par = rou * SMT.best_fit;% 论文的最小准则函数需要计算每一代的最差个体，但这样计算时间太长了，所以这里只考虑最优个体。。。
end
