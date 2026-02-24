
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.PostTypeName,
    COALESCE(comments.CommentCount, 0) AS TotalComments,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = r.PostId 
       AND v.VoteTypeId IN (2, 3)) AS TotalVotes, 
    (SELECT STRING_AGG(DISTINCT b.Name, ', ') 
     FROM Badges b 
     WHERE b.UserId = u.Id) AS UserBadges
FROM 
    RankedPosts r
LEFT JOIN 
    Users u ON r.PostId = u.Id 
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) comments ON r.PostId = comments.PostId
WHERE 
    r.RankByScore <= 5 
    AND u.Reputation IS NOT NULL
ORDER BY 
    CASE 
        WHEN r.PostTypeName = 'Question' THEN 1
        WHEN r.PostTypeName = 'Answer' THEN 2
        ELSE 3 
    END,
    r.Score DESC,
    r.CreationDate DESC;
