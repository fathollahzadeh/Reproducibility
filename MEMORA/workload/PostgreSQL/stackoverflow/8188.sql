
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerRank = 1
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate,
    (SELECT COUNT(DISTINCT pl.RelatedPostId)
     FROM PostLinks pl
     WHERE pl.PostId = tp.PostId) AS RelatedPostCount,
    (SELECT COUNT(DISTINCT v.Id)
     FROM Votes v
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(DISTINCT v.Id)
     FROM Votes v
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC
FETCH FIRST 10 ROWS ONLY;
