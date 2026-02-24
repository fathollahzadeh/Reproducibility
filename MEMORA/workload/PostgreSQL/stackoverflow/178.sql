WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        c.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(rc.CommentCount, 0) AS RecentComments,
    COALESCE(pvs.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pvs.Downvotes, 0) AS TotalDownvotes,
    ub.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    RecentComments rc ON rp.Id = rc.PostId
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC 
LIMIT 10
OFFSET 0;