
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        Score,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    tp.PostId, tp.Title, tp.Author, tp.CreationDate, tp.Score, tp.CommentCount, tp.VoteCount, pht.Name
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
