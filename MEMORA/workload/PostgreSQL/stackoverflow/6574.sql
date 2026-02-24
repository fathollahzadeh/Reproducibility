
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        U.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, U.DisplayName, p.CreationDate, p.Score, p.ViewCount
), TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, CreationDate, Score, ViewCount, CommentCount, AnswerCount
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 5
)
SELECT 
    t.PostId, 
    t.Title, 
    t.OwnerDisplayName, 
    t.CreationDate, 
    t.Score, 
    t.ViewCount, 
    t.CommentCount, 
    t.AnswerCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts t
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON b.UserId = (SELECT Id FROM Users WHERE DisplayName = t.OwnerDisplayName LIMIT 1)
ORDER BY 
    t.Score DESC, 
    t.ViewCount DESC;
