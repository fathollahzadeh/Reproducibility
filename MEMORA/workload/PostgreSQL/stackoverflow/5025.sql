
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tagArray ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagArray
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    up.DisplayName AS User,
    COUNT(DISTINCT ph.Id) AS EditsCount,
    COUNT(DISTINCT c.Id) AS CommentsCount,
    MAX(tp.CreationDate) AS LatestPostDate,
    AVG(tp.Score) AS AverageScore,
    STRING_AGG(DISTINCT tp.Tags, ', ') AS AllTags
FROM 
    Users up
JOIN 
    Posts p ON p.OwnerUserId = up.Id
JOIN 
    TopPosts tp ON tp.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
GROUP BY 
    up.DisplayName
ORDER BY 
    AverageScore DESC
LIMIT 10;
