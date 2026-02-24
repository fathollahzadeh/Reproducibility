
WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 0 AS Level
    FROM Users
    WHERE Id IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = 1)

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id
    WHERE uh.Level < 5  
), 
PostVoteCounts AS (
    SELECT PostId,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT p.Id AS PostId, ph.CreationDate AS ClosedDate,
           ph.Comment AS CloseReason, ph.UserDisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
)
SELECT u.DisplayName AS UserName,
       u.Reputation,
       COUNT(DISTINCT p.Id) AS QuestionCount,
       COALESCE(SUM(pvc.UpVotes - pvc.DownVotes), 0) AS NetVotes,
       COUNT(DISTINCT cp.PostId) AS ClosedQuestions,
       COALESCE(MAX(cp.ClosedDate), NULL) AS LastClosedDate,
       STRING_AGG(DISTINCT cp.CloseReason, '; ') AS CloseReasons
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN PostVoteCounts pvc ON p.Id = pvc.PostId
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
WHERE u.Reputation > 1000
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT p.Id) > 5
ORDER BY NetVotes DESC, LastClosedDate DESC;
