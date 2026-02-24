
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        u.Reputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        pt.Name AS PostTypeName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation, pt.Name
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.OwnerName,
    fp.Reputation,
    fp.CommentCount,
    fp.AnswerCount,
    CASE 
        WHEN fp.Reputation > 1000 THEN 'High Reputation'
        WHEN fp.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    STRING_AGG(DISTINCT fp.PostTypeName, ', ') AS PostTypeNames
FROM 
    FilteredPosts fp
JOIN 
    PostHistory ph ON ph.PostId = fp.PostId
WHERE 
    ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    AND ph.PostHistoryTypeId IN (10, 11)  
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.OwnerName, fp.Reputation, fp.CommentCount, fp.AnswerCount
ORDER BY 
    fp.CreationDate DESC, fp.Reputation DESC;
