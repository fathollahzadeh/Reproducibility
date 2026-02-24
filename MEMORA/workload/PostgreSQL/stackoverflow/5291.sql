
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, OwnerDisplayName, CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 
)
SELECT 
    tr.OwnerDisplayName,
    COUNT(DISTINCT tr.PostId) AS TotalTopPosts,
    AVG(tr.Score) AS AverageScore,
    SUM(tr.CommentCount) AS TotalComments
FROM 
    TopRankedPosts tr
GROUP BY 
    tr.OwnerDisplayName
HAVING 
    COUNT(DISTINCT tr.PostId) > 1 
ORDER BY 
    TotalTopPosts DESC, AverageScore DESC
LIMIT 10;
