
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND 
        p.PostTypeId IN (1, 2)  
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStatistics AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.CreationDate, 
        tp.Score, 
        tp.ViewCount, 
        tp.OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    ps.Title, 
    ps.CreationDate, 
    ps.Score, 
    ps.ViewCount, 
    ps.OwnerDisplayName, 
    ps.CommentCount, 
    ps.UpVotes, 
    ps.DownVotes
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;
