WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CreationDate, rp.CommentCount, rp.Upvotes, rp.Downvotes
),
PostSummary AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.Upvotes,
        p.Downvotes,
        CASE 
            WHEN p.BadgeCount > 0 THEN 'Has Badges'
            ELSE 'No Badges'
        END AS BadgeStatus
    FROM 
        PostWithBadges p
    WHERE 
        p.CommentCount > (SELECT AVG(CommentCount) FROM PostWithBadges)
)
SELECT 
    Title,
    Score,
    ViewCount,
    CommentCount,
    Upvotes,
    Downvotes,
    BadgeStatus
FROM 
    PostSummary
WHERE 
    Score > 10
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50
OFFSET 0;