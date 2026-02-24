
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 3
),
TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    trp.OwnerDisplayName,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    COALESCE(tc.PostsCount, 0) AS TagPostCount,
    CASE 
        WHEN trp.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus,
    CASE 
        WHEN trp.Score IS NULL THEN 'No Score Yet' 
        WHEN trp.Score > 50 THEN 'High Score'
        WHEN trp.Score BETWEEN 1 AND 50 THEN 'Moderate Score'
        ELSE 'Negative Score'
    END AS ScoreCategory
FROM 
    TopRankedPosts trp
LEFT JOIN 
    TagCounts tc ON trp.Title ILIKE '%' || tc.TagName || '%'
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC
LIMIT 10;
