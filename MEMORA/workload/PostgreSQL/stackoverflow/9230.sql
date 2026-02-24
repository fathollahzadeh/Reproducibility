
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM
        UserStats
)
SELECT
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalScore,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalBadges,
    U.ScoreRank,
    U.PostRank
FROM
    TopUsers U
WHERE
    U.ScoreRank <= 10 OR U.PostRank <= 10
ORDER BY
    U.ScoreRank, U.PostRank;
