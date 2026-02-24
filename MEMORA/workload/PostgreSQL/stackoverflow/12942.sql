
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypesStatistics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Name
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.TotalScore,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    pt.PostTypeName,
    pt.PostCount AS PostTypeCount,
    pt.AvgViewCount,
    pt.AvgAnswerCount,
    pt.TotalScore AS PostTypeScore
FROM 
    UserStatistics u
CROSS JOIN 
    PostTypesStatistics pt
ORDER BY 
    u.TotalScore DESC, 
    pt.TotalScore DESC;
