% 函数说明：计算适应值函数
% 参数：smt类、个体类
function [Fit,dis]= Count_Fit(Smt,life)
    alpha = decode(life.ce,life.pc); %解码贴放序列alpha（通过ce和pc解码）
    zeta = decode(life.ce,life.gc); %贴头元器件的分配zeta（ce、gc）
    lame = decode(life.fe,life.fc);%喂料器元件分布序列
    lamb = Feeder_Code(lame,life.nS);%供料槽元器件类型分配lamb
    dis = Dis_Sum(Smt,alpha,zeta,lamb);
    Fit = 1000/dis;%以距离的倒数作为适应值，因计算的距离数值较大所以倒数值放大一千倍
end