% 参数说明：个体1、个体2、交叉率、喂料器染色体交叉数量、组内交叉数量
% ce作为元件分组序列染色体应该只需要组间交叉就行了，而组内交叉交给pc和gc就行了，
% 两条再解码就能实现组内、组间元件都改变
%% 23年10月7日改：因对元件分组序列ce进行交叉，会出现相同元件序号，导致Dis_Sum函数内Match_LambIndex为多个数，
%% 更新吸头坐标会出现维数不一致问题
function [lif1,lif2] = Cross(t,T,self,li1,li2,cross_rate,FeCrossNum,InterCrossNum)
    if (unifrnd (0,1) < cross_rate)
        se = randperm(2,1);
        % #################################################################
        if se == 1 %使用基础交叉算子1
            %ce若进行遗传操作，会出现ce内含有相同元件序号，因此不应该对ce操作！！！
             r = randperm(length(li1.ce(:,1)),1);%随机选择一个循环进行父代的交叉
            temp = li2.ce(r,:);
            li2.ce(r,:) = li1.ce(r,:);
            li1.ce(r,:) = temp;
            
            temp = li2.pc(r,:);
            li2.pc(r,:) = li1.pc(r,:);
            li1.pc(r,:) = temp;
            
            temp = li2.gc(r,:);
            li2.gc(r,:) = li1.gc(r,:);
            li1.gc(r,:) = temp;
            % 组内交叉
            is = randperm(length(li1.pc(1,:)),InterCrossNum);
            for j = 1:InterCrossNum
                temp = li2.pc(r,j);
                if temp==0 || li1.pc(r,j) == 0
                    %排除0
                else
                    li2.pc(r,j) = li1.pc(r,j);
                    li1.pc(r,j) = temp;
                end
            end
            
              for j = 1:InterCrossNum
                temp = li2.gc(r,j);
                if temp==0 || li1.gc(r,j) == 0
                    %排除0
                else
                    li2.gc(r,j) = li1.pc(r,j);
                    li1.gc(r,j) = temp;
                end
              end
            
        end
        %% 喂料器交叉
         if se == 2
                %% 分段交叉数量
%                  if t<1/3*T 
                     FeCrossNum = 4;
%                  else
%                       FeCrossNum = 2;
%                  end
                %% log交叉函数
%                 FeCrossNum = round(log((T))+log((T))/2-t*log((T))/T);%每一代的群体数量计算
            %% 固定交叉数量
                 fs = randperm(self.nK,FeCrossNum);
                 for i = 1:FeCrossNum
                     temp = li2.fc(fs(i));
                     li2.fc(fs(i)) = li1.fc(fs(i));
                     li1.fc(fs(i)) = temp;
                 end        
         end
    end
        
    lif1 = li1;
    lif2 = li2;

end
