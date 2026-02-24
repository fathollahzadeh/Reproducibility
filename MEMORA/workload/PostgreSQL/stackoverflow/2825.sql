WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankByScore,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(rp.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Warm'
        ELSE 'Cold'
    END AS Temperature,
    ARRAY(SELECT DISTINCT t.TagName 
          FROM Tags t
          JOIN Posts p ON t.WikiPostId = p.Id
          WHERE p.Id = rp.PostId) AS RelatedTags
FROM 
    RankedPosts rp
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;