WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        u.Id AS OwnerUserId,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY p.Id, p.PostTypeId, u.Id, u.Reputation
)
SELECT 
    pst.PostId,
    pst.PostTypeId,
    pst.OwnerUserId,
    pst.OwnerReputation,
    pst.CommentCount,
    pst.VoteCount,
    pst.BadgeCount,
    pst.UpvoteCount,
    pst.DownvoteCount,
    CASE 
        WHEN pst.PostTypeId = 1 THEN 'Question' 
        WHEN pst.PostTypeId = 2 THEN 'Answer' 
        END AS PostType
FROM PostStatistics pst
ORDER BY pst.VoteCount DESC, pst.CommentCount DESC;