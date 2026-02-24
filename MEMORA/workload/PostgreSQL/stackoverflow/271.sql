WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ps.CloseCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpvoteCount DESC) AS Rank
    FROM 
        PostStats ps
    WHERE 
        ps.UpvoteCount - ps.DownvoteCount > 0
)
SELECT 
    t.Title,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    t.CloseCount,
    u.DisplayName,
    COALESCE(ub.GoldCount, 0) AS GoldBadges,
    COALESCE(ub.SilverCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeCount, 0) AS BronzeBadges
FROM 
    TopPosts t
JOIN 
    Posts p ON t.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeCounts ub ON ub.UserId = u.Id
WHERE 
    t.Rank <= 10
ORDER BY 
    t.UpvoteCount DESC;