WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        u.DisplayName AS OwnerName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
),
TopPosts AS (
    SELECT PostId, Title, ViewCount, OwnerName
    FROM RankedPosts
    WHERE Rank <= 3
),
PostComments AS (
    SELECT 
        pc.Id AS CommentId, 
        pc.PostId, 
        pc.Text AS CommentText, 
        pc.CreationDate AS CommentDate, 
        COUNT(v.Id) AS VoteCount
    FROM Comments pc
    LEFT JOIN Votes v ON pc.PostId = v.PostId AND v.VoteTypeId = 2 
    GROUP BY pc.Id, pc.PostId, pc.Text, pc.CreationDate
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.OwnerName,
    COUNT(pc.CommentId) AS TotalComments,
    COALESCE(SUM(pc.VoteCount), 0) AS TotalUpvotes,
    CASE 
        WHEN SUM(pc.VoteCount) IS NULL THEN 'No Votes'
        ELSE 'Has Votes'
    END AS VoteStatus,
    (SELECT COUNT(*) FROM Posts p WHERE p.AcceptedAnswerId = tp.PostId) AS AnswersCount
FROM TopPosts tp
LEFT JOIN PostComments pc ON tp.PostId = pc.PostId
GROUP BY tp.PostId, tp.Title, tp.ViewCount, tp.OwnerName
ORDER BY tp.ViewCount DESC
LIMIT 5;