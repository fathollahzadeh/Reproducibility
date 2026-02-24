
WITH RECURSIVE UserHierarchy AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           0 AS Level
    FROM Users u
    WHERE u.Id = (SELECT MIN(Id) FROM Users) 

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           uh.Level + 1 AS Level
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id + 1
), 
PostsWithVotes AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.Title, 
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
           COUNT(v.Id) AS TotalVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.Title
),
UserPosts AS (
    SELECT u.Id AS UserId,
           u.DisplayName AS UserDisplayName, 
           COUNT(pw.PostId) AS PostCount, 
           SUM(pw.UpVotes - pw.DownVotes) AS VoteBalance,
           MAX(pw.TotalVotes) AS HighestVotes
    FROM Users u
    LEFT JOIN PostsWithVotes pw ON u.Id = pw.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentPostEdits AS (
    SELECT ph.PostId, ph.UserId, ph.CreationDate, 
           pt.Name AS HistoryTypeName, 
           ph.Comment, 
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 YEAR'
)
SELECT uh.DisplayName, 
       uh.Reputation, 
       uh.CreationDate, 
       COALESCE(up.PostCount, 0) AS TotalPosts, 
       COALESCE(up.VoteBalance, 0) AS CurrentVoteBalance,
       COALESCE(up.HighestVotes, 0) AS MaxVotes,
       COALESCE(rp.PostId, -1) AS LastEditedPostId, 
       COALESCE(rp.HistoryTypeName, 'No edits') AS LastEditType,
       COALESCE(rp.Comment, 'No description') AS LastEditComment
FROM UserHierarchy uh
LEFT JOIN UserPosts up ON uh.Id = up.UserId
LEFT JOIN RecentPostEdits rp ON uh.Id = rp.UserId AND rp.rn = 1
ORDER BY uh.Reputation DESC, up.PostCount DESC;
