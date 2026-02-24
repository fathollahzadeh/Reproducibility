WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE ScoreRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    COUNT(DISTINCT u.Id) AS UniqueContributors,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = tp.PostId  
LEFT JOIN 
    Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId) 
LEFT JOIN 
    PostLinks pl ON pl.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.CommentCount, b.Name
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;