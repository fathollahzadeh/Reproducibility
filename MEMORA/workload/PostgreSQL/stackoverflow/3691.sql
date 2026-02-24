
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS TotalBadges,
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
        OwnerUserId, 
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(ViewCount) AS TotalViews,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.QuestionCount, 0) AS Questions, 
        COALESCE(ps.AnswerCount, 0) AS Answers,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AverageViews, 0) AS AverageViews,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.AverageViews,
    ups.TotalBadges,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    CASE 
        WHEN ups.GoldBadges > 0 THEN 'Gold Badge Holder'
        WHEN ups.SilverBadges > 0 THEN 'Silver Badge Holder'
        WHEN ups.BronzeBadges > 0 THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    UserPostStats ups
WHERE 
    (ups.Questions > 0 OR ups.Answers > 0) 
    AND ups.TotalViews > (
        SELECT AVG(TotalViews) FROM PostStatistics
    )
ORDER BY 
    ups.TotalViews DESC
LIMIT 10;
