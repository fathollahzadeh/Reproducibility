WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE 
                WHEN b.Class = 1 THEN 1 
                ELSE 0 
            END) AS GoldBadgeCount,
        SUM(CASE 
                WHEN b.Class = 2 THEN 1 
                ELSE 0 
            END) AS SilverBadgeCount,
        SUM(CASE 
                WHEN b.Class = 3 THEN 1 
                ELSE 0 
            END) AS BronzeBadgeCount
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
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageViews, 0) AS AverageViews,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(bc.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(bc.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(bc.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts bc ON u.Id = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    AverageViews,
    BadgeCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount
FROM 
    UserPerformance
ORDER BY 
    TotalScore DESC, 
    PostCount DESC
LIMIT 10;
