
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT UserId 
    FROM UserReputation 
    WHERE ReputationRank <= 100
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
UserPostInteractions AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT rp.PostId) AS PostsInteractedWith,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.NetVotes) AS TotalNetVotes
    FROM Users u
    JOIN TopUsers tu ON u.Id = tu.UserId
    JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    upi.PostsInteractedWith,
    upi.TotalComments,
    upi.TotalNetVotes,
    COUNT(b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM Users u
JOIN UserPostInteractions upi ON u.Id = upi.UserId
LEFT JOIN Badges b ON u.Id = b.UserId
GROUP BY u.Id, u.DisplayName, u.Reputation, upi.PostsInteractedWith, upi.TotalComments, upi.TotalNetVotes
ORDER BY u.Reputation DESC,
         upi.TotalNetVotes DESC
LIMIT 50;
