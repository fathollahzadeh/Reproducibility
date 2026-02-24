
WITH UserPostCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.voteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.voteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        upc.PostCount AS UserPostCount,
        upc.UpvoteCount,
        upc.DownvoteCount
    FROM Posts p
    LEFT JOIN UserPostCounts upc ON p.OwnerUserId = upc.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.UserPostCount,
    ps.UpvoteCount,
    ps.DownvoteCount
FROM PostStats ps
WHERE ps.Score > 0
ORDER BY ps.CreationDate DESC
LIMIT 100;
