
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId IN (1, 2) 
    GROUP BY
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM
        RankedPosts rp
    WHERE
        rp.ScoreRank <= 5 
)
SELECT
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount
FROM
    TopPosts tp
LEFT JOIN (
    SELECT 
        UserId, COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON tp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = b.UserId)
ORDER BY 
    tp.Score DESC;
