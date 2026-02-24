WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as Rank,
        COALESCE(b.Id, 0) AS BadgeId
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId 
                   AND b.Class = 1  
                   AND b.Date > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    WHERE 
        p.PostTypeId = 1  
),
AnswersWithVotes AS (
    SELECT 
        a.Id AS AnswerId,
        a.Score,
        a.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts a
    LEFT JOIN 
        Votes v ON a.Id = v.PostId
    WHERE 
        a.PostTypeId = 2  
    GROUP BY 
        a.Id, a.Score, a.CreationDate
),
CommentStatistics AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        MAX(c.CreationDate) AS LatestCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Rank,
    COALESCE(av.Upvotes, 0) AS TotalUpvotes,
    COALESCE(av.Downvotes, 0) AS TotalDownvotes,
    cs.TotalComments,
    cs.LatestCommentDate,
    CASE 
        WHEN rp.BadgeId > 0 THEN 'Gold Badge Holder'
        ELSE 'No Badge'
    END AS UserBadgeStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    AnswersWithVotes av ON rp.PostId = av.AnswerId
LEFT JOIN 
    CommentStatistics cs ON rp.PostId = cs.PostId
WHERE 
    rp.Rank = 1 
    AND rp.ViewCount > (
        SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1
    )
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;