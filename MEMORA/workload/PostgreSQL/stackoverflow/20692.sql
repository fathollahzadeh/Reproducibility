
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE 
                WHEN p.ViewCount > 100 THEN 1 
                ELSE 0 
            END) AS PopularPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 

PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        MAX(p.ViewCount) AS MaxViews,
        MIN(p.ViewCount) AS MinViews,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 

CombinedStatistics AS (
    SELECT 
        uu.DisplayName,
        uu.TotalBadges,
        ps.PostCount,
        ps.AverageScore,
        ps.MaxViews,
        ps.MinViews,
        ps.ClosedPosts,
        RANK() OVER (ORDER BY uu.TotalBadges DESC) AS BadgeRank,
        RANK() OVER (ORDER BY ps.AverageScore DESC) AS ScoreRank
    FROM 
        UserReputation uu
    LEFT JOIN 
        PostStatistics ps ON uu.UserId = ps.OwnerUserId
)

SELECT 
    cs.DisplayName,
    cs.TotalBadges,
    cs.PostCount,
    cs.AverageScore,
    cs.MaxViews,
    cs.MinViews,
    cs.ClosedPosts,
    CASE 
        WHEN cs.BadgeRank IS NULL THEN 'Unranked'
        ELSE CAST(cs.BadgeRank AS VARCHAR)
    END AS BadgeRanking,
    CASE 
        WHEN cs.ScoreRank IS NULL THEN 'Unranked'
        ELSE CAST(cs.ScoreRank AS VARCHAR)
    END AS ScoreRanking
FROM 
    CombinedStatistics cs
WHERE 
    cs.PostCount > 5 
    AND cs.TotalBadges > 0 
    AND COALESCE(cs.ClosedPosts, 0) < (SELECT AVG(ClosedPosts) FROM PostStatistics)
ORDER BY 
    cs.MaxViews DESC, cs.AverageScore DESC;
