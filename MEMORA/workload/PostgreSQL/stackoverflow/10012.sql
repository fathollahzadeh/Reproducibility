
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TagDetails AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        p.Id AS PostId
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%') 
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.VoteCount,
    pd.AnswerCount,
    STRING_AGG(td.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    TagDetails td ON pd.PostId = td.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.ViewCount, pd.Score, pd.OwnerDisplayName, pd.CommentCount, pd.VoteCount, pd.AnswerCount
ORDER BY 
    pd.ViewCount DESC;
