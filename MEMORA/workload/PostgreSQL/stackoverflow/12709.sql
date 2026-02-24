WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostCounts
    WHERE PostCount > 0
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AnswerCount,
    PostRank,
    ScoreRank
FROM TopUsers
WHERE PostRank <= 10 OR ScoreRank <= 10
ORDER BY PostRank, ScoreRank;