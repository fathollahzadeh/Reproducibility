WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS UserTotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Title IS NOT NULL
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) > 0
),
QuestionStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
),
FinalReport AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        qs.QuestionCount,
        qs.TotalViews,
        qs.AvgScore,
        COALESCE(bu.BadgeCount, 0) AS BadgeCount,
        CASE 
            WHEN qs.AvgScore IS NULL THEN 'No Score'
            WHEN qs.AvgScore > 5 THEN 'High Achiever'
            ELSE 'Needs Improvement'
        END AS PerformanceCategory
    FROM 
        Users u
    LEFT JOIN 
        QuestionStats qs ON u.Id = qs.OwnerUserId
    LEFT JOIN 
        BadgedUsers bu ON u.Id = bu.UserId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users) 
)
SELECT 
    fr.DisplayName,
    fr.Reputation,
    fr.QuestionCount,
    fr.TotalViews,
    fr.AvgScore,
    fr.BadgeCount,
    fr.PerformanceCategory
FROM 
    FinalReport fr
WHERE 
    fr.QuestionCount BETWEEN 5 AND 15 
    AND fr.TotalViews IS NOT NULL 
ORDER BY 
    fr.AvgScore DESC NULLS LAST
LIMIT 10;