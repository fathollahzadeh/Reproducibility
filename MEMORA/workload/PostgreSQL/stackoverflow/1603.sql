WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalBounties,
    rp.PostId,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViewCount,
    ph.HistoryDate,
    ph.HistoryType
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
WHERE 
    us.Reputation > 1000 AND 
    rp.PostId IS NOT NULL
ORDER BY 
    us.Reputation DESC, 
    rp.Score DESC;