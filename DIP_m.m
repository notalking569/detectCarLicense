classdef DIP_m < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        GridLayout        matlab.ui.container.GridLayout
        Panel_5           matlab.ui.container.Panel
        GridLayout6       matlab.ui.container.GridLayout
        Button26          matlab.ui.control.Button
        Button25          matlab.ui.control.Button
        Button24          matlab.ui.control.Button
        Button23          matlab.ui.control.Button
        Button22          matlab.ui.control.Button
        Button21          matlab.ui.control.Button
        Panel_4           matlab.ui.container.Panel
        GridLayout5       matlab.ui.container.GridLayout
        detectPasteBtn    matlab.ui.control.Button
        deleteObjBtn      matlab.ui.control.Button
        smoothBtn         matlab.ui.control.Button
        imeroadBtn        matlab.ui.control.Button
        Panel_3           matlab.ui.container.Panel
        GridLayout4       matlab.ui.container.GridLayout
        edgeDetectionBtn  matlab.ui.control.Button
        grayScaleBtn      matlab.ui.control.Button
        Panel_2           matlab.ui.container.Panel
        GridLayout3       matlab.ui.container.GridLayout
        selectImgBtn      matlab.ui.control.Button
        axImg             matlab.ui.control.UIAxes
        Panel             matlab.ui.container.Panel
        GridLayout2       matlab.ui.container.GridLayout
        ax25              matlab.ui.control.UIAxes
        ax24              matlab.ui.control.UIAxes
        ax23              matlab.ui.control.UIAxes
        ax22              matlab.ui.control.UIAxes
        ax21              matlab.ui.control.UIAxes
        ax16              matlab.ui.control.UIAxes
        ax15              matlab.ui.control.UIAxes
        ax14              matlab.ui.control.UIAxes
        ax13              matlab.ui.control.UIAxes
        ax12              matlab.ui.control.UIAxes
        ax11              matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        %% 全局属性
        imagePath           % 图片地址 
        imageData           % 图片数据  
        imageGray           % 图片灰度化处理 
        imageEdge           % 图片边缘检测
        imageErode          % 图片腐蚀
        imageSmooth         % 平滑处理
        imageDeleteObj      % 对象移除
        imageDetect         % 定位

        licenseGray         % 灰度
        licenseHist         % 均衡
        licenseBin          % 二值
        licenseDelete       % 移除
        licenseMid          % 滤波
        license             % 车牌        

        step = 1            % 程序步骤
    end
    
    methods (Access = private)
        
        function res = my_split(app)
            tmp = app.licenseMid;
            [m, n] = size(tmp);


            top = 1; bottom = m; left = 1; right = n;
            for i = 1:m
                RS(i) = sum(tmp(i, :));
            end
            for i = 1:n
                CS(i) = sum(tmp(:, i));
            end


            while(RS(top) == 0 && top <= m)
                top = top + 1;
            end
            if top - 10 > 1
                top = top - 10;
            else 
                top = 1;
            end

            while(RS(bottom) == 0 && bottom >= 1)
                bottom = bottom - 1;
            end
            if bottom + 10 < m
                bottom = bottom + 10;
            else 
                bottom = m;
            end

            while(CS(left) == 0 && left <= n)
                left = left + 1;
            end
            if left - 10 >= 1
                left = left - 10;
            else 
                left = 1;
            end

            while(CS(right) == 0 && right >= 1)
                right = right - 1;
            end
            if right + 10 <= n
                right = right + 10;
            else 
                right = n;
            end

            w = right - left;
            h = bottom - top;
            res = imcrop(tmp, [left top w h]);
        end
        
        function res = get_word(app)
            tmp = app.license;
            [~, n] = size(tmp);
            left = 1; width = 1;
            for i = 1:n
                CS(i) = sum(tmp(:, i));
            end
            assignin("base", "CS", CS);

            while(CS(left) == 0 && left < n)
                left = left + 1;
            end

            if left == n
                res = [];
                return
            end

            while(CS(left+width) ~= 0 && left+width < n)
                width = width + 1;
            end
            
            res = tmp(:, left:left+width-1);
            tmp(:, left:left+width-1) = 0;

            app.license = tmp;
            % figure;
            % subplot(121); imshow(res);
            % subplot(122); imshow(app.license);
        end
        
        function res = delete_obj(~, input, thresholdSize)
            if ~islogical(input)
                input = input ~= 0;
            end

            [labelInput, num] = bwlabel(input);
            regionSS = regionprops(labelInput, 'Area', 'PixelIdxList');
            assignin('base', "regionSS", regionSS);
            res = false(size(input));

            for i = 1:num
                if regionSS(i).Area >= thresholdSize
                    res(regionSS(i).PixelIdxList) = true;
                end
            end

            
        end
        
        function alertInfo(app)
            info = ["上传图片", "灰度处理", "边缘检测", "图像腐蚀", "平滑处理", "移除对象", "定位剪贴", "灰度处理", "直方图均衡化", "二值化", "移除对象(车牌识别)", "中值滤波"];
            output = strcat("请先进行", info(app.step), '');
            uialert(app.UIFigure, output, '警告', 'Icon', 'warning');
            return;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: selectImgBtn
        function uploadImg(app, event)
            %% 图片选择
            axis(app.axImg,'off');             %隐藏坐标轴
            % 当前目录下打开文件管理器
            [fileName, pathName] = uigetfile({'*.jpg;*.png;*.bmp;*.tif'}, '请选择图片路径', fileparts(mfilename('fullpath')));
            if pathName == 0
                return;
            end

            app.imagePath = [pathName fileName];
            app.imageData = imread(app.imagePath);

            assignin('base', "imagePath", app.imagePath);
            assignin('base', 'imageData', app.imageData); 
           
            if app.step > 4
                app.imageGray = [];
                app.imageEdge = [];
                app.imageErode = [];
                app.imageSmooth = [];
                app.imageDeleteObj = [];
                app.imageDetect = [];
                app.licenseBin = [];
                app.licenseHist = [];
                app.licenseDelete = [];
                app.licenseMid = [];
                app.license = [];
            end
            app.step = 2;
            imshow(app.imageData, 'Parent', app.axImg);
        end

        % Button pushed function: grayScaleBtn
        function grayScale(app, event)
            %% 灰度处理
            if isempty(app.imageData)
                app.alertInfo();
                return
            end
            axis(app.ax11,'off');             %隐藏坐标轴

            imgR = app.imageData(:, :, 1);
            imgG = app.imageData(:, :, 2);
            imgB = app.imageData(:, :, 3);

            wr = 0.30; wg = 0.59; wb = 0.11;
            g = (wr * imgR + wg * imgG + wb * imgB);

            app.imageGray = medfilt2(g);
            app.step = app.step + 1;
            assignin('base', 'imageGray', app.imageGray);  
            imshow(app.imageGray, "Parent", app.ax11);

        end

        % Button pushed function: edgeDetectionBtn
        function edgeDetection(app, event)
            %% 边缘检测
            if isempty(app.imageGray)
                app.alertInfo();
                return;
            end
            axis(app.ax12,'off');             %隐藏坐标轴

            app.imageEdge = edge(app.imageGray, 'roberts', 0.07);
            app.step = app.step + 1;
            assignin('base', 'imageEdge', app.imageEdge);  
            imshow(app.imageEdge, "Parent", app.ax12);
            
        end

        % Button pushed function: imeroadBtn
        function imeroadBtnButtonPushed(app, event)
            %% 腐蚀
            if isempty(app.imageEdge)
                app.alertInfo();
                return;
            end
            axis(app.ax13,'off');             %隐藏坐标轴

            se = strel('rectangle', [16, 1]);
            app.step = app.step + 1;
            app.imageErode = imerode(app.imageEdge, se);
            assignin('base', 'imageErode', app.imageErode);  
            imshow(app.imageErode, 'Parent', app.ax13);
        end

        % Button pushed function: smoothBtn
        function smoothBtnButtonPushed(app, event)
            %% 平滑处理
            if isempty(app.imageEdge)
                app.alertInfo();
                return;
            end
            axis(app.ax14,'off');             %隐藏坐标轴

            se = strel('rectangle', [300, 300]);
            app.imageSmooth = imclose(app.imageErode, se);
            assignin('base', 'imageSmooth', app.imageSmooth);
            app.step = app.step + 1;
            imshow(app.imageSmooth, 'Parent', app.ax14);
        end

        % Button pushed function: deleteObjBtn
        function deleteObjBtnButtonPushed(app, event)
            %% 移除对象
            
            if isempty(app.imageSmooth)
                app.alertInfo();
                return;
            end
            axis(app.ax15, 'off');
            
            cc = bwconncomp(app.imageSmooth);
            stats = regionprops(cc, 'Area');
            areas = [stats.Area];

            if isempty(areas)
                uialert(app.UIFigure, '没有检测到联通区域！', '警告', 'Icon','warning');
                return;
            end

            sortedAreas = sort(areas, 'descend');
            tar = sortedAreas(1);

            app.imageDeleteObj = bwareaopen(app.imageSmooth, tar);
            [m, n] = size(app.imageDeleteObj);
            for i = 1:n
                CC(i) = sum(app.imageDeleteObj(:, i));
            end
            cc_mean = mean(CC(:));

            for i=1:n
                if CC(i) ~= 0 && CC(i) < cc_mean / 5
                    app.imageDeleteObj(:, i) = 0;
                end
            end

            for i = 1:m
                RR(i) = sum(app.imageDeleteObj(i, :));
            end
            rr_mean = mean(RR(:));

            for i =  1:m
                if RR(i) ~= 0 && RR(i) < rr_mean / 5
                    app.imageDeleteObj(i, :) = 0;
                end
            end

            app.step = app.step + 1;
            assignin('base', 'imageDeleteObj', app.imageDeleteObj);
            imshow(app.imageDeleteObj, 'Parent', app.ax15);

            
        end

        % Button pushed function: detectPasteBtn
        function detectPasteBtnButtonPushed(app, event)
            %% 定位剪贴
            if isempty(app.imageDeleteObj)
                app.alertInfo();
                return;
            end

            pic = app.imageDeleteObj;
            [r, c] = size(pic);
            pr1 = 0;
            pr2 = 0;
            for i = 1 : r
                RR(i) = sum(pic(i, :));
            end
            judgeR = 30;
            k = 0;
            for i = 1 : r
                if (pr1 == 0 && RR(i) ~= 0)
                    pr1 = i;
                end
                if (pr1 ~= 0 && pr2 == 0 && RR(i) == 0)
                    pr2 = i;
                    k = pr2 - pr1;
                end
                if (k ~= 0 && k < judgeR)
                    pr1 = 0;
                    pr2 = 0;
                    k = 0;
                end
                if (k > judgeR)
                    break
                end
            end

            pc1 = 0;
            pc2 = 0;
            for i = 1 : c
                CC(i) = sum(pic(:, i));
            end
            judgeC = 120;
            k = 0;
            for i = 1 : c
                if (pc1 == 0 && CC(i) ~= 0)
                    pc1 = i;
                end
                if (pc1 ~= 0 && pc2 == 0 && CC(i) == 0)
                    pc2 = i;
                    k = pc2 - pc1;
                end
                if (k ~= 0 && k < judgeC)
                    pc1 = 0;
                    pc2 = 0;
                    k = 0;
                end
                if (k > judgeC)
                    break
                end
            end

            I = imread(app.imagePath);
            if (pr1 == 0 && pr2 ==0) || (pc1 == 0 && pc2 == 0)
                uialert(app.UIFigure, "车牌定位失败", '错误', 'Icon', 'error');
                return;
            end

            tar = zeros([pr2 - pr1, pc2 - pc1, 3], 'uint8');
            assignin("base", "pr", [pr1 pr2]);
            assignin("base", "pc", [pc1 pc2]);
            for i = pr1 : pr2
                for j = pc1 : pc2
                    tar(i-pr1+1, j-pc1+1, 1) = I(i, j, 1);
                    tar(i-pr1+1, j-pc1+1, 2) = I(i, j, 2);
                    tar(i-pr1+1, j-pc1+1, 3) = I(i, j, 3);
                end
            end
            app.step = app.step + 1;
            app.imageDetect = tar;
            axis(app.ax16, 'off');
            imshow(app.imageDetect, 'Parent', app.ax16);
        end

        % Button pushed function: Button21
        function Button21Pushed(app, event)
            %% 车牌识别 灰度处理
            if isempty(app.imageDetect)
                app.alertInfo();
                return 
            end
            app.licenseGray = rgb2gray(app.imageDetect);
            app.step = app.step + 1;
            axis(app.ax21, 'off');
            imshow(app.licenseGray, 'Parent', app.ax21);
        end

        % Button pushed function: Button22
        function Button22Pushed(app, event)
            %% 直方图均衡化
            % figure;
            % imhist(app.licenseGray); title("均衡前");
            if isempty(app.licenseGray)
                app.alertInfo();
                return;
            end
            app.licenseHist = histeq(app.licenseGray, 64);
            % figure;
            % imhist(app.licenseHist); title("均衡后");
            axis(app.ax22, 'off');
            app.step = app.step + 1;            
            imshow(app.licenseHist, 'Parent', app.ax22);
        end

        % Callback function: Button23, ax23
        function ax23ButtonDown(app, event)
            %% 二值化
            if isempty(app.licenseHist)
                app.alertInfo();
                return;
            end
            % 这里二值化均衡之后的图不如直接使用灰度图
            app.licenseBin = imbinarize(app.licenseGray);
            if mean(app.licenseBin(:)) > 0.5
                % 如果原始车牌字符为黑色 那么二值化之后背景为白色 不利于切割 将其反转
                app.licenseBin = ~app.licenseBin;
            end
            assignin("base", "licenseBin", app.licenseBin);
            axis(app.ax23, 'off');
            app.step = app.step + 1;            
            imshow(app.licenseBin, 'Parent', app.ax23);
        end

        % Button pushed function: Button24
        function Button24Pushed(app, event)
            %% 移除对象
            if isempty(app.licenseBin)
                app.alertInfo();
                return;
            end

            app.licenseDelete = app.delete_obj(app.licenseBin, 200);
            axis(app.ax24, 'off');
            app.step = app.step + 1;            
            imshow(app.licenseDelete, 'Parent', app.ax24);
        end

        % Button pushed function: Button25
        function Button25Pushed(app, event)
            %% 中值滤波
            if isempty(app.licenseDelete)
                app.alertInfo();
                return
            end

            app.licenseMid = medfilt2(app.licenseDelete, [3 3]);
            axis(app.ax25, 'off');
            app.step = app.step + 1;            
            imshow(app.licenseMid, 'Parent', app.ax25);

        end

        % Button pushed function: Button26
        function Button26Pushed(app, event)
            %% 字符切割 & 模板匹配
            if isempty(app.licenseMid)
                app.alertInfo();
                return;
            end
            app.license = app.my_split();
            assignin('base', "license", app.license);

            words = {};
            others = {};
            idx = 0;
            while true
                idx = idx + 1;
                word = app.get_word();
                if isempty(word)
                    break;
                end
                [m, n] = size(word);

                if m / n > 5 && ~(idx > 3 && idx < 7)
                    % 对于宽高比不对的图片舍弃
                    continue
                end
                words{end+1} = word;
                others{end+1} = app.license;
            end
            assignin('base', 'idx', idx);

            lth = length(words);
            figure();
            for i = 1:lth
                subplot(2, lth, i);
                imshow(words{i});
                title("切割字符");
                subplot(2, lth, i+lth);
                imshow(others{i});
                title("剩余字符");
            end
            
            file_name = char(['0':'9' 'A':'Z' '川赣贵黑吉冀津晋京警辽鲁蒙闽宁陕苏皖湘豫粤浙']);
            tmp = strcat('.\patterns\', file_name(1), '.jpg');
            I = imread(tmp);
            [em, en] = size(I);
            assignin('base', "resize", [em, en]);

            ans_cell = {};
            for i = 1:lth
                word = words{i};
                e_word = imresize(word, [em, en], "nearest");

                if i == 1
                    mmin = 37; mmax = 58;
                elseif i == 2
                    mmin = 11; mmax = 36;
                elseif i >= 3
                    mmin = 1; mmax = 36;
                end

                cnt = [];
                for idx = mmin:mmax
                    f_name = strcat('.\patterns\', file_name(idx), '.jpg');
                    pattern = imread(f_name);
                    pattern = imbinarize(pattern, 0.5);

                    diff = 0;
                    for j=1:em
                        for k=1:en
                            if e_word(j, k) ~= pattern(j, k)
                                diff = diff + 1;
                            end
                        end
                    end
                    cnt(end+1) = diff;
                end

                diff_min = min(cnt);
                idx = find(cnt == diff_min);

                ans_cell{end+1} = file_name(idx + mmin - 1);
            end
            assignin("base", "ans_cell", ans_cell);


            I = app.imageDetect;
            R = I(:, :, 1);
            G = I(:, :, 2);
            B = I(:, :, 3);

            r_mean = mean(R(:));
            g_mean = mean(G(:));
            b_mean = mean(B(:));

            if b_mean > g_mean && b_mean > r_mean
                color = '蓝色';
            elseif g_mean > b_mean && g_mean > r_mean
                color = '绿色';
            elseif r_mean > 150 && g_mean > 150 && b_mean > 150
                color = '白色';
            else
                color = '黄色';
            end
             
            output = sprintf('这是一张 %s 车牌，车牌号是 %s', color, strjoin(string(ans_cell), ''));
            msgbox(output, '检测结果', 'help');

            NET.addAssembly('System.Speech');
            synth = System.Speech.Synthesis.SpeechSynthesizer;
            
            synth.Volume = 100; 
            synth.Rate = 5;   
            
            synth.Speak(output);          
            synth.Dispose();
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100.2 100.2 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.Title = '结果';
            app.Panel.Layout.Row = [5 8];
            app.Panel.Layout.Column = [1 5];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.Panel);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};

            % Create ax11
            app.ax11 = uiaxes(app.GridLayout2);
            title(app.ax11, '灰度处理')
            zlabel(app.ax11, ' ')
            app.ax11.Layout.Row = 1;
            app.ax11.Layout.Column = 1;
            app.ax11.Visible = 'off';

            % Create ax12
            app.ax12 = uiaxes(app.GridLayout2);
            title(app.ax12, '边缘检测')
            xlabel(app.ax12, ' ')
            ylabel(app.ax12, ' ')
            zlabel(app.ax12, ' ')
            app.ax12.Layout.Row = 1;
            app.ax12.Layout.Column = 2;
            app.ax12.Visible = 'off';

            % Create ax13
            app.ax13 = uiaxes(app.GridLayout2);
            title(app.ax13, '图像腐蚀')
            xlabel(app.ax13, ' ')
            ylabel(app.ax13, ' ')
            zlabel(app.ax13, ' ')
            app.ax13.Layout.Row = 1;
            app.ax13.Layout.Column = 3;
            app.ax13.Visible = 'off';

            % Create ax14
            app.ax14 = uiaxes(app.GridLayout2);
            title(app.ax14, '平滑处理')
            xlabel(app.ax14, ' ')
            ylabel(app.ax14, ' ')
            zlabel(app.ax14, ' ')
            app.ax14.Layout.Row = 1;
            app.ax14.Layout.Column = 4;
            app.ax14.Visible = 'off';

            % Create ax15
            app.ax15 = uiaxes(app.GridLayout2);
            title(app.ax15, '移除对象')
            xlabel(app.ax15, ' ')
            ylabel(app.ax15, ' ')
            zlabel(app.ax15, ' ')
            app.ax15.Layout.Row = 1;
            app.ax15.Layout.Column = 5;
            app.ax15.Visible = 'off';

            % Create ax16
            app.ax16 = uiaxes(app.GridLayout2);
            title(app.ax16, '定位剪贴')
            xlabel(app.ax16, ' ')
            ylabel(app.ax16, ' ')
            zlabel(app.ax16, ' ')
            app.ax16.Layout.Row = 1;
            app.ax16.Layout.Column = 6;
            app.ax16.Visible = 'off';

            % Create ax21
            app.ax21 = uiaxes(app.GridLayout2);
            title(app.ax21, '灰度处理')
            xlabel(app.ax21, ' ')
            ylabel(app.ax21, ' ')
            zlabel(app.ax21, ' ')
            app.ax21.Layout.Row = 2;
            app.ax21.Layout.Column = 1;
            app.ax21.Visible = 'off';

            % Create ax22
            app.ax22 = uiaxes(app.GridLayout2);
            title(app.ax22, '直方图均衡化')
            xlabel(app.ax22, ' ')
            ylabel(app.ax22, ' ')
            zlabel(app.ax22, ' ')
            app.ax22.Layout.Row = 2;
            app.ax22.Layout.Column = 2;
            app.ax22.Visible = 'off';

            % Create ax23
            app.ax23 = uiaxes(app.GridLayout2);
            title(app.ax23, '二值化')
            xlabel(app.ax23, ' ')
            ylabel(app.ax23, ' ')
            zlabel(app.ax23, ' ')
            app.ax23.Layout.Row = 2;
            app.ax23.Layout.Column = 3;
            app.ax23.ButtonDownFcn = createCallbackFcn(app, @ax23ButtonDown, true);
            app.ax23.Visible = 'off';

            % Create ax24
            app.ax24 = uiaxes(app.GridLayout2);
            title(app.ax24, '移除对象')
            xlabel(app.ax24, ' ')
            ylabel(app.ax24, ' ')
            zlabel(app.ax24, ' ')
            app.ax24.Layout.Row = 2;
            app.ax24.Layout.Column = 4;
            app.ax24.Visible = 'off';

            % Create ax25
            app.ax25 = uiaxes(app.GridLayout2);
            title(app.ax25, '中值滤波')
            xlabel(app.ax25, ' ')
            ylabel(app.ax25, ' ')
            zlabel(app.ax25, ' ')
            app.ax25.Layout.Row = 2;
            app.ax25.Layout.Column = 5;
            app.ax25.Visible = 'off';

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout);
            app.Panel_2.Title = '选择图片';
            app.Panel_2.Layout.Row = [1 4];
            app.Panel_2.Layout.Column = [1 2];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.Panel_2);
            app.GridLayout3.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout3.RowHeight = {'1x', '9x'};

            % Create axImg
            app.axImg = uiaxes(app.GridLayout3);
            title(app.axImg, '原始图片')
            xlabel(app.axImg, ' ')
            ylabel(app.axImg, ' ')
            zlabel(app.axImg, ' ')
            app.axImg.Layout.Row = 2;
            app.axImg.Layout.Column = [1 3];
            app.axImg.Visible = 'off';

            % Create selectImgBtn
            app.selectImgBtn = uibutton(app.GridLayout3, 'push');
            app.selectImgBtn.ButtonPushedFcn = createCallbackFcn(app, @uploadImg, true);
            app.selectImgBtn.IconAlignment = 'center';
            app.selectImgBtn.VerticalAlignment = 'bottom';
            app.selectImgBtn.FontSize = 10;
            app.selectImgBtn.Layout.Row = 1;
            app.selectImgBtn.Layout.Column = 2;
            app.selectImgBtn.Text = '上传图片';

            % Create Panel_3
            app.Panel_3 = uipanel(app.GridLayout);
            app.Panel_3.Title = '图像预处理';
            app.Panel_3.Layout.Row = [1 4];
            app.Panel_3.Layout.Column = 3;

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.Panel_3);
            app.GridLayout4.ColumnWidth = {'1x'};
            app.GridLayout4.RowHeight = {'1x', '1x', '1x', '1x', '1x'};

            % Create grayScaleBtn
            app.grayScaleBtn = uibutton(app.GridLayout4, 'push');
            app.grayScaleBtn.ButtonPushedFcn = createCallbackFcn(app, @grayScale, true);
            app.grayScaleBtn.Layout.Row = 1;
            app.grayScaleBtn.Layout.Column = 1;
            app.grayScaleBtn.Text = '灰度处理';

            % Create edgeDetectionBtn
            app.edgeDetectionBtn = uibutton(app.GridLayout4, 'push');
            app.edgeDetectionBtn.ButtonPushedFcn = createCallbackFcn(app, @edgeDetection, true);
            app.edgeDetectionBtn.Layout.Row = 2;
            app.edgeDetectionBtn.Layout.Column = 1;
            app.edgeDetectionBtn.Text = '边缘检测';

            % Create Panel_4
            app.Panel_4 = uipanel(app.GridLayout);
            app.Panel_4.Title = '车牌定位';
            app.Panel_4.Layout.Row = [1 4];
            app.Panel_4.Layout.Column = 4;

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.Panel_4);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {'1x', '1x', '1x', '1x'};

            % Create imeroadBtn
            app.imeroadBtn = uibutton(app.GridLayout5, 'push');
            app.imeroadBtn.ButtonPushedFcn = createCallbackFcn(app, @imeroadBtnButtonPushed, true);
            app.imeroadBtn.Layout.Row = 1;
            app.imeroadBtn.Layout.Column = 1;
            app.imeroadBtn.Text = '图像腐蚀';

            % Create smoothBtn
            app.smoothBtn = uibutton(app.GridLayout5, 'push');
            app.smoothBtn.ButtonPushedFcn = createCallbackFcn(app, @smoothBtnButtonPushed, true);
            app.smoothBtn.Layout.Row = 2;
            app.smoothBtn.Layout.Column = 1;
            app.smoothBtn.Text = '平滑处理';

            % Create deleteObjBtn
            app.deleteObjBtn = uibutton(app.GridLayout5, 'push');
            app.deleteObjBtn.ButtonPushedFcn = createCallbackFcn(app, @deleteObjBtnButtonPushed, true);
            app.deleteObjBtn.Layout.Row = 3;
            app.deleteObjBtn.Layout.Column = 1;
            app.deleteObjBtn.Text = '移除对象';

            % Create detectPasteBtn
            app.detectPasteBtn = uibutton(app.GridLayout5, 'push');
            app.detectPasteBtn.ButtonPushedFcn = createCallbackFcn(app, @detectPasteBtnButtonPushed, true);
            app.detectPasteBtn.Layout.Row = 4;
            app.detectPasteBtn.Layout.Column = 1;
            app.detectPasteBtn.Text = '定位剪贴';

            % Create Panel_5
            app.Panel_5 = uipanel(app.GridLayout);
            app.Panel_5.Title = '车牌识别';
            app.Panel_5.Layout.Row = [1 4];
            app.Panel_5.Layout.Column = 5;

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.Panel_5);
            app.GridLayout6.ColumnWidth = {'1x'};
            app.GridLayout6.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x'};

            % Create Button21
            app.Button21 = uibutton(app.GridLayout6, 'push');
            app.Button21.ButtonPushedFcn = createCallbackFcn(app, @Button21Pushed, true);
            app.Button21.Layout.Row = 1;
            app.Button21.Layout.Column = 1;
            app.Button21.Text = '灰度处理';

            % Create Button22
            app.Button22 = uibutton(app.GridLayout6, 'push');
            app.Button22.ButtonPushedFcn = createCallbackFcn(app, @Button22Pushed, true);
            app.Button22.Layout.Row = 2;
            app.Button22.Layout.Column = 1;
            app.Button22.Text = '直方图均衡化';

            % Create Button23
            app.Button23 = uibutton(app.GridLayout6, 'push');
            app.Button23.ButtonPushedFcn = createCallbackFcn(app, @ax23ButtonDown, true);
            app.Button23.Layout.Row = 3;
            app.Button23.Layout.Column = 1;
            app.Button23.Text = '二值化';

            % Create Button24
            app.Button24 = uibutton(app.GridLayout6, 'push');
            app.Button24.ButtonPushedFcn = createCallbackFcn(app, @Button24Pushed, true);
            app.Button24.Layout.Row = 4;
            app.Button24.Layout.Column = 1;
            app.Button24.Text = '移除对象';

            % Create Button25
            app.Button25 = uibutton(app.GridLayout6, 'push');
            app.Button25.ButtonPushedFcn = createCallbackFcn(app, @Button25Pushed, true);
            app.Button25.Layout.Row = 5;
            app.Button25.Layout.Column = 1;
            app.Button25.Text = '中值滤波';

            % Create Button26
            app.Button26 = uibutton(app.GridLayout6, 'push');
            app.Button26.ButtonPushedFcn = createCallbackFcn(app, @Button26Pushed, true);
            app.Button26.Layout.Row = 6;
            app.Button26.Layout.Column = 1;
            app.Button26.Text = '输出结果';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = DIP_m

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end