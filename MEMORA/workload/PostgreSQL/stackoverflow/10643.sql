WITH UserReputation AS (
    SELECT Id AS UserId, Reputation
    FROM Users
),
PostCounts AS (
    SELECT OwnerUserId AS UserId, COUNT(Id) AS TotalPosts
    FROM Posts
    GROUP BY OwnerUserId
),
VoteCounts AS (
    SELECT PostId, COUNT(Id) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
TopPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, pc.TotalPosts, uc.Reputation, COALESCE(vc.TotalVotes, 0) AS TotalVotes
    FROM Posts p
    JOIN PostCounts pc ON p.OwnerUserId = pc.UserId
    JOIN UserReputation uc ON p.OwnerUserId = uc.UserId
    LEFT JOIN VoteCounts vc ON p.Id = vc.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' 
    ORDER BY TotalVotes DESC, p.CreationDate DESC
    LIMIT 100
)
SELECT *
FROM TopPosts;