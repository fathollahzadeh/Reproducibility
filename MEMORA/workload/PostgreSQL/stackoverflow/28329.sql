
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY VoteCount DESC, CommentCount DESC) AS Rank
    FROM 
        RankedPosts
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.CommentCount,
    tp.VoteCount,
    ht.Name AS PostTypeName,
    pht.Name AS PostHistoryTypeName,
    (SELECT COUNT(DISTINCT b.UserId) 
     FROM Badges b 
     WHERE b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    PostTypes ht ON ht.Id = (SELECT PostTypeId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
