
WITH RankedQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
             p.Id AS PostId,
             t.TagName
         FROM 
             Posts p
         JOIN 
             Tags t ON t.ExcerptPostId = p.Id
        ) t ON t.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.ViewCount, u.DisplayName
)

SELECT 
    PostId,
    Title,
    ViewCount,
    OwnerDisplayName,
    Tags
FROM 
    RankedQuestions
WHERE 
    Rank <= 10;
