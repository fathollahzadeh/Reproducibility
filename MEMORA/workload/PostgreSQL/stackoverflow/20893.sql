
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score >= 10
        AND p.PostTypeId IN (1, 2)  
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        rp.TotalBounty,
        CASE 
            WHEN rp.Score IS NULL THEN 'Unknown Score'
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1  
),
MostCommentedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY fp.CommentCount DESC) AS CommentRank
    FROM 
        FilteredPosts fp
),
TopBountyPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY fp.TotalBounty DESC) AS BountyRank
    FROM 
        FilteredPosts fp
)
SELECT 
    f.PostId,
    f.Title,
    f.CommentCount,
    mbp.CommentRank,
    tbp.BountyRank,
    f.ScoreCategory
FROM 
    FilteredPosts f
LEFT JOIN MostCommentedPosts mbp ON f.PostId = mbp.PostId
LEFT JOIN TopBountyPosts tbp ON f.PostId = tbp.PostId
WHERE 
    f.TotalBounty > 0
    OR (SELECT COUNT(*) FROM Votes v WHERE v.PostId = f.PostId AND v.VoteTypeId = 2) > 5  
ORDER BY 
    f.CommentCount DESC, 
    f.TotalBounty DESC
LIMIT 10;
