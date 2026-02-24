
WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        UserActivity
)
SELECT
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    CASE
        WHEN tu.TotalPosts > 0 THEN ROUND((CAST(tu.UpVotes AS FLOAT) / NULLIF((tu.UpVotes + tu.DownVotes), 0)) * 100, 2) 
        ELSE NULL END AS UpvotePercentage
FROM
    TopUsers tu
WHERE
    tu.ReputationRank <= 10
ORDER BY
    tu.Reputation DESC;
