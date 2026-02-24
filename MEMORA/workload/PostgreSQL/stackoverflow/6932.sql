
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.Tags
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerName, 
        rp.CreationDate, 
        rp.Score, 
        rp.CommentCount, 
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTag <= 5
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.AnswerCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY tp.PostId), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY tp.PostId), 0) AS TotalDownVotes
FROM 
    TopPosts tp
LEFT JOIN Votes v ON tp.PostId = v.PostId
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
