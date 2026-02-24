
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS AuthorRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        Score,
        ViewCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        AuthorRank <= 5
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(bc.BadgeCount, 0) AS TotalBadges
FROM 
    TopPosts tp
LEFT JOIN 
    BadgeCounts bc ON tp.Author = (SELECT DisplayName FROM Users WHERE Id = bc.UserId)
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC
LIMIT 100;
