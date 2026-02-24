WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    COALESCE(ps.Score, 0) AS PostScore,
    COALESCE(COUNT(DISTINCT c.Id), 0) AS TotalComments,
    MAX(pb.Date) AS LastBadgeDate
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 2
LEFT JOIN 
    Badges b ON b.UserId = (SELECT Id FROM Users WHERE DisplayName = tp.OwnerDisplayName ORDER BY CreationDate DESC LIMIT 1)
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
LEFT JOIN 
    Posts ps ON tp.PostId = ps.Id
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    (SELECT DISTINCT UserId, MAX(Date) AS Date FROM Badges GROUP BY UserId) pb ON b.UserId = pb.UserId
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount, ps.Score
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;