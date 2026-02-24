
WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostStatistics AS (
    SELECT p.OwnerUserId, 
           COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ClosedPosts AS (
    SELECT ph.UserId, 
           COUNT(*) AS ClosedCount,
           STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes c ON CAST(ph.Comment AS INT) = c.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.UserId
),
UserVoteStats AS (
    SELECT v.UserId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
)
SELECT ur.DisplayName, 
       ur.Reputation, 
       ps.TotalPosts,
       ps.QuestionCount,
       ps.AnswerCount,
       COALESCE(cp.ClosedCount, 0) AS ClosedCount,
       COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
       COALESCE(uvs.UpVotes, 0) AS UpVotes,
       COALESCE(uvs.DownVotes, 0) AS DownVotes
FROM UserReputation ur
LEFT JOIN PostStatistics ps ON ur.Id = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON ur.Id = cp.UserId
LEFT JOIN UserVoteStats uvs ON ur.Id = uvs.UserId
WHERE ur.Reputation > 1000
ORDER BY ur.Rank;
