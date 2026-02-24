WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.BadgeCount,
    ps.RelatedPostCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 6) AS CloseVotes,
    (SELECT MAX(p.CreationDate) FROM Posts p WHERE p.OwnerUserId = p.OwnerUserId) AS LastPostDate
FROM 
    PostStats ps
ORDER BY 
    ps.UpvoteCount DESC, ps.CommentCount DESC;