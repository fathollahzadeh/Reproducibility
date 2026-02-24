
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), TopPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        rp.Title,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
), PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), BadgedUsers AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), JoinedData AS (
    SELECT 
        tp.OwnerDisplayName,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.LastCommentDate, DATE '1970-01-01') AS LastCommentDate,
        bu.BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.Title = (SELECT Title FROM Posts WHERE Id = pc.PostId)
    LEFT JOIN 
        BadgedUsers bu ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bu.UserId)
)
SELECT 
    OwnerDisplayName,
    Title,
    Score,
    ViewCount,
    CommentCount,
    LastCommentDate,
    BadgeCount
FROM 
    JoinedData
WHERE 
    Score > 10
    AND ViewCount > 100
ORDER BY 
    Score DESC,
    CommentCount DESC;
