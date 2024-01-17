% 喂料器从喂料槽中间向两边排列
% 输入参数：喂料器染色体（也是喂料器元件类型序列）fc、喂料槽数量
function code = Feeder_Code(lame,nS)
    lam = zeros(1,nS);
    init_pos = floor((nS-length(lame))/2);
    lam(1,init_pos+1:init_pos+length(lame)) = lame;%将所需元件类型放置到喂料槽中间位置
    code = lam;
end