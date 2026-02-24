
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.PostId) AS VoteCount,
        COUNT(c.Id) AS CommentCountTotal
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, FavoriteCount, Rank, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.AnswerCount,
    t.CommentCount,
    t.FavoriteCount,
    t.OwnerDisplayName,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    COALESCE(AVG(u.Reputation), 0) AS AverageReputation
FROM 
    TopPosts t
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
GROUP BY 
    t.PostId, t.Title, t.CreationDate, t.Score, t.ViewCount, t.AnswerCount, t.CommentCount, t.FavoriteCount, t.OwnerDisplayName
ORDER BY 
    t.Score DESC;
