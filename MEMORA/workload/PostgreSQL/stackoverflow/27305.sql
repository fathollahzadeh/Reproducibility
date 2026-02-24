
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        r.Name AS Rating,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS ScoreAdjustment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 1
    LEFT JOIN 
        PostHistoryTypes r ON ph.PostHistoryTypeId = r.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, r.Name
)

SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.Author,
    p.AnswerCount,
    p.CommentCount,
    p.Rating,
    p.ScoreAdjustment,
    STRING_AGG(tag.TagName, ', ') AS Tags
FROM 
    RankedPosts p
LEFT JOIN 
    (SELECT 
         PostId,
         STRING_AGG(TagName, ', ') AS TagName
     FROM 
         Tags t
     JOIN 
         Posts p ON t.WikiPostId = p.Id
     GROUP BY 
         PostId) tag ON p.PostId = tag.PostId
WHERE 
    p.ScoreAdjustment > 0
GROUP BY 
    p.PostId, p.Title, p.Body, p.CreationDate, p.Author, p.AnswerCount, p.CommentCount, p.Rating, p.ScoreAdjustment
ORDER BY 
    p.ScoreAdjustment DESC, p.CreationDate DESC
LIMIT 10;
