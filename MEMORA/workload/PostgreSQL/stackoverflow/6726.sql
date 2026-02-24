
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, OwnerDisplayName, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn = 1
    ORDER BY 
        Score DESC, CreationDate DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        COALESCE(h.Comment, 'No history') AS PostHistory
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistory h ON tp.PostId = h.PostId
    WHERE 
        h.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    Title,
    OwnerDisplayName,
    CreationDate,
    Score,
    CommentCount,
    UpVotes,
    DownVotes,
    STRING_AGG(PostHistory, ', ') AS RecentActions
FROM 
    PostStats
GROUP BY 
    Title, OwnerDisplayName, CreationDate, Score, CommentCount, UpVotes, DownVotes
ORDER BY 
    Score DESC, CreationDate DESC;
