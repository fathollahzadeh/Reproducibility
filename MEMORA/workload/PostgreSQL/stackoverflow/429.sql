
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
), 
UserActivity AS (
    SELECT u.Id AS UserId,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    GROUP BY u.Id
), 
ClosedPosts AS (
    SELECT p.Id, p.Title, ph.UserDisplayName, ph.CreationDate AS ClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
          AND ph.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '12 months'
), 
TopUsers AS (
    SELECT ua.UserId, 
           RANK() OVER (ORDER BY ua.UpVotes - ua.DownVotes DESC) AS UserRank
    FROM UserActivity ua
    WHERE ua.UpVotes > 0
)

SELECT rp.Id AS RecentPostId, 
       rp.Title AS RecentPostTitle, 
       rp.CreationDate AS RecentPostCreationDate, 
       ua.UserId AS OwnerUserId, 
       ua.UpVotes AS OwnerUpVotes, 
       ua.DownVotes AS OwnerDownVotes, 
       ua.CommentCount AS OwnerCommentCount, 
       cp.ClosedDate AS PostClosedDate, 
       tu.UserRank
FROM RecentPosts rp
JOIN UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN ClosedPosts cp ON rp.Id = cp.Id
JOIN TopUsers tu ON ua.UserId = tu.UserId
WHERE rp.rn = 1 AND (ua.UpVotes > 10 OR ua.CommentCount > 5)
ORDER BY tu.UserRank, rp.CreationDate DESC
LIMIT 50;
