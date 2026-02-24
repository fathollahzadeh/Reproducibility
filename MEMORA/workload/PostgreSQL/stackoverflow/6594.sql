WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, u.DisplayName AS OwnerDisplayName, 
           p.Score, p.ViewCount, p.AnswerCount, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 10
),
UserStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT us.DisplayName, us.TotalPosts, us.TotalAnswers, us.GoldBadges,
           ROW_NUMBER() OVER (ORDER BY us.TotalPosts DESC, us.TotalAnswers DESC) AS UserRank
    FROM UserStats us
    WHERE us.TotalPosts > 5
)
SELECT rp.Title, rp.CreationDate, rp.OwnerDisplayName, rp.Score, rp.ViewCount, rp.AnswerCount,
       tu.DisplayName AS TopUser, tu.TotalPosts, tu.TotalAnswers, tu.GoldBadges
FROM RankedPosts rp
JOIN TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
WHERE tu.UserRank <= 10
ORDER BY rp.CreationDate DESC, rp.Score DESC;
