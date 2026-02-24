
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (
            PARTITION BY p.OwnerUserId 
            ORDER BY p.Score DESC, p.ViewCount DESC
        ) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.LastActivityDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        CreationDate, 
        LastActivityDate, 
        CommentCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate,
    DENSE_RANK() OVER (ORDER BY tp.ViewCount DESC) AS ViewRank,
    DENSE_RANK() OVER (ORDER BY tp.Score DESC) AS ScoreRank,
    STRING_AGG(c.UserDisplayName, ', ') AS CommentAuthors
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
GROUP BY
    tp.OwnerDisplayName,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
