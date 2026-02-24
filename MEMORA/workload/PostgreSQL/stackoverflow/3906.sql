
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)

SELECT 
    r.OwnerUserId,
    u.DisplayName,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = r.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = r.PostId AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = r.PostId AND ph.PostHistoryTypeId = 10) AS CloseVotes,
    CASE 
        WHEN r.Score > 10 THEN 'Highly Rated'
        WHEN r.Score BETWEEN 1 AND 10 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    RecentPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
WHERE 
    r.rn = 1
ORDER BY 
    r.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
