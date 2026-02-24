WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(u.CreationDate) AS AccountCreated
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
    WHERE Reputation > 0
),
SelectedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AccountCreated
    FROM TopUsers
    WHERE ReputationRank <= 10
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(p.Score) AS TotalScore,
        MAX(p.LastActivityDate) AS LastActivePostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    su.DisplayName,
    su.Reputation,
    su.QuestionCount,
    su.AnswerCount,
    ps.PostCount,
    ps.AvgViewCount,
    ps.TotalScore,
    ps.LastActivePostDate,
    EXTRACT(YEAR FROM age(su.AccountCreated)) AS AccountAgeYears
FROM SelectedUsers su
JOIN PostStatistics ps ON su.UserId = ps.OwnerUserId
ORDER BY su.Reputation DESC;
