WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        COALESCE(pm.TotalPosts, 0) AS TotalPosts,
        COALESCE(pm.QuestionsCount, 0) AS QuestionsCount,
        COALESCE(pm.AnswersCount, 0) AS AnswersCount,
        COALESCE(pm.TotalViews, 0) AS TotalViews,
        COALESCE(pm.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN PostMetrics pm ON u.Id = pm.OwnerUserId
)
SELECT 
    ue.UserId,
    ue.BadgeCount,
    ue.TotalPosts,
    ue.QuestionsCount,
    ue.AnswersCount,
    ue.TotalViews,
    ue.TotalScore,
    ROW_NUMBER() OVER (ORDER BY ue.TotalScore DESC) AS ScoreRanking
FROM 
    UserEngagement ue
WHERE 
    ue.TotalPosts > 0
ORDER BY 
    ue.TotalScore DESC, ue.BadgeCount DESC;
