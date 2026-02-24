WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    bs.BadgeCount
FROM 
    PostStats ps
LEFT JOIN 
    BadgeStats bs ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bs.UserId)
ORDER BY 
    ps.Score DESC;