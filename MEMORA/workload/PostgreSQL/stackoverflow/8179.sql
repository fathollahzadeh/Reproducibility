WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR' 
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        AnswerCount, 
        CommentCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.Id), 0) AS TotalComments,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.Id AND v.VoteTypeId = 2), 0) AS TotalUpvotes,
    COALESCE((SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)), 0) AS TotalBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;