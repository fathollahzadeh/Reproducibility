
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT AVG(v.BountyAmount) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id 
                  AND v.VoteTypeId IN (8, 9)), 0) AS AvgBounty
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MAX(u.CreationDate) AS AccountCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    us.DisplayName AS OwnerName,
    us.PostCount,
    us.TotalScore,
    r.AvgBounty,
    cp.CloseReasons
FROM 
    RankedPosts r
JOIN 
    UserStats us ON r.OwnerUserId = us.UserId
LEFT JOIN 
    ClosedPosts cp ON r.PostId = cp.PostId
WHERE 
    r.Rank = 1
ORDER BY 
    r.Score DESC
LIMIT 100;
