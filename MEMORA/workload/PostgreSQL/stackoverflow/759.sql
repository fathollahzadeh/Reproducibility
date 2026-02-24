
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS BadgePoints,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.BadgePoints,
    us.TotalBounty,
    rp.Title AS MostRecentPostTitle,
    rp.CreationDate AS MostRecentPostDate,
    COALESCE(cp.Comment, 'No reason provided') AS CloseReason,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE 'Older Posts'
    END AS PostCategory 
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPosts cp ON us.UserId = cp.UserId
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.BadgePoints DESC,
    us.TotalPosts DESC;
