
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        LEAD(u.Reputation) OVER (ORDER BY u.Reputation DESC) AS NextUserReputation,
        LAG(u.Reputation) OVER (ORDER BY u.Reputation) AS PrevUserReputation
    FROM Users u
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown Reputation'
            WHEN Reputation > 10000 THEN 'Elite User'
            WHEN Reputation BETWEEN 5000 AND 10000 THEN 'Experienced User'
            ELSE 'Novice User'
        END AS ReputationCategory,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.UserId) AS BadgeCount
    FROM UserReputation u
    WHERE Reputation IS NOT NULL
    ORDER BY Reputation DESC
    LIMIT 100
),
UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivities AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(up.PostCount, 0) AS PostCount,
        COALESCE(up.QuestionCount, 0) AS QuestionCount,
        COALESCE(up.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN COALESCE(up.QuestionCount, 0) = 0 THEN NULL
            ELSE COALESCE(up.AnswerCount, 0) / NULLIF(COALESCE(up.QuestionCount, 0), 0)
        END AS AnswerToQuestionRatio
    FROM Users u
    LEFT JOIN UserPosts up ON u.Id = up.OwnerUserId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(cr.Name) AS Reasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
PostsWithCloseReasons AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COALESCE(cr.Reasons, '{}') AS CloseReasons,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN CloseReasons cr ON p.Id = cr.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ta.ReputationCategory,
    ta.BadgeCount,
    COALESCE(pcr.PostCount, 0) AS TotalPosts,
    COALESCE(pcr.QuestionCount, 0) AS TotalQuestions,
    COALESCE(pcr.AnswerCount, 0) AS TotalAnswers,
    COALESCE(pcr.AnswerToQuestionRatio, 0) AS AnswerToQuestionRatio,
    p.Title AS RecentPostTitle,
    p.CloseReasons
FROM TopUsers ta
JOIN Users u ON u.Id = ta.UserId
LEFT JOIN UserActivities pcr ON u.Id = pcr.Id
LEFT JOIN (
    SELECT * FROM PostsWithCloseReasons WHERE RecentPostRank = 1
) p ON p.OwnerUserId = u.Id
WHERE u.Reputation IS NOT NULL
ORDER BY u.Reputation DESC
LIMIT 50;
