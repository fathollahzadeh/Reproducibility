
WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM UserPostStats
    WHERE TotalPosts > 0
),

RecentVotes AS (
    SELECT
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY V.UserId
)

SELECT
    TU.DisplayName,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    COALESCE(RV.UpVotes, 0) AS MonthlyUpVotes,
    COALESCE(RV.DownVotes, 0) AS MonthlyDownVotes,
    (COALESCE(RV.UpVotes, 0) - COALESCE(RV.DownVotes, 0)) AS NetVotes,
    CASE
        WHEN TU.QuestionCount > 0 THEN 'Active Contributor'
        ELSE 'Observer'
    END AS UserStatus
FROM TopUsers TU
LEFT JOIN RecentVotes RV ON TU.UserId = RV.UserId
WHERE TU.Rank <= 10
ORDER BY TU.TotalPosts DESC;
