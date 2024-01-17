%% 8月10日~14日：元件坐标解析、喂料器、吸头初始化
%% 8月23日~ 9月1日 
%1.分三种情况分配吸嘴循环：元件类型大于吸头数、元件类型小于吸头数且元件数量大于吸头数、元件数量小于吸头数
%2.喂料器分配
%3.解决最后一个吸嘴分配循环导致删掉最后一个jk索引的bug
%4.终于写完模型的代码了...
%% 9月4日~ 10月9日
% 1.解决元件分配pl出现重复元件索引值的bug（在拾取贴装顺序模块代码的两个条件判断内添加min_ComIndex = rg_CompIndex(1);）
% 2.理清元件顺序与染色体编解码的原理
% 3.编写距离计算函数Dis_Sum、适应度计算函数Count_Fit、喂料器排列函数Feeder_Code
% 4.完成遗传算法的交叉函数Cross、变异函数Mut、局部搜索算子Local
% 5.完成最小准则MC函数，至此最小准则遗传算法求解贴片路径代码已全部完成！
% 6.解决迭代次数多了之后Dis_Sum函数内更新吸头坐标出现矩阵维度不一致的bug（解决方法是不对元件分组序列ce进行遗传操作）
%% 10月7日~10月26日

%% 代码规范
%1.模块化编程，层次清晰，方便调试，方便多人协作（例如一人负责建模，一人负责算法）
%2.注释清晰，对可能影响后续开发的程序做特别注释,此程序使用长#注释易出bug的地方（例如数据格式可能不匹配算法）
%3.保留必要的调试程序（例如打印生成的元件坐标是否正确）
%4.合适的缩进，一眼就能看出循环、条件判断的范围
%% 清理之前的数据
% 清除所有数据
clear all;
% 清除窗口输出
clc;
%% SMT模型参数
%因此后面考虑将SMT模型参数全部放入component类中
% 模型、代码参考自《贴片机贴装调度综合优化方法研究_王凯》
head_space = 15;%贴头间距mm
head_num = 4; %贴头数量，后面的四个类型索引都指四吸头
feeder_space = 15; %喂料器间距mm
feeder_num = 50;% 喂料槽数量
ANC_pos_x = 800;
ANC_pos_y = 150; 
t_A = 1.0; %吸嘴更换时间s，还是固定吸嘴来测试吧，否则吸嘴分配比较麻烦
O_y = 30; %PCB定位点y坐标
v = 1000; %移动速度mm/s


%% 解析PCB坐标文件,元件类型，丝印号
%结构体存储每个元件坐标、对应元件的Designator（c1、c2等）、Comment（100uf、1uf、10kΩ等）
addpath('../PCB')
addpath('./MDFA')
addpath('./LSO_MNSC')
addpath('./GA_PC')
PCB_File = 'M01.csv';                       %读取PCB坐标文件，注意表格格式要符合通用csv和xlsx
[num,Comment] = xlsread(PCB_File,'A2:A144'); %第一列在excel中为 A+数字，num是数字矩阵，Comment是文字部分的元胞数组
tabu = tabulate(Comment);%计算第一列各类字符串出现的频次，返回值为元胞类型
self = SMT;%SMT对象
self.nC = size(Comment,1);%元件数量
self.K = cell(self.nC,2);
%存储所有元件及对应序号，等效于python pandas的Series数据结构！！
for i = 1:self.nC
    self.K(i,1) = Comment(i);%后面需要和self.nK比较，所以以元胞赋值
    self.K{i,2} = i;
end
type_num =  tabu(:,1:2);
self.type_num = cell(size(type_num(:,2),1),3);%3列，分别存储元件类型名、该类型元件的数量、该元件类型在self.K的索引
self.type_num(:,1:2) =  tabu(:,1:2);%存储每种元件类型名及数量(后面可能需要将cell转为数值类型)
self.nK = size(self.type_num(:,2),1);% 存储元件类型数,PS:因论文是手动匹配元件和吸嘴，所以没有解析封装信息
[num,self.Designator] = xlsread(PCB_File,'E2:E144');%读取元件丝印号
self.Designator;
%% 解析元件坐标
[num,x] = xlsread(PCB_File,'C2:C144');%读取元件x坐标
x = strrep(x,"mm","");%去掉mm单位
for i=1:self.nC
    self.pos(i,1)=str2num(x(i));%将字符串转化为double类型
end
self.pos(:,1);

[num,y] = xlsread(PCB_File,'D2:D144');%读取元件y坐标
y = strrep(y,"mm","");%去掉mm单位
for i=1:self.nC
    self.pos(i,2)=str2num(y(i));%将字符串转化为double类型
end
self.pos;
%% 以喂料器中心位置 - 距离最远两个元件的中心位置重新计算元件坐标，喂料器，贴片头坐标
max_x = max(self.pos(:,1),[],1); %求元件x坐标最大值
min_x = min(self.pos(:,1),[],1); %求元件x坐标最小值（负数）
self.O_x = feeder_space * int16(feeder_num / 2.0) - (max_x - min_x) / 2.0; %求整个贴片机系统的原点x坐标
self.O_y = O_y; %原点y坐标 = PCB定位点y坐标
self.pos(:,1)=self.pos(:,1)+double(self.O_x);%更新所有元件的x坐标
self.pos(:,2)=self.pos(:,2)+double(self.O_y);%更新所有元件的y坐标
for i = 1:feeder_num
self.fe_pos(i,1) = feeder_space * i;   %喂料器x坐标
self.fe_pos(i,2) = 0;%喂料器y坐标
end
self.nS = feeder_num;
%初始化贴片头坐标
for i = 1:head_num
self.head_pos(i,1) = head_space * i;   
self.head_pos(i,2) = 0;
end
self.head_num = head_num;
%不更换吸嘴，所以不考虑ANC
self.v = v;
self.R = ceil(self.nC / self.head_num);% 计算贴片周期
%% 初始解的生成
% 由于贴装调度优化问题十分复杂，且随着PCB板元器件数量的增加，
% 求解难度逐渐增大，直接使用随机初始解进行启发式优化，需要很
% 长的优化时间，又因为解空间巨大，使得搜索得到的优化结果往往
% 并不理想。针对上述问题，一般采取的方法为设计近似算法来得到
% 问题的一个或多个局部最优解，然后从这些局部最优解出发，搜索
% 得到更优解，这样算法的优化效率将大大提高，优化结果也较为理想。
C = cell(1,self.nC);%创建元件的元胞数组 = python的列表
ce = cell(ceil(length(C)/self.head_num),self.head_num);
temp = 1;
for i = 1:length(C)/self.head_num+1 %循环次数，+1保证循环完之后所有元件被取贴完
    for j = 1:self.head_num%每次循环取贴数量（吸头数量）
        ce{i,j} = temp;%元件循环分组初始化
        temp=temp+1;
    end
end
%kg = ce;%元件循环分组，matlab没深拷贝、浅拷贝，所以直接赋值
kg = zeros(ceil(length(C)/self.head_num),self.head_num);%换成数组，不用cell，方便第147行进行赋值
cli = zeros(1,self.nK);
for i = 1:self.nK
    tf = strcmp(self.type_num(i,1),self.K(:,1));
    index = find(tf == 1); %每个元件类型在所有元件对象self.K中的索引
    self.type_num{i,3} = index;%存储每种元件在self.K中的索引
    jkl(i)= self.type_num{i,2};%jk1存储每种类型的元件数量
end
%% 计算贴头元件类型分配序列kg（先看论文原理）
% 步骤基本和论文差不多，实现的方法有所区别
%% 步骤1：元件升序排列
disp("qk jk 初始值：qk存储从小到大排序好的每种类型的元件数量，jk存储类型索引")
[qk,jk] = sort(jkl)%qk存储从小到大排序好的每种类型的元件数量，jk存储类型索引
kn = self.nK;
r = 0;
kge = zeros(1,self.head_num);
%% 步骤2：判断未分配的元件类型数量是否大于贴头数量
if kn >= self.head_num 
    %将前四种元件分配到第一个循环
    %这里应该没有考虑具体哪个吸头对应哪种元件，反正四种元件肯定能匹配四个吸头
    %（而四个吸头只有两种吸嘴也是有可能的）
%% 步骤3、4，判断为首次分配 (应该可以不要)
%     for rl = 1:qk(1)%为什么是qk(0)?答：论文P25步骤5，基本上qk第一个数都是1，所以不影响
%         kg(rl,:) = kge; %每四个类型索引分配一次循环
%         r=r+qk(1);%统计已分配的循环次数
%     end
%% 步骤5：当元件类型数量大于吸头数
    while kn >= self.head_num
        qkl = qk(1);%其实qkl初始化为任何数都行
        %记录一次分配
        ind_num = 0;
        ind = 0;%必须赋初始值，否则删除qk的元素会出错!!!
        r=r+1;%循环次数+1
        kg(r,:) = jk(1:4);%存储每次分配的元件索引
        for qkl = 1:self.head_num
            qk(qkl)=qk(qkl)-1;%不应该减去1吗？？？***********************
            if qk(qkl)==0 %如果没有0的情况，又没有给ind赋初值，删除qk数字会出错
                ind_num=ind_num+1;
                ind(ind_num)= qkl;%记录已经分配完的元件，对应类型的索引（已排序的索引）
            end     
        end
        jko = jk;
        if ind~=0
            for i=1:ind_num
                %qk(ind(i)) = [];%删除已经分配完的类型(这种方式会出错，例如qk=[1,2,5],原本想要删除第1、2个数，但删除第一个之后，数字5的索引变为2，会将数字5删掉)
                qk(ind(i)) = [0];%后面再删除掉0就行了
                jk(ind(i)) = [0];%也删除该类型的索引（这个索引指未排序时的索引） 
            end
        end
        %% 步骤6：移除jk、qk已经分配的元件类型
        x = find(qk == 0);
        qk(x) = [];
        jk(x) = [];
        qkl = qk(1); %qkl用来做什么？？
        %disp("每次循环后的qk值：");
        qk;
        kn = length(qk);%计算还剩多少类型没有分配完
        if kn < self.head_num
            break %剩下的类型数小于吸头数就退出循环
        end

        %% 后面的步骤不太懂，论文似乎也没有提到
        jkm = [];

    end
    %% 步骤 ７ ：此时元件类型小于吸头数；添加数个０至qk及jk中使得其元素个数等于贴装头总数即补齐贴装头上的空缺位置
    ind_num = 0;%再次初始化0
    ind = 0;
    while length(qk)>1 || sum(qk)>0
            insert0_num = self.head_num-length(qk);
            len = length(qk);
            for j = 1:insert0_num
                qk(len+j) = 0;%后面补零（而论文是前面补零）
                jk(len+j) = 0;
            end
            find(qk == 0);
    %% 步骤 8：分配元件到0位
            if find(qk == 0)%上面的while循环之后，少于吸头数的位置补零，所以一定有0
                k = find(jk==0);
                max_index = find(qk == max(qk));
               %% 存在相同最大值，则选择第一个最大值
                if (length(max_index) >1)
                    max_index = max_index(1);
                end
               %% 元件总数不小于吸头数的情况
                  if sum(qk)>(self.head_num-1)
                    qk(k(1)) = floor(qk(max_index)/2);%将最多元件的一半取整分配到0位
                    jk(k(1)) = jk(max_index);
                    qk(max_index) = qk(max_index)-qk(k(1));%最大元件数也得减去分配的
                    for sub = 1:min(qk)%将最小数量的元件减为0
                        for qkl = 1:self.head_num
                            qk(qkl)=qk(qkl)-1;%不应该减去1吗？？？***********************
                            if qk(qkl)==0 %如果没有0的情况，又没有给ind赋初值，删除qk数字会出错
                                ind_num=ind_num+1;
                                ind(ind_num)= qkl;%记录已经分配完的元件，对应类型的索引（已排序的索引）
                            end     
                        end
                    r=r+1;%循环次数+1
                    kg(r,:) = jk(1:4);%存储每次分配的元件索引
                    end

                    if ind~=0
                        for a=1:ind_num
                            %qk(ind(i)) = [];%删除已经分配完的类型(这种方式会出错，例如qk=[1,2,5],原本想要删除第1、2个数，但删除第一个之后，数字5的索引变为2，会将数字5删掉)
                            qk(ind(a)) = [0];%补零
                            jk(ind(a)) = [0];
                        end
                    end
                    x = find(qk == 0);
                    repair_jk = jk(max(x));
                    qk(x) = [];%删除0
                    jk(x) = [];
                    ind = 0;%!!必须将ind清零，否则上一次设定的ind值会保留，导致删掉非0值，使用断点才调试到这个问题！！
                    %disp("类型数小于吸头数的qk值：")
                    qk;
                  end
               end
               %% 最后一次分配，元件数小于吸头数的情况
               len_jk = 0;
                if (sum(qk)<self.head_num)
                    r=r+1;%循环次数+1
                    kg(r,1:length(jk)) = jk(1:length(jk));%存储每次分配的元件索引
                    len_jk = length(jk);
                    jk = 0;%最后肯定都是0
                    qk = 0;
                    %disp("元件数小于吸头数的qk值：")
                    qk;
                end
               
    end
kg(r,len_jk+1) = repair_jk;%执行上面while的最后一个循环的时候，会将末尾补零，导致上面使用
                                           %find查找0元素并删除的时候，会将jk最后一个元素删掉，因此需要补上
end%元件类型分配完毕
kg_init = kg;
%% 供料器分配：按所需元件数量从小到大排列元件类型到喂料器（喂料器也可以用优化算法进行分配）
% 本方法实现了论文所说的：主要考虑因素为最大化单次吸取元器件的个数，
% 其次考虑供料器对应元器件类型对应元器件数目越多越应该靠近PCB
% 两个优化无法同时达到最优解，原因是最大化单次吸取数量需要喂料器的元件类型排布和kg的分配一致，
% 但是可能吸取循环最多的四个元件类型都靠近PCB中间部分，而这四个元件类型放在喂料器最右边比在中间移动的距离要长

%% 23年11月22日补充：最大化单次吸取元器件的个数可以减少吸取元件的时间，但是会导致吸取元件的总距离变长，
%% 比如每组能同时吸取4个元件，上下轮循环移动的距离可能较长，但是每一组吸取的时间只有一次吸嘴运动时间。
%% 而考虑喂料器元件类型靠近PCB虽然可以减少贴装的距离，但是每一组吸取的四个元件都要分别吸取，总的吸取时间是四个同时吸取的四倍
%% 因此需要均衡考虑二者！
lame = 0;
lam = zeros(1,self.nS);
lame_num = 0;
for i = 1:self.R
    for j = 1:length(kg(i,:))-1
        if ~ismember(kg(i,j),lame)&&~ismember(kg(i,j+1),lame)
            lame_num = lame_num+1;
            lame(lame_num) = kg(i,j);
            lame_num = lame_num+1;
            lame(lame_num) = kg(i,j+1);
        end
        if ismember(kg(i,j),lame)&&~ismember(kg(i,j+1),lame)
            lame_num = lame_num+1;
            lame(lame_num) = kg(i,j+1);
        end
        if ~ismember(kg(i,j),lame)&&ismember(kg(i,j+1),lame)
            lame_num = lame_num+1;
            lame(lame_num) = kg(i,j);
        end
    end
end
%##########################################################################
lame(find(lame == 0)) = [];%删掉0,否则解码喂料器元件分布序列会出错（Count_Fit函数第六行）
lame;
init_pos = floor((self.nS-length(lame))/2);
lam(1,init_pos+1:init_pos+length(lame)) = lame;%将所需元件类型放置到喂料槽中间位置
%% 邻近算法求解初始贴装顺序(结合硕士论文4.3节的流程图更容易理解)
% 参考文献《一种高速贴片机在线贴装优化方法研究_邢星》
pl = 0;
rg_CompIndex = 0;%存储kg索引对应的元件号
lastkg_Index = 0;%最后一个吸头的元件类型索引
fe_pos = 0;
min_dis = 0;
min_ComIndex = 1;%最小距离元件索引
com_pos = 0;%元件横轴坐标
last_pl = 0;%暂存上一步分配的元件索引
temp_self = self;%拷贝一份，避免对原始对象进行处理
%循环结束之后temp_self.type_num第三列应该是空的，所有元件都被分配完
for r = 1:length(kg)
    for g = 1:length(kg(r,:))
        %最后一个循环含有0值，只取非0值（早知道用链表存数据了，数组真的麻烦...）
        if kg(r,g)==0
            break %是0就退出，否则代码temp_self.type_num(kg(r,g),3)中的kg(r,g)为0，无法索引
        end
        if g == 1
            rg_CompIndex = cell2mat(temp_self.type_num(kg(r,g),3));%第r轮第g个贴头对应元件类型所包含的元件的索引
            lastkg_Index = kg(r,length(kg(r,:)));%存储该轮循环最后一个吸头元件类型的索引
            fe_pos = temp_self.fe_pos(find(lam == lastkg_Index));%找到最后一个元件类型在喂料槽的索引，并获取该喂料槽的坐标（只有横向坐标）
            %计算离最后一个元件类型对应喂料器最近的元件索引
            min_dis = abs(temp_self.pos(rg_CompIndex(1))-fe_pos);
            min_ComIndex = rg_CompIndex(1);%加上该代码，避免出现第一个元件索引就是最小距离，导致没有进入条件语句内为min_ComIndex赋值！！！
            for comp_num = 1:length(rg_CompIndex)
                if abs(temp_self.pos(rg_CompIndex(comp_num))-fe_pos) < min_dis
                    min_dis =  abs(temp_self.pos(rg_CompIndex(comp_num))-fe_pos);
                    min_ComIndex = rg_CompIndex(comp_num);
                end
            end
            pl(r,g) = min_ComIndex;%存储元件索引
            last_pl = pl(r,g);%暂存“上一个分配的元件索引”
            del_index = find(cell2mat(temp_self.type_num(kg(r,g),3)) == min_ComIndex);
            temp_self.type_num{kg(r,g),3}(del_index)=[];%删掉已经分配的元件
        end
        if g~=1
            rg_CompIndex = cell2mat(temp_self.type_num(kg(r,g),3));%第r轮第g个贴头对应元件类型所包含的元件的索引
            if length(rg_CompIndex) >0 
                com_pos = temp_self.pos(last_pl);%上一个pl元件的横坐标
                min_dis = abs(temp_self.pos(rg_CompIndex(1))-com_pos);
                min_ComIndex = rg_CompIndex(1);
                for comp_num = 1:length(rg_CompIndex)
                    if abs(temp_self.pos(rg_CompIndex(comp_num))-com_pos) < min_dis
                        min_dis =  abs(temp_self.pos(rg_CompIndex(comp_num))-com_pos);
                        min_ComIndex = rg_CompIndex(comp_num);
                    end
                end
                pl(r,g) = min_ComIndex;%存储元件索引
                last_pl = pl(r,g);%暂存“上一个分配的元件索引”
                del_index = find(cell2mat(temp_self.type_num(kg(r,g),3)) == min_ComIndex);
                temp_self.type_num{kg(r,g),3}(del_index)=[];%删掉已经分配的元件
            end
        end
    end
end
%% 初始解生成结束，获取的数据包括初始贴头元件类型分配序列kg、喂料器分布lam、初始元件贴装序列pl

%% 解码贴放序列alpha（通过ce和pc解码）、拾取序列beta（ce、kc）、贴装头元器件的分配zeta（ce、gc）、供料槽元器件类型分配lamb
%% 论文原始代码解码的lamb、alpha及zeta和论文所说的编解码名称搞乱了。。。这里使用论文对应的名称
% 上面的步骤已经获取了元件类型分配序列kg以及元件贴放序列pl，染色体编码的是元件顺序，假设pl第一个循环序列是[1,2,14,11]
% 里面的数字表示元件序号，但是放置这些元件的顺序是由染色体编码决定，例如放置顺序（染色体编码为）为[4,1,3,2],则pl放置
% 元件的解码贴放顺序为[2,11,14,1]
% 论文中的kc指元器件拾取顺序染色体编码、gc指贴头的元件分配编码、pc指贴放顺序编码、fc指供料槽元件类型分配编码

% 需要解码的原因：
% 由于同一取贴循环中贴放、拾取以及贴装头所分配的元器件相同
% 假设第一组循环贴放的元件序列alpha为[2,1,23,14],而吸头从左到右元件序列zeta为[23,2,14,1],二者各自有其组内编码染色体pc、gc
% 而组间编码则是直接使用原本的元件分组序列ce(pl)，所以两条ce染色体只能进行组间交叉，而pc、gc等只能进行组内交叉

% 假设吸头元件序列已经确定，但是拾取元件的顺序也是不定的，比如可以第一次吸取2号元件也可以吸取14号元件，因此也需要一条染色体来编码
% 综上：ce其实指的元件序列分组，每次循环无论拾取、贴放、吸头元件分配都是一样的四个元件，但是拾取、贴放及吸头分配的元件顺序却不一样
% 因此，组间序列染色体ce和组内顺序染色体（pc、gc、kc）一起解码就能获取到真正的拾取、贴放和吸头分配的元件序列！！！

% 每一次的交叉、变异、局部搜索都对kc、gc、pc的染色体编码（z、w、y）进行改变,
% 后面再与ce（元件序号本身作为染色体而不是像kc、gc一样以元件顺序作为编码，上面生成的pl作为初始染色体）解码就可以获取到pc和gc
% 令人疑惑的一点在于ce指分组编码染色体，pc指贴放编码染色体，二者均进行了交叉、变异操作
% 为何不只以ce（pl）作为贴放染色体进行遗传操作？
% 答：看上面的分析
%% 吸嘴匹配元件类型的问题
%通过对多篇论文的装贴模型分析，原始论文代码没有考虑吸嘴匹配元件类型的约束问题
%该问题确实比较麻烦，考虑该约束会限制遗传操作，每次都要判断吸嘴是否匹配元件
%所以在上面初始解生成的kg序列，也没有考虑吸嘴是否匹配元件类型，默认每个吸嘴能吸取所有类型的元件
%如果论文只是对比各类算法的优势，那其实模型确实就应该这样简化
%% 编写距离计算函数Dis_Sum
% 将贴装距离分成几段组成：PCB上前后贴放的元件i到元件j的距离和Dpp、前后拾取元件i供料槽到元件j供料槽距离和Dss、
% 每一轮循环动臂由供料槽移动到PCB第一个贴放位置的距离和Dsp、每一轮循环PCB移动到供料槽的距离和Dps
% 再加上动臂由最后一个贴放位置返回原点的距离De、动臂由原点移动到供料槽拾取第一个元器件的距离D0（模型需要，但是代码其实可以省去）
% 模型参考论文《An MILP model and a hybrid evolutionary algorithm for integrated operation》和《最小准则遗传算法求解贴片机贴装调度问题》

%% 加载上面初始解的结果，加快运行速度
% clear all;
% % 清除窗口输出
% clc;
% load('GA_self_11680.mat')
%% 遗传算法
% 初始化贴放染色体,其实应该也可以初始化为一维数组[1,2,3,4,5,6,...,self.nC],遗传操作会有所区别，后面可以改来试试！！！！
for i = 1:length(pl(:,1))
    for j = 1:length(pl(1,:))
    pc(i,j) = j; 
    end
end
gc = pc; % 贴头元件分布染色体（由于计算距离时，按数组从左到右顺序计算，因此认为等价于拾取染色体）

%% 什么初始解都不考虑，随机初始序列
c = 1:self.R*self.head_num;
c(1:self.nC) = randperm(self.nC,self.nC);
c(self.nC+1:end) = 0;
c = reshape(c,[self.R,self.head_num]);
%% 考虑喂料器中心排列方法的初始解：喂料器元件类型分布染色体初始化，与lame解码生成实际的喂料器分布，再将其放在整排喂料槽的中间，分布如[0,1,3,2,0]
%% 不考虑论文元件分配初始解，元件按序排列，hdmi的初始长度约为1.68*10^4
%% 
c = 1:self.R*self.head_num;
c(self.nC+1:end) = 0;
c = reshape(c,[self.R,self.head_num]);
%% 考虑论文的元件分配初始解
c = pl; %考虑论文的初始解
%% 考虑论文喂料器的初始解 
fc = 1:self.nK;
fe = fc;%考虑喂料器的初始解 
%% 遗传算法的参数
cross_rate = 0.9;%交叉概率
p_n = 0.05;%扰动概率
p_m = 0.1;%变异概率
self.n = 1;%初始化种群代数
self.eit = 0.7;%初始化准校准测系数

%% 初始解：初始化gc、pc、fc序列
life = Life(fc,fe,c,pc,gc,feeder_num);%life初始化必须pc=gc，保证每一组内元件和贴放的元件一样！！！
self.life = life;
self.best_life = life;
pop_size = 300;
% 种群初始化
for i=1:pop_size 
    lives(i) = life;
end
%% 载入不同距离的元件序列：测试用
% self.life = GA_self.best_life;
% self.best_life = GA_self.best_life;
% 种群初始化
% for i=1:pop_size 
%     lives(i) = GA_self.best_life;
% end
%% 随机初始解
% for j= 1:pop_size
%     for i = 1:36
%         lives(j).pc(i,:) = randperm(4,4);
%         lives(j).gc = lives(j).pc;
%         lives(j).fc = randperm(self.nK,self.nK);
%     end
% end
% self.best_life = lives(1);
%% 显示当前距离
[self.best_fit,self.best_dis] = Count_Fit(self,self.best_life);%设定目前最好的适应度和距离为初始解的适应度、距离
disp("初始解的计算距离：")
self.best_dis
disp("初始解扩大一万倍的适应度：")
self.best_fit
%% 狮群算法直接对元件序列进行操作，因此需要解码
% life.alpha = decode(self.best_life.ce,self.best_life.pc); %解码贴放序列alpha（通过ce和pc解码）
% life.zeta = decode(self.best_life.ce,self.best_life.gc); %贴头元器件的分配zeta（ce、gc）
% lame = decode(self.best_life.fe,self.best_life.fc);%喂料器元件分布序列
% life.lamb = Feeder_Code(lame,self.best_life.nS);%供料槽元器件类型分配lamb
% life.lso_mnsc_sequen = randperm(self.R,self.R);
% self.life = life;
% 
% 
%  [life,dis] = SMT_LSO_Run(self,20,500,0.4,0.4);
%% 载入对比算法的对比图
% f = open('SDR测试图/20代300个体论文初始解log交叉函数对比固定6交叉单图.fig');
% h_line=get(gca,'Children');%get linehandles
% xdata=get(h_line,'Xdata');
% ydata=get(h_line,'Ydata');
% set(f,'Name','figure1');
% close(f)
% figure
% plot(ydata,'color','g')
% hold on; box on
%% 不同PCB的迭代次数及固定交叉个数设定
InterCrossNum = 1;%组内元件交叉数量
GA_lives = lives;
temp_lives = lives;
temp_self = self;
GA_self = self;
tic
start_time=cputime;
FeCrossNum = 4;%喂料器交叉的元件数量
if strcmp(PCB_File, 'humi_temp.csv')
    gen_size = 20;%设定不同规模PCB的迭代次数
    FeCrossNum = 4;% 修改喂料器交叉的元件数量
    PCB_File = 'humi_temp';
end
if strcmp(PCB_File,'hdmi.xlsx')
    gen_size = 60;%设定不同规模PCB的迭代次数
    FeCrossNum = 6;
    PCB_File = 'hdmi';
end
if strcmp(PCB_File,'lai_luo.csv')
    gen_size = 40;%设定不同规模PCB的迭代次数
    FeCrossNum = 4;
    PCB_File = 'lai_luo';
end
if strcmp(PCB_File,'M01.csv')
    gen_size = 50;%设定不同规模PCB的迭代次数
    FeCrossNum = 4;
    PCB_File = 'M01';
end
if strcmp(PCB_File,'RTC.xlsx')
    gen_size = 50;%设定不同规模PCB的迭代次数
    FeCrossNum = 4;
    PCB_File = 'RTC';
end
if strcmp(PCB_File,'SDR.xlsx')
    gen_size = 20;%设定不同规模PCB的迭代次数
    FeCrossNum = 4;
    PCB_File = 'SDR';
end
pop_size = 300;% 种群个体数量
%% GA
for t=1:3 %取三张图
    numm = 1;%记录点数
    dis_ = 0;
    GA_lives = temp_lives;
    GA_self = temp_self;
    start_time=cputime;
     for i = 1:gen_size
        [GA_self,GA_lives,dis_best,numm,dis_] = Make_News(GA_self,GA_lives,cross_rate,FeCrossNum,InterCrossNum,p_n,p_m,i,gen_size,pop_size,numm,dis_);
        lame = decode(GA_self.best_life.fe,GA_self.best_life.fc);%喂料器元件分布序列
        disp(['第',num2str(i),'代最高适应度为:',num2str(GA_self.best_fit)])
        disp(['第',num2str(i),'代最短距离为:',num2str(GA_self.best_dis)])
        disp(['第',num2str(i),'代喂料器分布为:'])
     end
    total_time=cputime-start_time  %这里输出CPU用时
    toc
    figure
    plot(dis_)
    title(['MCGA_M01第',num2str(t),'次',num2str(gen_size),'代',num2str(pop_size),'个体'])
    xlabel('迭代次数')
    ylabel('距离(mm)')
    name = strcat('MCGA_M01第',num2str(t),'次');
    saveas(gcf, name, 'fig');
end
%% MDFA
%% 考虑pc、gc、fc同时操作
% for t = 1:3
%     numm = 1;%记录点数
%     dis = 0;
%     self = temp_self;
%     lives = temp_lives;
%     tic
%     start_time=cputime;
%      for i = 1:gen_size
%         [self,lives,dis_best,numm,dis] = MDFA_News(self,lives,i,gen_size,numm,dis);   
%         disp(['第',num2str(i),'代最高适应度为:',num2str(self.best_fit)])
%         disp(['第',num2str(i),'代最短距离为:',num2str(self.best_dis)])
%      end
%     total_time=cputime-start_time  %这里输出CPU用时
%     toc
%     time = toc
%     % legend('LOG\_GA','MDFA')
%     % legend('LOG\_GA','MDFA')
%     figure
%     plot(dis)
%     title(['MDFA_M01第',num2str(t),'次',num2str(gen_size),'代',num2str(pop_size),'个体'])
%     xlabel('迭代次数')
%     ylabel('距离(mm)')
%     name = strcat('MDFA_M01第',num2str(t),'次');
%     saveas(gcf, name, 'fig');
% end
%% 

alpha = decode(self.best_life.ce,self.best_life.pc); %解码贴放序列alpha（通过ce和pc解码）
zeta = decode(self.best_life.ce,self.best_life.gc); %贴头元器件的分配zeta（ce、gc）
lame = decode(self.best_life.fe,self.best_life.fc);%喂料器元件分布序列
lamb = Feeder_Code(lame,self.best_life.nS);%供料槽元器件类型分配lamb
%% alpha、zeta解码成元件类型序列（可以对比不同距离下，元件类型分布的特点）
alpha_type = decode_compo_to_type(self,life.pc);
zeta_type = decode_compo_to_type(self,life.gc);
for i = 1:length(zeta(:,1))
    for j = 1:length(zeta(i,:))
        match_type = find(cellfun(@(x) ismember(zeta(i,j),x),self.type_num(:,3))); %元件对应的元件类型
        if length(match_type) == 0
            zeta_type(i,j) = 0;
        else
            zeta_type(i,j)  = match_type;
        end
    end
end
%  alpha_type
%  zeta_type