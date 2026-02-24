
WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        pu.PostCount,
        pu.QuestionCount,
        pu.AnswerCount,
        pu.TotalScore,
        CASE 
            WHEN pu.PostCount = 0 THEN 0
            ELSE pu.TotalScore / NULLIF(pu.PostCount, 0) 
        END AS AverageScore
    FROM RankedUsers u
    LEFT JOIN PostStats pu ON u.Id = pu.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.AverageScore,
    COALESCE(b.Class, 0) AS BadgeClass
FROM UserPostStats ups
LEFT JOIN (
    SELECT 
        UserId, 
        MAX(Class) AS Class 
    FROM Badges 
    GROUP BY UserId
) b ON ups.UserId = b.UserId
WHERE 
    ups.AverageScore IS NOT NULL 
    AND ups.AverageScore > 1.5
ORDER BY 
    ups.AverageScore DESC 
LIMIT 10;
