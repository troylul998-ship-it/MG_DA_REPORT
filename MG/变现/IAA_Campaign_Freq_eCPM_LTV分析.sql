-- ============================================================
-- 四款游戏新用户 Freq/DAU × eCPM × IAA LTV 分析
-- 维度：双端(iOS/Android/ALL)、LT7/30/60/90/120/180
-- 指标：总Freq、总LTV、总eCPM、RV LTV、RV eCPM、INT LTV、INT eCPM
-- 用户范围：2025-12-18 ~ 2026-06-16 新注册用户(been_reg_days=1)
-- 引擎：Presto/Trino
-- 注：使用 CUBE(platform) 自动生成分平台 + 汇总(ALL) 数据
-- ============================================================


-- ===================== UNO (game_id = 1000000) =====================
WITH new_users AS (
    SELECT DISTINCT
        date            AS reg_date,
        CAST(role_id AS VARCHAR) AS role_id,
        platform
    FROM dw_ods_mn01.dm_mn01_player_active_info
    WHERE been_reg_days = 1
      AND date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(client) = 'APP'
      AND is_adult = 1
      AND UPPER(platform) IN ('IOS', 'ANDROID')
),
daily_ad_metrics AS (
    SELECT
        a.date,
        CAST(a.role_id AS VARCHAR)                                              AS role_id,
        UPPER(a.platform)                                                       AS platform,
        n.reg_date,
        DATE_DIFF('day', DATE(n.reg_date), DATE(a.date))                        AS life_day,
        COALESCE(a.ad_reward_cnt_1d, 0)                                         AS rv_play_cnt,
        COALESCE(a.ad_interstitial_cnt_1d, 0)                                   AS int_play_cnt,
        (COALESCE(a.ad_reward_cnt_1d, 0) + COALESCE(a.ad_interstitial_cnt_1d, 0)) AS total_play_cnt,
        COALESCE(a.advalue_reward_sum_1d, 0)                                    AS rv_revenue,
        COALESCE(a.advalue_interstitial_sum_1d, 0)                              AS int_revenue,
        COALESCE(a.advalue_sum_1d, 0)                                           AS total_revenue
    FROM dw_ods_mn01.dm_mn01_player_active_info a
    JOIN new_users n
      ON CAST(a.role_id AS VARCHAR) = n.role_id
      AND a.date >= n.reg_date
      AND UPPER(a.platform) = UPPER(n.platform)
    WHERE a.date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(a.client) = 'APP'
),
lifecycle_metrics AS (
    SELECT
        'UNO' AS game,
        platform,
        role_id,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END AS lt_stage,
        COUNT(DISTINCT date)   AS active_days,
        SUM(total_play_cnt)    AS total_adplay,
        SUM(rv_play_cnt)       AS total_rv_play,
        SUM(int_play_cnt)      AS total_int_play,
        SUM(total_revenue)     AS total_ad_revenue,
        SUM(rv_revenue)        AS total_rv_revenue,
        SUM(int_revenue)       AS total_int_revenue
    FROM daily_ad_metrics
    WHERE life_day BETWEEN 0 AND 179
    GROUP BY 1, 2, 3,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END
)
SELECT
    game                                                                                    AS "游戏",
    lt_stage                                                                                AS "生命周期",
    COALESCE(platform, 'ALL')                                                               AS "平台",
    COUNT(DISTINCT role_id)                                                                 AS "用户数",
    ROUND(CAST(SUM(total_adplay) AS DOUBLE) / NULLIF(SUM(active_days), 0), 4)               AS "Freq_per_DAU",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) / COUNT(DISTINCT role_id), 4)               AS "总IAA_LTV",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_adplay), 0), 4)   AS "总eCPM",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) / COUNT(DISTINCT role_id), 4)               AS "RV_LTV",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_rv_play), 0), 4)  AS "RV_eCPM",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) / COUNT(DISTINCT role_id), 4)              AS "INT_LTV",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_int_play), 0), 4) AS "INT_eCPM"
FROM lifecycle_metrics
WHERE lt_stage IS NOT NULL
GROUP BY 1, 2, CUBE(platform);


-- ===================== P10 (game_id = 1019) =====================
WITH new_users_p10 AS (
    SELECT DISTINCT
        date            AS reg_date,
        CAST(account_id AS VARCHAR) AS account_id,
        platform
    FROM dw_ods_common_mn02.dm_mn02_player_active_info
    WHERE been_reg_days = 1
      AND date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(client) = 'APP'
      AND UPPER(platform) IN ('IOS', 'ANDROID')
),
daily_ad_metrics_p10 AS (
    SELECT
        a.date,
        CAST(a.account_id AS VARCHAR)                                            AS account_id,
        UPPER(a.platform)                                                        AS platform,
        n.reg_date,
        DATE_DIFF('day', DATE(n.reg_date), DATE(a.date))                         AS life_day,
        COALESCE(a.ad_view_cnt_1d, 0)                                            AS rv_play_cnt,
        COALESCE(a.ad_interstitial_cnt_1d, 0)                                    AS int_play_cnt,
        (COALESCE(a.ad_view_cnt_1d, 0) + COALESCE(a.ad_interstitial_cnt_1d, 0)) AS total_play_cnt,
        COALESCE(a.advalue_reward_sum_1d, 0)                                     AS rv_revenue,
        COALESCE(a.advalue_interstitial_sum_1d, 0)                               AS int_revenue,
        COALESCE(a.advalue_sum_1d, 0)                                            AS total_revenue
    FROM dw_ods_common_mn02.dm_mn02_player_active_info a
    JOIN new_users_p10 n
      ON CAST(a.account_id AS VARCHAR) = n.account_id
      AND a.date >= n.reg_date
      AND UPPER(a.platform) = UPPER(n.platform)
    WHERE a.date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(a.client) = 'APP'
),
lifecycle_metrics_p10 AS (
    SELECT
        'P10' AS game,
        platform,
        account_id,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END AS lt_stage,
        COUNT(DISTINCT date)   AS active_days,
        SUM(total_play_cnt)    AS total_adplay,
        SUM(rv_play_cnt)       AS total_rv_play,
        SUM(int_play_cnt)      AS total_int_play,
        SUM(total_revenue)     AS total_ad_revenue,
        SUM(rv_revenue)        AS total_rv_revenue,
        SUM(int_revenue)       AS total_int_revenue
    FROM daily_ad_metrics_p10
    WHERE life_day BETWEEN 0 AND 179
    GROUP BY 1, 2, 3,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END
)
SELECT
    game                                                                                    AS "游戏",
    lt_stage                                                                                AS "生命周期",
    COALESCE(platform, 'ALL')                                                               AS "平台",
    COUNT(DISTINCT account_id)                                                              AS "用户数",
    ROUND(CAST(SUM(total_adplay) AS DOUBLE) / NULLIF(SUM(active_days), 0), 4)               AS "Freq_per_DAU",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) / COUNT(DISTINCT account_id), 4)            AS "总IAA_LTV",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_adplay), 0), 4)   AS "总eCPM",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) / COUNT(DISTINCT account_id), 4)            AS "RV_LTV",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_rv_play), 0), 4)  AS "RV_eCPM",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) / COUNT(DISTINCT account_id), 4)           AS "INT_LTV",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_int_play), 0), 4) AS "INT_eCPM"
FROM lifecycle_metrics_p10
WHERE lt_stage IS NOT NULL
GROUP BY 1, 2, CUBE(platform);


-- ===================== SKB (game_id = 1000008) =====================
WITH new_users_skb AS (
    SELECT DISTINCT
        date            AS reg_date,
        CAST(account_id AS VARCHAR) AS account_id,
        platform
    FROM dw_ods_common_mn04.dm_mn04_player_active_info
    WHERE been_reg_days = 1
      AND date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(client) = 'APP'
      AND UPPER(platform) IN ('IOS', 'ANDROID')
),
daily_ad_metrics_skb AS (
    SELECT
        a.date,
        CAST(a.account_id AS VARCHAR)                                            AS account_id,
        UPPER(a.platform)                                                        AS platform,
        n.reg_date,
        DATE_DIFF('day', DATE(n.reg_date), DATE(a.date))                         AS life_day,
        COALESCE(a.ad_reward_cnt_1d, 0)                                          AS rv_play_cnt,
        COALESCE(a.ad_interstitial_cnt_1d, 0)                                    AS int_play_cnt,
        (COALESCE(a.ad_reward_cnt_1d, 0) + COALESCE(a.ad_interstitial_cnt_1d, 0)) AS total_play_cnt,
        COALESCE(a.advalue_reward_sum_1d, 0)                                     AS rv_revenue,
        COALESCE(a.advalue_interstitial_sum_1d, 0)                               AS int_revenue,
        COALESCE(a.advalue_sum_1d, 0)                                            AS total_revenue
    FROM dw_ods_common_mn04.dm_mn04_player_active_info a
    JOIN new_users_skb n
      ON CAST(a.account_id AS VARCHAR) = n.account_id
      AND a.date >= n.reg_date
      AND UPPER(a.platform) = UPPER(n.platform)
    WHERE a.date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(a.client) = 'APP'
),
lifecycle_metrics_skb AS (
    SELECT
        'SKB' AS game,
        platform,
        account_id,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END AS lt_stage,
        COUNT(DISTINCT date)   AS active_days,
        SUM(total_play_cnt)    AS total_adplay,
        SUM(rv_play_cnt)       AS total_rv_play,
        SUM(int_play_cnt)      AS total_int_play,
        SUM(total_revenue)     AS total_ad_revenue,
        SUM(rv_revenue)        AS total_rv_revenue,
        SUM(int_revenue)       AS total_int_revenue
    FROM daily_ad_metrics_skb
    WHERE life_day BETWEEN 0 AND 179
    GROUP BY 1, 2, 3,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END
)
SELECT
    game                                                                                    AS "游戏",
    lt_stage                                                                                AS "生命周期",
    COALESCE(platform, 'ALL')                                                               AS "平台",
    COUNT(DISTINCT account_id)                                                              AS "用户数",
    ROUND(CAST(SUM(total_adplay) AS DOUBLE) / NULLIF(SUM(active_days), 0), 4)               AS "Freq_per_DAU",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) / COUNT(DISTINCT account_id), 4)            AS "总IAA_LTV",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_adplay), 0), 4)   AS "总eCPM",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) / COUNT(DISTINCT account_id), 4)            AS "RV_LTV",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_rv_play), 0), 4)  AS "RV_eCPM",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) / COUNT(DISTINCT account_id), 4)           AS "INT_LTV",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_int_play), 0), 4) AS "INT_eCPM"
FROM lifecycle_metrics_skb
WHERE lt_stage IS NOT NULL
GROUP BY 1, 2, CUBE(platform);


-- ===================== UNO2 (game_id = 1000014) =====================
-- 差异点：UNO2 使用 ad_log 明细表拆分 adplay/advalue，需 FULL OUTER JOIN
-- Android advalue 需除以 1000000
WITH new_users_uno2 AS (
    SELECT DISTINCT
        date            AS reg_date,
        CAST(role_id AS VARCHAR) AS role_id,
        UPPER(platform)          AS platform
    FROM dw_ods_mn08.dm_mn08_player_active_info
    WHERE been_reg_days = 1
      AND date BETWEEN '2025-12-18' AND '2026-06-16'
      AND UPPER(client) = 'APP'
      AND UPPER(platform) IN ('IOS', 'ANDROID')
),
ad_play_uno2 AS (
    SELECT
        a.date,
        CAST(a.role_id AS VARCHAR)                         AS role_id,
        UPPER(a.platform)                                  AS platform,
        n.reg_date,
        DATE_DIFF('day', DATE(n.reg_date), DATE(a.date))   AS life_day,
        COUNT(IF(LOWER(a.adtype) = 'rewardvideo', 1, NULL))  AS rv_play_cnt,
        COUNT(IF(LOWER(a.adtype) = 'interstitial', 1, NULL)) AS int_play_cnt,
        COUNT(*)                                           AS total_play_cnt
    FROM dw_ods_mn08.c_client_app_ad_log a
    JOIN new_users_uno2 n
      ON CAST(a.role_id AS VARCHAR) = n.role_id
      AND a.date >= n.reg_date
      AND UPPER(a.platform) = n.platform
    WHERE a.date BETWEEN '2025-12-18' AND '2026-06-16'
      AND a.log_subtype = 'adplay'
      AND a.status = 1
    GROUP BY 1, 2, 3, 4, 5
),
ad_value_uno2 AS (
    SELECT
        a.date,
        CAST(a.role_id AS VARCHAR)   AS role_id,
        UPPER(a.platform)            AS platform,
        n.reg_date,
        DATE_DIFF('day', DATE(n.reg_date), DATE(a.date)) AS life_day,
        SUM(CASE WHEN LOWER(a.adtype) = 'rewardvideo'
                 THEN CASE WHEN UPPER(a.platform) = 'IOS' THEN CAST(a.value AS DOUBLE)
                           ELSE CAST(a.value AS DOUBLE) / 1000000 END
                 ELSE 0 END) AS rv_revenue,
        SUM(CASE WHEN LOWER(a.adtype) = 'interstitial'
                 THEN CASE WHEN UPPER(a.platform) = 'IOS' THEN CAST(a.value AS DOUBLE)
                           ELSE CAST(a.value AS DOUBLE) / 1000000 END
                 ELSE 0 END) AS int_revenue,
        SUM(CASE WHEN UPPER(a.platform) = 'IOS' THEN CAST(a.value AS DOUBLE)
                 ELSE CAST(a.value AS DOUBLE) / 1000000 END) AS total_revenue
    FROM dw_ods_mn08.c_client_app_ad_log a
    JOIN new_users_uno2 n
      ON CAST(a.role_id AS VARCHAR) = n.role_id
      AND a.date >= n.reg_date
      AND UPPER(a.platform) = n.platform
    WHERE a.date BETWEEN '2025-12-18' AND '2026-06-16'
      AND a.log_subtype = 'advalue'
    GROUP BY 1, 2, 3, 4, 5
),
daily_merged AS (
    SELECT
        COALESCE(p.date, v.date)         AS date,
        COALESCE(p.role_id, v.role_id)   AS role_id,
        COALESCE(p.platform, v.platform) AS platform,
        COALESCE(p.reg_date, v.reg_date) AS reg_date,
        COALESCE(p.life_day, v.life_day) AS life_day,
        COALESCE(p.rv_play_cnt, 0)       AS rv_play_cnt,
        COALESCE(p.int_play_cnt, 0)      AS int_play_cnt,
        COALESCE(p.total_play_cnt, 0)    AS total_play_cnt,
        COALESCE(v.rv_revenue, 0)        AS rv_revenue,
        COALESCE(v.int_revenue, 0)       AS int_revenue,
        COALESCE(v.total_revenue, 0)     AS total_revenue
    FROM ad_play_uno2 p
    FULL OUTER JOIN ad_value_uno2 v
      ON p.date = v.date AND p.role_id = v.role_id AND p.platform = v.platform
),
lifecycle_metrics_uno2 AS (
    SELECT
        'UNO2' AS game,
        platform,
        role_id,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END AS lt_stage,
        COUNT(DISTINCT date)   AS active_days,
        SUM(total_play_cnt)    AS total_adplay,
        SUM(rv_play_cnt)       AS total_rv_play,
        SUM(int_play_cnt)      AS total_int_play,
        SUM(total_revenue)     AS total_ad_revenue,
        SUM(rv_revenue)        AS total_rv_revenue,
        SUM(int_revenue)       AS total_int_revenue
    FROM daily_merged
    WHERE life_day BETWEEN 0 AND 179
    GROUP BY 1, 2, 3,
        CASE
            WHEN life_day BETWEEN 0 AND 6 THEN 'LT7'
            WHEN life_day BETWEEN 0 AND 29 THEN 'LT30'
            WHEN life_day BETWEEN 0 AND 59 THEN 'LT60'
            WHEN life_day BETWEEN 0 AND 89 THEN 'LT90'
            WHEN life_day BETWEEN 0 AND 119 THEN 'LT120'
            WHEN life_day BETWEEN 0 AND 179 THEN 'LT180'
        END
)
SELECT
    game                                                                                    AS "游戏",
    lt_stage                                                                                AS "生命周期",
    COALESCE(platform, 'ALL')                                                               AS "平台",
    COUNT(DISTINCT role_id)                                                                 AS "用户数",
    ROUND(CAST(SUM(total_adplay) AS DOUBLE) / NULLIF(SUM(active_days), 0), 4)               AS "Freq_per_DAU",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) / COUNT(DISTINCT role_id), 4)               AS "总IAA_LTV",
    ROUND(CAST(SUM(total_ad_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_adplay), 0), 4)   AS "总eCPM",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) / COUNT(DISTINCT role_id), 4)               AS "RV_LTV",
    ROUND(CAST(SUM(total_rv_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_rv_play), 0), 4)  AS "RV_eCPM",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) / COUNT(DISTINCT role_id), 4)              AS "INT_LTV",
    ROUND(CAST(SUM(total_int_revenue) AS DOUBLE) * 1000 / NULLIF(SUM(total_int_play), 0), 4) AS "INT_eCPM"
FROM lifecycle_metrics_uno2
WHERE lt_stage IS NOT NULL
GROUP BY 1, 2, CUBE(platform);
