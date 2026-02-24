
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        MAX(u.Reputation) AS MaxReputation,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.MaxReputation,
    us.AvgReputation,
    rp.Title,
    rp.ViewCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'Unscored'
        WHEN rp.Score > 10 THEN 'Highly Scored'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN us.AvgReputation IS NULL THEN 'No Reputation Data'
        ELSE CONCAT('User ', us.DisplayName, ' has an average reputation of ', ROUND(us.AvgReputation, 2))
    END AS ReputationInfo
FROM 
    UserStatistics us
FULL OUTER JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.TotalPosts > 0 OR rp.Rank IS NOT NULL
ORDER BY 
    us.MaxReputation DESC, rp.ViewCount DESC;
