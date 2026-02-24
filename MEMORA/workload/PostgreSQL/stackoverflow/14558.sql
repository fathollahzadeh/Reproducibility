
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AveragePostScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.AveragePostScore,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM
        UserPostStats ups
    JOIN
        Users u ON ups.UserId = u.Id
)

SELECT
    UserId,
    DisplayName,
    TotalPosts,
    AveragePostScore
FROM
    TopUsers
WHERE
    ReputationRank <= 10
ORDER BY
    ReputationRank;
