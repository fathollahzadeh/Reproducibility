
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        COALESCE(COUNT(DISTINCT b.Id), 0) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentCloseVotes AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        p.Title,
        ph.CreationDate,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '3 months'
    GROUP BY 
        ph.UserId, ph.PostId, p.Title, ph.CreationDate
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.AcceptedAnswers,
        us.BadgeCount,
        us.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStatistics us
    WHERE 
        us.Reputation > 0
),
MaxCloseVote AS (
    SELECT 
        UserId,
        MAX(CloseVoteCount) AS MaxVotes
    FROM 
        RecentCloseVotes
    GROUP BY 
        UserId
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.AcceptedAnswers,
    tu.BadgeCount,
    tu.TotalBounty,
    COALESCE(mc.MaxVotes, 0) AS MaxCloseVotesByUser,
    COUNT(rp.PostId) AS RecentPostsCount
FROM 
    TopUsers tu
LEFT JOIN MaxCloseVote mc ON tu.UserId = mc.UserId
LEFT JOIN RankedPosts rp ON rp.OwnerUserId = tu.UserId
WHERE 
    tu.UserRank <= 10 
GROUP BY 
    tu.DisplayName, 
    tu.Reputation, 
    tu.AcceptedAnswers, 
    tu.BadgeCount, 
    tu.TotalBounty, 
    mc.MaxVotes
ORDER BY 
    tu.Reputation DESC;
