
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE u.Reputation > 1000 
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.TotalBounties,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score
FROM TopUsers tu
LEFT JOIN RankedPosts rp ON tu.UserId = rp.PostId 
WHERE rp.Rank = 1 
    AND rp.ViewCount IS NOT NULL
ORDER BY tu.Reputation DESC, rp.Score DESC;
