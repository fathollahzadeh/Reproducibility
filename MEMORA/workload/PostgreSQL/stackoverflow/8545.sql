WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.CommentCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.Score,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostStats AS (
    SELECT 
        tp.PostId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    ps.TotalComments,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    tp.Author,
    (ps.TotalUpvotes - ps.TotalDownvotes) AS NetVotes
FROM 
    TopPosts tp
JOIN 
    PostStats ps ON tp.PostId = ps.PostId
ORDER BY 
    NetVotes DESC, tp.CreationDate DESC;