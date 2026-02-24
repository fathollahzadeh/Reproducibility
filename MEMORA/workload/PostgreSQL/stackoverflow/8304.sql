
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, U.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)

SELECT 
    tp.PostId, 
    tp.Title, 
    tp.ViewCount, 
    tp.CreationDate, 
    tp.OwnerDisplayName, 
    tp.CommentCount,
    tp.UpvoteCount, 
    tp.DownvoteCount,
    COALESCE(ROUND((tp.UpvoteCount * 1.0 / NULLIF(tp.UpvoteCount + tp.DownvoteCount, 0)) * 100, 2), 0) AS UpvotePercentage
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC;
