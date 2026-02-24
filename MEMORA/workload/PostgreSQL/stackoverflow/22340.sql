
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COALESCE((SELECT SUM(v.BountyAmount) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)), 0) AS TotalBounty
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND (p.Title IS NOT NULL OR p.Body IS NOT NULL)
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 2) AS TotalUpvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate < '2024-10-01 12:34:56' 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), UserTopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        u.DisplayName,
        u.Reputation,
        r.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY r.OwnerUserId ORDER BY r.Score DESC) AS PostRank
    FROM 
        RankedPosts r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
    WHERE 
        r.rn <= 3
)
SELECT 
    utp.PostId,
    utp.Title,
    utp.CreationDate,
    utp.Score,
    utp.ViewCount,
    utp.DisplayName,
    utp.Reputation,
    utp.TotalBounty
FROM 
    UserTopPosts utp
JOIN 
    UserStats us ON utp.DisplayName = us.DisplayName
WHERE 
    us.TotalPosts > 5 
    AND (utp.Score IS NOT NULL AND utp.ViewCount IS NOT NULL) 
ORDER BY 
    utp.Reputation DESC, utp.Score DESC
LIMIT 10 OFFSET 0;
