%% 1：选择 IMU 和 UWB 距离话题
imuSel = select(bag, 'Topic', '/imu/imu');

uwbSel = select(bag, 'Topic', '/uwb_endorange_info');

fprintf('IMU 消息数：%d\n', imuSel.NumMessages);
fprintf('UWB 距离消息数：%d\n', uwbeSel.NumMessages);

%% 2：查看IMU前两条数据记录的时间差
imuTwoMsgs = readMessages(imuSel, [1 2], 'DataFormat', 'struct');

t1 = double(imuTwoMsgs{1}.Header.Stamp.Sec) ...
    + double(imuTwoMsgs{1}.Header.Stamp.Nsec) * 1e-9;

t2 = double(imuTwoMsgs{2}.Header.Stamp.Sec) ...
    + double(imuTwoMsgs{2}.Header.Stamp.Nsec) * 1e-9;

dtImu = t2 - t1;

fprintf('第 1 条 IMU 时间：%.9f s\n', t1);
fprintf('第 2 条 IMU 时间：%.9f s\n', t2);
fprintf('两条 IMU 记录的时间差：%.6f ms\n', dtImu * 1000);

%% 3：用 1000 个间隔计算 IMU 平均采样时间
imuMsgs = readMessages(imuSel, [1 1001], 'DataFormat', 'struct'); %1:2是一个区间间隔

t1 = double(imuMsgs{1}.Header.Stamp.Sec) ...
    + double(imuMsgs{1}.Header.Stamp.Nsec) * 1e-9;

t1001 = double(imuMsgs{2}.Header.Stamp.Sec) ...
    + double(imuMsgs{2}.Header.Stamp.Nsec) * 1e-9;

avgDtImu = (t1001 - t1) / 1000;

fprintf('1000 个 IMU 间隔总时长：%.6f s\n', t1001 - t1);
fprintf('IMU 平均采样间隔：%.6f ms\n', avgDtImu * 1000);
fprintf('IMU 平均采样频率：%.3f Hz\n', 1 / avgDtImu);

%%  4：计算UWB的平均采样时间
uwbMsgs = readMessages(uwbSel, [1 1001], 'DataFormat', 'struct'); %1:2是一个区间间隔

t1 = double(uwbMsgs{1}.Header.Stamp.Sec) ...
    + double(uwbMsgs{1}.Header.Stamp.Nsec) * 1e-9;

t1001 = double(uwbMsgs{2}.Header.Stamp.Sec) ...
    + double(uwbMsgs{2}.Header.Stamp.Nsec) * 1e-9;

avgDtImu = (t1001 - t1) / 1000;

fprintf('1000 个 UWB 间隔总时长：%.6f s\n', t1001 - t1);
fprintf('UWB 平均采样间隔：%.6f ms\n', avgDtImu * 1000);
fprintf('UWB 平均采样频率：%.3f Hz\n', 1 / avgDtImu);

%% 5：可视化 IMU 相邻记录时间间隔
imuAllMsgs = readMessages(imuSel, 'DataFormat', 'struct');

Nimu = numel(imuAllMsgs);
tImu = zeros(Nimu, 1);

for k = 1:Nimu
    stamp = imuAllMsgs{k}.Header.Stamp;

    tImu(k) = double(stamp.Sec) ...
        + double(stamp.Nsec) * 1e-9;
end


dtImu = diff(tImu);

figure('Color', 'w');
plot(tImu(2:end) - tImu(1), dtImu * 1000, 'r.');
grid on;
xlabel('相对时间 (s)');
ylabel('相邻 IMU 时间差 \Deltat (ms)');
title('IMU 相邻记录时间间隔');

%% 可视化 UWB 相邻记录时间间隔
uwbAllMsgs = readMessages(uwbSel, 'DataFormat', 'struct');

Nuwb = numel(uwbAllMsgs);
tUwb = zeros(Nuwb, 1);

for k = 1:Nuwb
stamp = uwbAllMsgs{k}.Header.Stamp;
tUwb(k) = double(stamp.Sec) + double(stamp.Nsec) * 1e-9;
end

% 现在进行排序
[tUwbSorted, order] = sort(tUwb);
uwbMsgsSorted = uwbAllMsgs(order);

dtUwb = diff(tUwbSorted);
fprintf('排序后负时间间隔个数：%d\n', sum(dtUwb < 0));

figure('Color', 'w');
plot(tUwbSorted(2:end) - tUwbSorted(1), dtUwb * 1000, 'b.');
grid on;
xlabel('从第一条 UWB 消息起经过的时间 (s)');
ylabel('与上一条 UWB 消息的间隔 (ms)');
title('UWB 相邻消息时间间隔');

% 找到UWB间隔图中 有一个为负值
idx = find(dtUwb < 0);

fprintf('负时间间隔个数：%d\n', numel(idx));
fprintf('最小时间间隔：%.3f ms\n', min(dtUwb) * 1000);

if ~isempty(idx)
    k = idx(1);
    fprintf('第一次出现在第 %d 与第 %d 条消息之间：%.3f ms\n', ...
        k, k+1, dtUwb(k) * 1000);
end


for k = 5799:5800
    m = uwbAllMsgs{k};
    fprintf('第 %d 条：时间戳 %.9f，机载节点 %d，锚点 %d，天线 %d\n', ...
        k, tUwb(k), m.RequesterId, m.ResponderId, m.Antenna);
end

% 核对负值
% disp(uwbSel.MessageList(5799:5800, :))
% format long      % 切换到长格式（15位有效数字）；
% disp(uwbSel.MessageList(5799:5800, :))
% for k = 5799:5800
% fprintf('第 %d 条：bag时间 %.9f，消息头时间 %.9f\n', ...
    % k, uwbSel.MessageList.Time(k), tUwb(k));
% end


fprintf('IMU：%.6f 至 %.6f s\n', tImu(1), tImu(end));
fprintf('UWB：%.6f 至 %.6f s\n', tUwbSorted(1), tUwbSorted(end));


j = find(tImu <= tUwbSorted(1), 1, 'last');

fprintf('第一条 UWB 位于第 %d 和第 %d 条 IMU 记录之间\n', j, j+1);
fprintf('距前一条 IMU：%.3f ms\n', (tUwbSorted(1)-tImu(j))*1000);
fprintf('距后一条 IMU：%.3f ms\n', (tImu(j+1)-tUwbSorted(1))*1000);

%% 每条 UWB 消息与最近 IMU 消息的时间差
imuIndex = interp1(tImu, (1:numel(tImu))', ...
    tUwbSorted, 'nearest');

timeDiffMs = (tUwbSorted - tImu(imuIndex)) * 1000;

figure('Color', 'w');
plot(tUwbSorted - tUwbSorted(1), timeDiffMs, 'b.');
yline(0, 'k--');
grid on;

xlabel('从第一条 UWB 消息起经过的时间 (s)');
ylabel('UWB 与最近 IMU 的时间差 (ms)');
title('UWB 和最近 IMU 消息的时间错位');


%% UWB 与最近 IMU 的时间差分布
figure('Color', 'w');
histogram(timeDiffMs, 60);
xline(0, 'r--');
yline(400, 'r--');
grid on;

xlabel('UWB 时间戳 − 最近 IMU 时间戳 (ms)');
ylabel('UWB 消息数量');
title('UWB 与最近 IMU 的时间差分布');

fprintf('时间差绝对值的中位数：%.3f ms\n', median(abs(timeDiffMs)));
fprintf('时间差绝对值的最大值：%.3f ms\n', max(abs(timeDiffMs)));

%% 10970数据的时间检查
fprintf('IMU 非正时间间隔数：%d\n', sum(diff(tImu) <= 0));
fprintf('排序后 UWB 非正时间间隔数：%d\n', ...
    sum(diff(tUwbSorted) <= 0));

imuRateAll = (numel(tImu) - 1) / (tImu(end) - tImu(1));
uwbRateAll = (numel(tUwbSorted) - 1) / ...
    (tUwbSorted(end) - tUwbSorted(1));

fprintf('IMU 整段平均消息频率：%.3f Hz\n', imuRateAll);
fprintf('UWB 整段平均消息频率：%.3f Hz\n', uwbRateAll);

%%uwbSel = select(bag, 'Topic', '/uwb_endorange_info');
uwbMsgs = readMessages(uwbSel, 1:10, 'DataFormat', 'struct');

for k = 1:numel(uwbMsgs)
    m = uwbMsgs{k};

    fprintf(['第 %d 条：机载节点 %d，天线编号 %d，' ...
        '基站 %d，距离 %.3f m\n'], ...
        k, m.RequesterId, m.Antenna, ...
        m.ResponderId, double(m.Distance));
end