
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.Score, 0) AS PostScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(p.Score, 0) DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, u.DisplayName
), 
FilteredPosts AS (
    SELECT 
        PostID, 
        Title, 
        OwnerDisplayName, 
        PostScore, 
        CommentCount, 
        VoteCount 
    FROM 
        RankedPosts 
    WHERE 
        RankByScore <= 10  
)

SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.PostScore,
    fp.CommentCount,
    fp.VoteCount,
    pt.Name AS PostType
FROM 
    FilteredPosts fp
JOIN 
    PostTypes pt ON fp.PostID IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
ORDER BY 
    fp.PostScore DESC, 
    fp.CommentCount DESC;
