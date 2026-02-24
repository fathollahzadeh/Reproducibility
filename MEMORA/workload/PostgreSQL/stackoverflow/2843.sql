WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        ScoreRank
    FROM UserPostStats
    WHERE ScoreRank <= 10
),
BadgesReceived AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
UserEngagement AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.PostCount,
        t.QuestionCount,
        t.AnswerCount,
        t.TotalScore,
        COALESCE(br.BadgeCount, 0) AS BadgeCount,
        COALESCE(br.BadgeNames, 'None') AS BadgeNames
    FROM TopUsers t
    LEFT JOIN BadgesReceived br ON t.UserId = br.UserId
)
SELECT 
    ue.DisplayName,
    ue.PostCount,
    ue.QuestionCount,
    ue.AnswerCount,
    ue.TotalScore,
    ue.BadgeCount,
    ue.BadgeNames,
    (SELECT COUNT(DISTINCT c.Id) 
     FROM Comments c 
     JOIN Posts p ON c.PostId = p.Id 
     WHERE p.OwnerUserId = ue.UserId) AS CommentCount,
    (SELECT COUNT(DISTINCT ph.Id) 
     FROM PostHistory ph 
     WHERE ph.UserId = ue.UserId AND ph.PostHistoryTypeId IN (10, 11, 12)) AS EditActivity
FROM UserEngagement ue
WHERE ue.TotalScore > 100
ORDER BY ue.TotalScore DESC;
