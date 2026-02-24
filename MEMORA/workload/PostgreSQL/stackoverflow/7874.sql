WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND p.Score > 0
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    ap.PostId,
    ap.Title,
    ap.CreationDate,
    ap.Score,
    ap.AnswerCount,
    ap.CommentCount,
    ap.ViewCount,
    pvs.Upvotes,
    pvs.Downvotes,
    pvs.TotalVotes
FROM 
    UserBadges up
JOIN 
    ActivePosts ap ON up.UserId = ap.OwnerUserId
JOIN 
    PostVoteStats pvs ON ap.PostId = pvs.PostId
ORDER BY 
    up.BadgeCount DESC, ap.Score DESC
LIMIT 
    100;