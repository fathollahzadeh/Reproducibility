
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBountyAmount,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownvote
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.Id AS UserId,
        ur.Reputation,
        ur.ReputationRank,
        COALESCE(SUM(CASE WHEN rp.HasUpvote = 1 THEN 1 ELSE 0 END), 0) AS UpvotedPosts,
        COALESCE(SUM(CASE WHEN rp.HasDownvote = 1 THEN 1 ELSE 0 END), 0) AS DownvotedPosts
    FROM UserReputation ur
    LEFT JOIN RecentPosts rp ON ur.Id = rp.OwnerUserId
    WHERE ur.Reputation > (SELECT AVG(Reputation) FROM Users)
    GROUP BY ur.Id, ur.Reputation, ur.ReputationRank
)
SELECT 
    tu.UserId,
    tu.Reputation,
    tu.ReputationRank,
    tu.UpvotedPosts,
    tu.DownvotedPosts
FROM TopUsers tu
WHERE tu.ReputationRank <= 10
ORDER BY tu.Reputation DESC;
