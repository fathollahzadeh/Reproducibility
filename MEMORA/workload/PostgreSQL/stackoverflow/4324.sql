WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 10
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserPosts AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.Title AS TopPostTitle,
    rp.ViewCount,
    rp.Score,
    up.PostCount,
    up.TotalViews,
    up.TotalScore
FROM 
    RecentUsers u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.PostId
LEFT JOIN 
    UserPosts up ON u.DisplayName = up.DisplayName
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.Reputation DESC, rp.Score DESC
FETCH FIRST 10 ROWS ONLY;