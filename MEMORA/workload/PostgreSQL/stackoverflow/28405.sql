
WITH UserActivity AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(p.ViewCount) AS TotalViews,
           AVG(CASE WHEN v.BountyAmount IS NOT NULL THEN v.BountyAmount END) AS AvgBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT UserId,
           DisplayName,
           Reputation,
           TotalPosts,
           TotalQuestions,
           TotalAnswers,
           TotalViews,
           AvgBounty,
           RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews,
           RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation
    FROM UserActivity
)
SELECT UserId,
       DisplayName,
       Reputation,
       TotalPosts,
       TotalQuestions,
       TotalAnswers,
       TotalViews,
       AvgBounty,
       RankByViews,
       RankByReputation
FROM TopUsers
WHERE RankByViews <= 10 OR RankByReputation <= 10
ORDER BY RankByViews, RankByReputation;
