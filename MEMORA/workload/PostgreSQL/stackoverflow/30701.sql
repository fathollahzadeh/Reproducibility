
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        STRING_AGG(c.Text, '; ') AS CloseComments
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, ph.CreationDate, ph.UserDisplayName
)
SELECT 
    us.UserId,
    us.Reputation,
    us.TotalPosts,
    us.TotalBadges,
    us.TotalBounties,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score,
    rcp.ClosedPostId,
    rcp.ClosedDate,
    rcp.ClosedBy,
    rcp.CloseComments
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1 
LEFT JOIN 
    RecentClosedPosts rcp ON rp.PostId = rcp.ClosedPostId 
WHERE 
    us.Reputation > 100 
ORDER BY 
    us.Reputation DESC, rp.CreationDate DESC;
