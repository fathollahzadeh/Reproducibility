WITH UserPostCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePostCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePostCount,
        SUM(P.ViewCount) AS TotalViewCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositiveScorePostCount,
        NegativeScorePostCount,
        TotalViewCount,
        RANK() OVER (ORDER BY TotalViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserPostCount
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    PositiveScorePostCount,
    NegativeScorePostCount,
    TotalViewCount,
    ViewRank,
    PostRank
FROM TopUsers
WHERE PostCount > 0
ORDER BY TotalViewCount DESC
LIMIT 10;