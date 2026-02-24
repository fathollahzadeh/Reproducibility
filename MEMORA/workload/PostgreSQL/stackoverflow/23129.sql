WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankPerType,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(MAX(v.BountyAmount) OVER (PARTITION BY p.Id), 0) AS MaxBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.MaxBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankPerType <= 10 
        AND rp.Score > (SELECT AVG(Score) FROM Posts) 
        AND (rp.MaxBounty > 0 OR rp.CommentCount >= 5)
)
SELECT 
    fp.PostID,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.MaxBounty,
    CASE 
        WHEN fp.Score IS NULL THEN 'No Votes'
        WHEN fp.MaxBounty > 0 THEN 'Bounty Available'
        WHEN fp.CommentCount > 5 THEN 'Highly Discussed'
        ELSE 'Normal'
    END AS PostCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostID = p.Id 
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
GROUP BY 
    fp.PostID, fp.Title, fp.CreationDate, fp.Score, fp.CommentCount, fp.MaxBounty
HAVING 
    SUM(fp.CommentCount) IS NOT NULL 
ORDER BY 
    fp.Score DESC, fp.CommentCount DESC;