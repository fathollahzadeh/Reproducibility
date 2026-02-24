
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryTypeName,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years'
        AND ph.Comment IS NULL 
    GROUP BY 
        ph.PostId, pht.Name
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Comment AS CloseReason,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.PostCount,
    us.TotalBounty,
    us.AverageScore,
    rp.Title AS TopPostTitle,
    rp.ViewCount,
    rp.Score,
    phd.HistoryTypeName,
    phd.ChangeCount,
    cp.Title AS ClosedPostTitle,
    cp.CloseReason
FROM 
    Users u
LEFT JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    ClosedPosts cp ON u.Id = cp.OwnerUserId
WHERE 
    u.Reputation IS NOT NULL
    AND (us.PostCount > 0 OR us.TotalBounty IS NOT NULL) 
ORDER BY 
    u.Reputation DESC, us.PostCount DESC, us.AverageScore DESC
LIMIT 100;
