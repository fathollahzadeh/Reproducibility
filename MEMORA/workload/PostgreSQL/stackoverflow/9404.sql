
WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATE '2022-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate, p.LastActivityDate
),
TopPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.LastActivityDate,
        pa.CommentCount,
        pa.VoteCount,
        pa.UpVoteCount,
        pa.DownVoteCount,
        RANK() OVER (ORDER BY pa.VoteCount DESC, pa.CommentCount DESC) AS Rank
    FROM PostActivity pa
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.CommentCount,
    tp.VoteCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    pt.Name AS PostTypeName,
    COUNT(b.Id) AS BadgeCount
FROM TopPosts tp
JOIN PostTypes pt ON tp.PostId = pt.Id
LEFT JOIN Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE tp.Rank <= 10
GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.LastActivityDate, tp.CommentCount, tp.VoteCount, tp.UpVoteCount, tp.DownVoteCount, pt.Name
ORDER BY tp.VoteCount DESC, tp.CommentCount DESC;
