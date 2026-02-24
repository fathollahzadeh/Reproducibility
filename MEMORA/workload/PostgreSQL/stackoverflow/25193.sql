
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 END) * 100.0 / NULLIF(COUNT(v.Id), 0), 0) AS UpvotePercentage,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '> <')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
), 
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpvotePercentage,
        Tags,
        ROW_NUMBER() OVER (ORDER BY UpvotePercentage DESC, ViewCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.OwnerDisplayName,
    pm.CommentCount,
    pm.ViewCount,
    pm.UpvotePercentage,
    pm.Tags,
    CASE 
        WHEN pm.UpvotePercentage >= 75 THEN 'Hot'
        WHEN pm.UpvotePercentage >= 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 10  
ORDER BY 
    pm.Rank;
