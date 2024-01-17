% 扰动函数参数说明：输入染色体、扰动概率、染色体长度
function code_ = Noise(code,p_n,len_u)
    len_n = length(code);
    for i=1:len_u
        if unifrnd (0,1) < p_n
            code(i) = randperm(len_n-len_u+i,1);
        end
    end
    code_ = code;
end