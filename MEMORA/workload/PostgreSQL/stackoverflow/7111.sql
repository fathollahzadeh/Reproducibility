
WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.CommentCount), 0) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.BadgeCount,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalComments,
        RANK() OVER (ORDER BY ub.BadgeCount DESC, ups.TotalScore DESC) AS Rank
    FROM UserBadgeCounts ub
    JOIN UserPostStats ups ON ub.UserId = ups.UserId
)
SELECT 
    Rank,
    DisplayName,
    PostCount,
    TotalScore,
    QuestionCount,
    AnswerCount,
    TotalComments,
    BadgeCount
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
