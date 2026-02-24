
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 5
)
SELECT 
    tp.OwnerDisplayName,
    COUNT(DISTINCT tp.Id) AS TotalPosts,
    SUM(tp.Score) AS TotalScore,
    AVG(tp.ViewCount) AS AverageViewCount,
    AVG(tp.CommentCount) AS AverageCommentCount,
    AVG(tp.AnswerCount) AS AverageAnswerCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
GROUP BY 
    tp.OwnerDisplayName
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
