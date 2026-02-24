
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS OwnerName, 
        p.CreationDate, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.*, 
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank 
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.OwnerName, 
    tp.CreationDate, 
    tp.ViewCount, 
    tp.CommentCount, 
    tp.VoteCount 
FROM 
    TopPosts tp
WHERE 
    tp.ViewRank <= 10
ORDER BY 
    tp.Rank;
