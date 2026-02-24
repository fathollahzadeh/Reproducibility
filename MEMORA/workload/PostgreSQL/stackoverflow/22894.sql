WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
        AND NOT EXISTS (
            SELECT 1 
            FROM Votes v
            WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3
        )
        AND (rp.Score > 100 OR rp.ViewCount > 1000)
),
CommentsInfo AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerDisplayName,
    ci.CommentCount,
    COALESCE(ci.AvgCommentScore, 0) AS AvgCommentScore,
    pt.Name AS PostType,
    COALESCE(bt.Name, 'No Badge') AS Badge,
    CASE 
        WHEN fp.ViewCount > 5000 THEN 'Highly Viewed'
        WHEN fp.ViewCount BETWEEN 1000 AND 5000 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges bt ON bt.UserId = p.OwnerUserId AND bt.Class = 1
LEFT JOIN 
    CommentsInfo ci ON ci.PostId = fp.PostId
WHERE 
    fp.Score >= 50
    OR (fp.Score < 50 AND fp.ViewCount > 2000)
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;