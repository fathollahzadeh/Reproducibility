
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
PostsWithLastEdit AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.LastEditDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.LastEditDate DESC) AS rn
    FROM Posts p
    WHERE p.LastEditDate IS NOT NULL
),
ActiveUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        COALESCE(p.TotalPosts, 0) AS TotalPosts,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(p.QuestionCount, 0) AS QuestionCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.TotalScore, 0) AS TotalScore
    FROM Users u
    LEFT JOIN PostStatistics p ON u.Id = p.OwnerUserId
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    WHERE u.Reputation > 1000
),
MostActivePosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.LastEditDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.LastEditDate DESC) AS rn
    FROM Posts p
)
SELECT 
    au.Id AS UserID,
    au.DisplayName,
    au.TotalPosts,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    au.QuestionCount,
    au.AnswerCount,
    au.TotalScore,
    mp.Title AS MostRecentPostTitle,
    mp.LastEditDate AS MostRecentPostEditDate
FROM ActiveUsers au
LEFT JOIN MostActivePosts mp ON au.Id = mp.OwnerUserId AND mp.rn = 1
ORDER BY au.TotalScore DESC, au.DisplayName;
