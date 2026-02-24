WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.QuestionsCount,
        ps.AnswersCount,
        ps.TotalScore,
        ps.TotalViews
    FROM 
        UserBadgeCounts ub
    LEFT JOIN 
        PostStatistics ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    COALESCE(QuestionsCount, 0) AS QuestionsCount,
    COALESCE(AnswersCount, 0) AS AnswersCount,
    COALESCE(TotalScore, 0) AS TotalScore,
    COALESCE(TotalViews, 0) AS TotalViews
FROM 
    CombinedStats
ORDER BY 
    BadgeCount DESC, TotalScore DESC
LIMIT 10;