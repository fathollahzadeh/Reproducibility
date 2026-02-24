
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Author, 
        CommentCount, 
        VoteCount, 
        PostType
    FROM 
        RankedPosts
    WHERE 
        rn = 1
)
SELECT 
    tp.Author,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.VoteCount,
    tp.PostType
FROM 
    TopPosts tp
ORDER BY 
    tp.VoteCount DESC, 
    tp.CreationDate DESC
LIMIT 10;
