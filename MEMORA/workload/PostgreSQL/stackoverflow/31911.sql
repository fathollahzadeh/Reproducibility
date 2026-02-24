WITH RECURSIVE UserReputation as (
    SELECT Id, Reputation 
    FROM Users 
    WHERE Reputation > 0
    UNION ALL
    SELECT u.Id, u.Reputation + ur.Reputation 
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id + 1
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.Reputation > 1000
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.TotalComments,
        ps.AverageBounty,
        tu.DisplayName AS TopUser
    FROM PostStatistics ps
    LEFT JOIN TopUsers tu ON ps.OwnerUserId = tu.UserId
    WHERE ps.TotalComments > 5 or ps.AverageBounty IS NOT NULL
)
SELECT 
    fp.PostId,
    fp.OwnerUserId,
    fp.TotalComments,
    fp.AverageBounty,
    fp.TopUser,
    COALESCE(fp.TopUser, 'No Top User') AS User_Status,
    CASE 
        WHEN fp.AverageBounty IS NOT NULL THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS Bounty_Status
FROM FilteredPosts fp
ORDER BY fp.TotalComments DESC, fp.AverageBounty DESC
LIMIT 20;
