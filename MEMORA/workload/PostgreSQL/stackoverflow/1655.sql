WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentTotal,
        COUNT(DISTINCT v.UserId) AS UniqueVoters
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentTotal,
        rp.UniqueVoters
    FROM RankedPosts rp
    WHERE rp.rn = 1 
),
TopPosts AS (
    SELECT 
        fp.*,
        (fp.ViewCount * 1.0 / NULLIF(fp.CommentTotal, 0)) AS ViewToCommentRatio
    FROM FilteredPosts fp
    WHERE fp.CommentTotal > 5 
)
SELECT 
    t.Id,
    t.Title,
    t.ViewCount,
    t.CommentTotal,
    t.UniqueVoters,
    t.ViewToCommentRatio,
    CASE 
        WHEN t.ViewToCommentRatio > 10 THEN 'High Engagement'
        WHEN t.ViewToCommentRatio >= 5 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM TopPosts t
WHERE t.UniqueVoters > 3
ORDER BY t.ViewToCommentRatio DESC
LIMIT 50;