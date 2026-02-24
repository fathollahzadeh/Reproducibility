WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, CommentCount, UpVoteCount, DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    u.DisplayName AS OwnerDisplayName,
    ub.Reputation AS OwnerReputation
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Users ub ON p.OwnerUserId = ub.Id
WHERE 
    tp.UpVoteCount > tp.DownVoteCount
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;