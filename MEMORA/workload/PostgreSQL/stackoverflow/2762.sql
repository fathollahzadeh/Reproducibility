
WITH UserReputation AS (
    SELECT Id AS UserId, 
           Reputation, 
           CreationDate, 
           LastAccessDate, 
           DisplayName, 
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.ViewCount, 
           p.Score, 
           p.OwnerUserId,
           COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostVoteSummary AS (
    SELECT v.PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    GROUP BY v.PostId
),
ClosedPosts AS (
    SELECT p.Id AS ClosedPostId, 
           ph.UserId AS CloserUserId, 
           ph.CreationDate AS ClosedDate, 
           ph.Comment,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT u.DisplayName, 
       u.Reputation, 
       COUNT(DISTINCT rp.PostId) AS RecentPostCount,
       SUM(ps.Upvotes) - SUM(ps.Downvotes) AS NetVotes,
       STRING_AGG(DISTINCT cp.Comment, '; ') AS CloseComments,
       STRING_AGG(DISTINCT COALESCE(CAST(cp.ClosedPostId AS TEXT), 'N/A'), ', ') AS ClosedPostIds,
       SUM(CASE WHEN rp.RecentPostRank = 1 THEN 1 ELSE 0 END) AS MostRecentPostExists
FROM UserReputation u
LEFT JOIN RecentPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.ClosedPostId AND cp.ClosureRank = 1
WHERE u.Reputation > 1000
GROUP BY u.DisplayName, u.Reputation
ORDER BY u.Reputation DESC;
