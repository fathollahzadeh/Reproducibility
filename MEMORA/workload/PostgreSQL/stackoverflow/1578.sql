
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0)::text, '0') || ' comments' AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.rn = 1 THEN 'Most Popular'
            ELSE 'Other'
        END AS Popularity
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.Popularity,
    CASE 
        WHEN tp.Upvotes > tp.Downvotes THEN 'Positive'
        WHEN tp.Upvotes < tp.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tp.OwnerUserId AND b.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tp.OwnerUserId AND b.Class = 2) AS SilverBadges
FROM 
    TopPosts tp
LEFT JOIN 
    VoteTypes vt ON vt.Id IN (SELECT DISTINCT VoteTypeId FROM Votes v WHERE v.PostId = tp.PostId)
WHERE 
    tp.ViewCount > 100 
ORDER BY 
    tp.ViewCount DESC, tp.Upvotes DESC
LIMIT 10;
