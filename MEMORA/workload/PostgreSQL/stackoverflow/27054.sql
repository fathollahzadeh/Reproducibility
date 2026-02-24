WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (
            PARTITION BY 
                CASE 
                    WHEN p.Score > 10 THEN 'High Score'
                    WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium Score'
                    ELSE 'Low Score'
                END 
            ORDER BY p.CreationDate DESC
        ) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        Score,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostTagMetrics AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.Score,
    ptm.Tags,
    fp.CreationDate
FROM 
    FilteredPosts fp
JOIN 
    PostTagMetrics ptm ON fp.Id = ptm.PostId
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;