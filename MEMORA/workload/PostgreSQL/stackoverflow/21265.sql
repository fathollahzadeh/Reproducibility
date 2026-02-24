WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 9 
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        pl.Name AS PostHistoryType,
        COUNT(*) AS ChangeCount,
        MIN(ph.CreationDate) AS FirstChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pl ON ph.PostHistoryTypeId = pl.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        ph.PostId, pl.Name
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.PositivePosts,
    u.AvgBounty,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ph.PostHistoryType,
    ph.ChangeCount,
    ph.FirstChangeDate
FROM 
    UserEngagement u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.PostId 
LEFT JOIN 
    RecentPostHistory ph ON rp.PostId = ph.PostId
WHERE 
    u.PostCount > 5 
    AND u.AvgBounty IS NOT NULL 
ORDER BY 
    u.PostCount DESC,
    rp.CreationDate DESC,
    ph.FirstChangeDate DESC
LIMIT 20;