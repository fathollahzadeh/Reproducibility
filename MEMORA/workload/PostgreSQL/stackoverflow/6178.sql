
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 5
)
SELECT 
    t.OwnerDisplayName,
    COUNT(t.PostId) AS TotalPosts,
    SUM(t.ViewCount) AS TotalViewCount,
    AVG(t.Score) AS AverageScore,
    AVG(t.CommentCount) AS AverageCommentCount
FROM 
    TopPosts t
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC;
