
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.*, 
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC, rp.CreationDate DESC) AS OverallRank
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Owner,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    tp.RecentPostRank,
    tp.OverallRank
FROM 
    TopPosts tp
WHERE 
    tp.RecentPostRank = 1 
ORDER BY 
    tp.OverallRank
FETCH FIRST 10 ROWS ONLY;
