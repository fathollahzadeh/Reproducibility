WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostRank <= 5 AND rp.PostId IN (SELECT DISTINCT PostId FROM Votes WHERE VoteTypeId IN (2, 3))
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.CreationDate, 
    tp.ViewCount, 
    tp.AnswerCount, 
    tp.CommentCount, 
    tp.PostTypeName,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(u.Reputation) AS AverageAuthorReputation
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
JOIN 
    Users u ON tp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.CreationDate, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.PostTypeName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;