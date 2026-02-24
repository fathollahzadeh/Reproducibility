
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text,
        c.CreationDate,
        c.UserDisplayName,
        RANK() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ua.DisplayName AS TopUser,
    ua.BadgeCount,
    ua.TotalBounties,
    rc.CommentId,
    rc.Text AS RecentCommentText,
    rc.CreationDate AS RecentCommentDate
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON ua.BadgeCount = (
        SELECT MAX(BadgeCount) 
        FROM UserActivity
    )
LEFT JOIN 
    RecentComments rc ON rc.PostId = rp.PostId AND rc.CommentRank = 1
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
