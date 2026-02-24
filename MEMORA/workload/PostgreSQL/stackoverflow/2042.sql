WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id
)
SELECT 
    us.DisplayName,
    us.PostCount,
    us.TotalScore,
    us.TotalBounties,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    CASE 
        WHEN rp.Rank = 1 THEN 'Best Post'
        ELSE NULL 
    END AS IsBestPost
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.PostCount > 5 
    AND (us.TotalScore IS NOT NULL OR us.TotalBounties > 0)
ORDER BY 
    us.TotalScore DESC, us.PostCount DESC
LIMIT 100;