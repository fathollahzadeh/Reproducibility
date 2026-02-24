
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS Author, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
), TopRankedPosts AS (
    SELECT 
        PostId, 
        Title,
        Author,
        CreationDate,
        Score,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Author,
    trp.CreationDate,
    trp.Score,
    trp.CommentCount,
    trp.VoteCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    COALESCE(bt.Name, 'No Badge Type') AS BadgeType
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Badges b ON trp.Author = (SELECT DisplayName FROM Users WHERE Id = b.UserId) 
LEFT JOIN 
    (SELECT * FROM Badges WHERE Class = 1) bt ON b.UserId = bt.UserId
ORDER BY 
    trp.Score DESC;
