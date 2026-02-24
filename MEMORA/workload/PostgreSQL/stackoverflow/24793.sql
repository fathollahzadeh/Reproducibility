
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year') 
      AND ph.PostHistoryTypeId IN (10, 11, 12) 
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 6) AS EditTagCount,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM Posts p
    WHERE p.CreationDate BETWEEN (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 year') AND TIMESTAMP '2024-10-01 12:34:56'
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounty,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.EditTagCount,
    ps.CommentCount,
    ps.DownvoteCount,
    ps.UpvoteCount,
    CASE 
        WHEN rp.PostId IS NOT NULL THEN 'Post has recently changed state' 
        ELSE 'No recent changes' 
    END AS RecentChangeStatus
FROM UserActivity ua
JOIN PostStats ps ON ua.UserId = ps.PostId 
LEFT JOIN RecentPostHistory rp ON ps.PostId = rp.PostId AND rp.rn = 1
WHERE ua.TotalPosts > 5
  AND ua.TotalBounty > 0
  AND EXISTS (
      SELECT 1 
      FROM Badges b 
      WHERE b.UserId = ua.UserId AND b.Class = 1 
  )
ORDER BY ua.TotalBounty DESC, ua.TotalPosts DESC;
