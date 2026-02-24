
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        NetVotes,
        CommentCount,
        RANK() OVER (ORDER BY NetVotes DESC, CommentCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.NetVotes,
    tp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    ROW_NUMBER() OVER (PARTITION BY tp.Rank ORDER BY tp.CreationDate DESC) AS RowInRank
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank, RowInRank;
