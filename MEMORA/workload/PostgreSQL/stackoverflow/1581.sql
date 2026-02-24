
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(*) AS TotalPosts, 
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '15 days'
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    us.DisplayName AS UserDisplayName, 
    us.TotalPosts, 
    us.TotalBounties, 
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.PostId, rp.Score DESC;
