WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.AnswerCount,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.OwnerDisplayName,
    t.Score,
    t.AnswerCount,
    t.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON t.PostId = c.PostId
LEFT JOIN 
    Votes v ON t.PostId = v.PostId
GROUP BY 
    t.PostId, t.Title, t.CreationDate, t.OwnerDisplayName, t.Score, t.AnswerCount, t.ViewCount
ORDER BY 
    t.Score DESC, t.ViewCount DESC;