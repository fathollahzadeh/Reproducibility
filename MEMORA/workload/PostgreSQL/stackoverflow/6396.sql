WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerName,
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
        PostId, Title, Score, ViewCount, OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.Score, 
        tp.ViewCount, 
        tp.OwnerName, 
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerName
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.Score, 
    ps.ViewCount, 
    ps.OwnerName, 
    ps.CommentCount, 
    ps.UpVotes, 
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;