%函数说明：元件序列解码为元件类型序列
function type = decode_compo_to_type(Smt,compo)
    for i = 1:length(compo(:,1))
        for j = 1:length(compo(i,:))
            match_type = find(cellfun(@(x) ismember(compo(i,j),x),Smt.type_num(:,3))); %元件对应的元件类型
            if length(match_type) == 0
                type(i,j) = 0;
            else
                type(i,j)  = match_type;
            end
        end
    end
end