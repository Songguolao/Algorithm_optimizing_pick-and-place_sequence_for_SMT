function Dis_Sum_ = Dis_Sum(smt,alpha,zeta,lamb)
    %% 参数说明：
    % self:元件类
    %  alpha:贴放序列
    %  zeta:贴装头元器件的分配，如[1,3,2,4;90,103,104,117]
    %  个人觉得拾取序列和头元件分配序列可以只考虑一个,因此只使用zeta，即认为zeta = beta ！！！
    %  lamb:供料槽元器件类型分配
    Dss = 0;
    Dsp = 0;
    Dpp = 0;
    Dps = 0;
    for i=1:length(zeta(:,1)) % 行数
        if ismember(0,zeta(i,:))
            len = find(zeta(i,:) == 0)-1;%最后一个循环元件数可能小于吸头数，会在后面补零
        else
            len = length(zeta(i,:));
        end
        %% 拾取元件i供料槽到元件j供料槽距离和Dss,认为贴装头的元器件排布和数组一致，即第一次循环依次拾取1，3，2，4号元件
        for j=1:len
            Match_LambIndex = find(cellfun(@(x) ismember(zeta(i,j),x),smt.type_num(:,3)));%找到贴头具体元件序号在元件类型中的第几行（即元件属于哪种元件类型，才能与喂料器的元件类型匹配）
            Match_LambSequen = find(lamb == Match_LambIndex);%该元件类型在喂料器的位置序号
            Dss_Abs = Compute_Dis(smt.head_pos(j,:),smt.fe_pos(Match_LambSequen,:));%每次吸头移动距离的绝对值
            Dss = Dss + Dss_Abs;%每个吸头在喂料器上吸取元件移动的距离和
            % 更新所有吸头的位置
            X_Dis = smt.fe_pos(Match_LambSequen,1) - smt.head_pos(j,1); % X轴移动距离
            Y_Dis = smt.fe_pos(Match_LambSequen,2) - smt.head_pos(j,2); % Y轴移动距离
            smt.head_pos(:,1) = smt.head_pos(:,1)+X_Dis;%% 更新所有吸头位置，由于吸头吸取元件只沿x轴移动，因此x坐标+移动距离
            smt.head_pos(:,2) = smt.head_pos(:,2)+Y_Dis;
            
        end
       %% 供料槽移动到PCB第一个贴放位置的距离和Dsp
        % 认为alpha[i,1]是第一个贴放元件
        Match_HeadIndex = 0;
        Match_HeadIndex = find(zeta(i,:) == alpha(i,1));%找到第一个贴放元件对应吸头序号,吸头若存在相同元件序号Match_HeadIndex会有多个值，导致更新吸头坐标出错
%         if length(Match_HeadIndex)~=1
%             pause(5)
%         end
        Dsp_Abs = Compute_Dis(smt.head_pos(Match_HeadIndex,:),smt.pos(alpha(i,1),:));
        Dsp = Dsp + Dsp_Abs; %叠加每次循环,吸头移动到第一个元件的距离
        % 更新所有吸头的位置
        X_Dis = smt.pos(alpha(i,1),1) - smt.head_pos(Match_HeadIndex,1); % X轴移动距离
        Y_Dis = smt.pos(alpha(i,1),2) - smt.head_pos(Match_HeadIndex,2); % Y轴移动距离
        smt.head_pos(:,1) = smt.head_pos(:,1) + X_Dis;% 更新每个吸头的X坐标
        smt.head_pos(:,2) = smt.head_pos(:,2) + Y_Dis;% 更新每个吸头的Y坐标
       %% PCB上前后贴放的元件i到元件j的距离和Dpp
        for j=1:len
            if j<len
                Dpp_Abs = Compute_Dis(smt.pos(alpha(i,j),:),smt.pos(alpha(i,j+1),:)); % 每次移动的距离
                Dpp = Dpp + Dpp_Abs;
                % 更新所有吸头的位置
                X_Dis = smt.pos(alpha(i,j+1),1) - smt.pos(alpha(i,j),1); % X轴移动距离
                Y_Dis = smt.pos(alpha(i,j+1),2) - smt.pos(alpha(i,j),2); % Y轴移动距离
                smt.head_pos(:,1) = smt.head_pos(:,1) + X_Dis;% 更新每个吸头的X坐标
                smt.head_pos(:,2) = smt.head_pos(:,2) + Y_Dis;% 更新每个吸头的Y坐标
            end
        end

       %% 每一轮循环PCB移动到供料槽的距离和Dps,由于返回了喂料器，因此需要更新吸头位置，以便新的拾取循环开始计算吸头在喂料器上的移动距离
        if i < length(zeta(:,1)) % 不是最后一次取贴循环，则是返回到喂料器
            if zeta(i+1,1) == 0 %第一个元件为0特殊处理
                ind = find(zeta(i+1,:)==0);
                ze = zeta(i+1,length(ind)+1);%进行组内交换后，补零位置会移动，所以避免第一个元件为0
                Match_LambIndex = find(cellfun(@(x) ismember(ze,x),smt.type_num(:,3))); %下一个循环第一个拾取元件对应的元件类型
            else
                Match_LambIndex = find(cellfun(@(x) ismember(zeta(i+1,1),x),smt.type_num(:,3))); %下一个循环第一个拾取元件对应的元件类型
            end
            
            Match_LambSequen = find(lamb == Match_LambIndex);%该元件类型在喂料器的位置序号
            Pos1 = smt.pos(alpha(i,j),:);
            Pos2 = smt.fe_pos(Match_LambSequen,:);
%             Dps_Abs = Compute_Dis(smt.pos(alpha(i,j),:),smt.fe_pos(Match_LambSequen,:)); 
            Dps_Abs = sqrt((Pos1(1,1)-Pos2(1,1))^2+(Pos1(1,2)-Pos2(1,2))^2);%本次循环最后一个贴放元件的PCB坐标到下一个循环第一个拾取元件在喂料器的距离
            Dps = Dps + Dps_Abs;
            % 更新所有吸头的位置
            X_Dis = smt.fe_pos(Match_LambSequen,1) - smt.pos(alpha(i,j),1); % X轴移动距离
            Y_Dis = smt.fe_pos(Match_LambSequen,2) - smt.pos(alpha(i,j),2);  % Y轴移动距离
            smt.head_pos(:,1) = smt.head_pos(:,1) + X_Dis;% 更新每个吸头的X坐标
            smt.head_pos(:,2) = smt.head_pos(:,2) + Y_Dis;% 更新每个吸头的Y坐标
        else % 最后一次其实是返回到原点，而不是喂料器，也不必再更新吸头位置
            % #############################################################
            j = find(alpha(i,:) == 0);%找到补零位置
            Pos1 = smt.pos(alpha(i,j(1)-1),:);%第一个补零位置的前一个元件就是最后一个元件
            Pos2 = [0,0];% 原点就设为0，0吧，如果有问题则改为self.0_x,self.0_y
            dis_end = sqrt((Pos1(1,1)-Pos2(1,1))^2+(Pos1(1,2)-Pos2(1,2))^2);
        end
    end
    Dis_Sum_ =  Dss + Dsp + Dpp + Dps+dis_end;
end