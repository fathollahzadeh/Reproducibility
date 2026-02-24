
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.AcceptedAnswerId,
        rp.CommentCount,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Most Recent'
            WHEN rp.PostRank <= 5 THEN 'Top Recent'
            ELSE 'Other Posts'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 10
),
PostMetrics AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.AcceptedAnswerId,
        fp.CommentCount,
        fp.PostCategory,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        COUNT(v.Id) AS VoteCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId
    LEFT JOIN 
        Users u ON u.Id = fp.AcceptedAnswerId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1
    GROUP BY 
        fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.AcceptedAnswerId, 
        fp.CommentCount, fp.PostCategory, b.Name
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.CommentCount,
    pm.PostCategory,
    pm.UserBadge,
    pm.VoteCount,
    CASE 
        WHEN pm.Score IS NULL THEN 'No Score'
        WHEN pm.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus
FROM 
    PostMetrics pm
WHERE 
    (pm.UserBadge IS NOT NULL OR pm.VoteCount > 0)
ORDER BY 
    pm.CreationDate DESC
LIMIT 100 OFFSET 0;
