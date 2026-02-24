
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS RankByVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.VoteCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByVotes <= 3 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.VoteCount,
    tp.CommentCount,
    COUNT(DISTINCT bh.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    TopPosts tp
LEFT JOIN 
    Badges bh ON bh.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.VoteCount, tp.CommentCount
ORDER BY 
    tp.VoteCount DESC, tp.CommentCount DESC;
