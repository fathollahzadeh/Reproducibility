
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.LastActivityDate, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.LastActivityDate,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.AcceptedAnswer,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.LastActivityDate, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount, 
    tp.OwnerDisplayName, 
    tp.AcceptedAnswer, 
    tp.CommentCount, 
    tp.UpVotes, 
    tp.DownVotes,
    pt.Name AS PostType
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.AcceptedAnswer = pt.Id
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
