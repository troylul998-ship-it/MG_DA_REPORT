---
inclusion: manual
---

# 数据分析全流程 Skill

## 概述

本 Skill 定义了一个从需求获取到报告交付的完整数据分析工作流。适用于 Mobile Growth 团队的变现分析、AB 测试分析等场景。

## 工作流步骤

### Step 1: 需求获取

**输入**: 飞书群消息 / 用户口头描述
**操作**:
- 使用 `mcp_lark_mcp_im_v1_message_list` 从指定飞书群读取最近消息
- 识别分析需求：分析对象（哪些产品）、分析维度（平台/广告类型/生命周期等）、时间范围
- 确认数据口径和指标定义

**输出**: 明确的分析需求文档（产品、维度、指标、时间范围）

**常用群 chat_id**:
- MG 变现小群: `oc_9b0689b9a37e1eebf014fb39d8c78638`
- 赛博牛马: `oc_44ce402d9ee9d0f901b61e6885cc33b1`

---

### Step 2: 数据埋点与口径确认

**输入**: 分析需求
**操作**:
- 使用 `mcp-atlassian` 的 `confluence_get_page` 工具查询 Confluence 上的埋点文档
- 确认各产品的数据表名、字段名、埋点逻辑
- 注意不同产品的差异（如 UNO 用 role_id，P10/SKB 用 account_id，UNO2 用 ad_log 明细表等）

**关键数据源**:
| 产品 | 活跃表 | 广告数据 | 用户ID字段 |
|------|--------|----------|------------|
| UNO | dw_ods_mn01.dm_mn01_player_active_info | 同表(聚合字段) | role_id |
| P10 | dw_ods_common_mn02.dm_mn02_player_active_info | 同表(聚合字段) | account_id |
| SKB | dw_ods_common_mn04.dm_mn04_player_active_info | 同表(聚合字段) | account_id |
| UNO2 | dw_ods_mn08.dm_mn08_player_active_info | dw_ods_mn08.c_client_app_ad_log(明细) | role_id |

**UNO2 特殊说明**:
- 广告播放和广告价值分开统计（adplay/advalue 两个 log_subtype）
- Android 的 advalue 需要除以 1000000
- 需要 FULL OUTER JOIN 合并播放次数和收入数据

**输出**: 确认的数据口径和表结构

---

### Step 3: 编写 SQL

**输入**: 数据口径
**操作**:
- 基于确认的表结构编写 Presto/Trino SQL
- 使用 `mcp_bi_analyse_client` 的 `sql_query` 工具执行 SQL 获取数据
- SQL 模板结构：新用户筛选 → 日维度广告指标 → 生命周期聚合 → 最终汇总

**SQL 编写规范**:
- 引擎：Presto/Trino
- 新用户标识：`been_reg_days = 1`
- 客户端过滤：`UPPER(client) = 'APP'`
- 平台过滤：`UPPER(platform) IN ('IOS', 'ANDROID')`
- 生命周期分段：LT7/LT30/LT60/LT90/LT120/LT180（累积式，非增量式）
- 核心指标：Freq/DAU、eCPM（×1000）、IAA LTV

**输出**: 可执行的 SQL 文件，保存到 `MG/变现/` 目录

---

### Step 4: 生成分析报告 HTML

**输入**: SQL 查询结果数据
**操作**:
- 创建自包含 HTML 文件（使用 ECharts CDN）
- 图表结构：
  - 整体概览（合并双端，分产品对比）：总eCPM / RV eCPM / INT eCPM / Freq / 总LTV / RV LTV / INT LTV
  - 分平台详情（分产品 × 分双端）：每个指标 Android + iOS 各一张
  - 特殊对比图（如 P10 RV vs INT）
- 包含核心结论摘要
- 文件保存到 `MG/变现/` 目录

**HTML 规范**:
- 引用 `https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js`
- 数据硬编码在 JS 变量中（自包含，无外部依赖）
- 响应式布局（grid）
- 支持 window resize

**输出**: 完整的 HTML 分析报告

---

### Step 5: 部署到公开 HTML

**输入**: HTML 报告文件
**操作**:
- 复制 HTML 为根目录 `index.html`
- Git 提交并推送到 GitHub：
  ```bash
  git add index.html "MG/变现/报告文件.html"
  git commit -m "deploy: 报告描述"
  git push origin main
  ```
- 确认 GitHub Pages 已启用（Settings > Pages > main branch / root）

**GitHub 仓库**: `https://github.com/troylul998-ship-it/MG_DA_REPORT`
**部署地址**: `https://troylul998-ship-it.github.io/MG_DA_REPORT/`

**注意**: 推送后等待 1-3 分钟 GitHub Pages 自动部署

**输出**: 可公开访问的报告 URL

---

### Step 6: 生成飞书文档

**输入**: 分析报告内容 + SQL 代码
**操作**:
- 准备 Markdown 格式的文档内容（标题、结论、维度说明、SQL 代码块）
- 使用 `lark-cli docs +update` 写入飞书文档：
  ```bash
  lark-cli docs +update --doc "飞书文档URL" --command overwrite --doc-format markdown --content "@本地md文件路径"
  ```

**lark-cli 配置**:
- App ID: `cli_a92474aa16b91bce`
- 切换身份：`echo "secret" | lark-cli config init --app-id cli_a92474aa16b91bce --app-secret-stdin`

**文档结构模板**:
```markdown
# 📊 报告标题

> 用户范围 | 维度说明

📎 **完整交互报告：** [报告名称](部署URL)

---

## 🔑 核心结论
- 结论1
- 结论2
...

---

## 📝 分析维度说明
| 维度 | 范围 |
|------|------|
...

---

## 📊 分产品概要
### 产品1
...

---

## 💻 分析 SQL 代码
### 产品名 (表名)
```sql
SQL代码
```
```

**输出**: 格式化的飞书文档（含代码块）

---

### Step 7: 发送飞书卡片总结

**输入**: 核心结论 + 报告链接 + 文档链接
**操作**:
- 使用 `mcp_lark_mcp_im_v1_message_create` 发送 interactive 类型消息
- 卡片模板（green 主题）包含：报告概要、核心结论、分产品概要、链接
- @相关人员：在 lark_md 内容中使用 `<at id=open_id>姓名</at>`

**常用 @人 ID**:
- 李超(Aric): `ou_42dc86ba9e33cd81a2c81fa0a68d4e00`

**飞书卡片 JSON 模板**:
```json
{
  "config": {"wide_screen_mode": true},
  "header": {"title": {"tag": "plain_text", "content": "标题"}, "template": "green"},
  "elements": [
    {"tag": "div", "text": {"tag": "lark_md", "content": "正文内容"}},
    {"tag": "hr"},
    {"tag": "div", "text": {"tag": "lark_md", "content": "**结论部分**"}}
  ]
}
```

**注意事项**:
- 发送到群用 `receive_id_type: "chat_id"`
- 私聊需要获取该 app 下的 open_id（不同 app 的 open_id 不同）
- 链接文字中不要出现 "GitHub Pages" 等技术术语

**输出**: 飞书群里的卡片消息

---

## 快速复用指南

1. 告诉我"做一个XX分析"
2. 我会按上述 7 步执行
3. 每步完成后简要汇报，遇到需要确认的地方会暂停

## 环境依赖

- Git（推送到 GitHub）
- lark-cli（写飞书文档）
- MCP servers: lark-mcp（飞书消息）、bi-analyse-client（数据查询）、mcp-atlassian（Confluence）
