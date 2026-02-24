WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(AVG(P.Score), 0) AS AverageScore,
        COALESCE(SUM(V.Id), 0) AS TotalVotes
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName
)

SELECT
    UserId,
    DisplayName,
    TotalPosts,
    AverageScore,
    TotalVotes
FROM
    UserPostStats
ORDER BY
    TotalPosts DESC, AverageScore DESC;