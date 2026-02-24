WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        PostCount, 
        QuestionCount, 
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount
    FROM UserPostCounts
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    tuc.PostCount,
    tuc.QuestionCount,
    tuc.AnswerCount
FROM TopUsers tuc
JOIN Users u ON u.Id = tuc.UserId
WHERE tuc.RankByPostCount <= 10
ORDER BY tuc.RankByPostCount;