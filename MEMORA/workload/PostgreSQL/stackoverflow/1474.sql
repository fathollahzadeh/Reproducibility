
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalQuestions DESC) AS ActivityRank
    FROM UserActivity
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(ba.TotalBounty, 0) AS BountyCount,
        p.OwnerUserId  -- Added OwnerUserId to join with TopUsers
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS Count 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, SUM(BountyAmount) AS TotalBounty 
        FROM Votes 
        WHERE VoteTypeId = 8
        GROUP BY PostId
    ) ba ON p.Id = ba.PostId
    WHERE p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') 
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalBounty,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.BountyCount
FROM TopUsers u
LEFT JOIN RecentPosts rp ON u.UserId = rp.OwnerUserId
WHERE u.ActivityRank <= 10
ORDER BY u.TotalPosts DESC, rp.CreationDate DESC;
