WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, CommentCount, VoteCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    t.PostId, 
    t.Title, 
    t.CreationDate, 
    t.Score, 
    t.ViewCount, 
    t.CommentCount, 
    t.VoteCount, 
    u.DisplayName AS OwnerDisplayName
FROM 
    TopPosts t
JOIN 
    Users u ON t.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = t.PostId) 
ORDER BY 
    t.Score DESC, t.ViewCount DESC;