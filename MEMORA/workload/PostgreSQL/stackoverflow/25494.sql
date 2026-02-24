
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
ScoredPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.TagsList,
        r.CommentCount,
        r.VoteCount,
        CASE 
            WHEN r.ViewCount > 1000 THEN 'High'
            WHEN r.ViewCount BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ViewCategory,
        CASE 
            WHEN r.Score > 50 THEN 'High'
            WHEN r.Score BETWEEN 10 AND 50 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory,
        r.rn
    FROM 
        RankedPosts r
    WHERE 
        r.rn = 1
)
SELECT 
    sp.PostId,
    sp.Title,
    sp.Body,
    sp.CreationDate,
    sp.ViewCount,
    sp.Score,
    sp.TagsList,
    sp.CommentCount,
    sp.VoteCount,
    sp.ViewCategory,
    sp.ScoreCategory
FROM 
    ScoredPosts sp
WHERE 
    sp.ViewCategory = 'High' AND 
    sp.ScoreCategory = 'High'
ORDER BY 
    sp.CreationDate DESC
LIMIT 10;
