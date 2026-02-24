WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AverageCommentScore,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.Id = c.PostId
LEFT JOIN 
    Votes v ON tp.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
GROUP BY 
    tp.OwnerDisplayName
ORDER BY 
    TotalBounty DESC, AverageCommentScore DESC;