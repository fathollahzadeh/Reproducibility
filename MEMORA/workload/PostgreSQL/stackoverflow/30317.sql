WITH RECURSIVE UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(Badges.Id) AS BadgeCount,
        MAX(Badges.Class) AS HighestBadgeClass,
        STRING_AGG(Badges.Name, ', ') AS BadgeNames
    FROM Users
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    GROUP BY Users.Id
),
UserPosts AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        ub.BadgeNames,
        up.PostCount,
        up.QuestionCount,
        up.AnswerCount,
        up.AverageScore,
        u.CreationDate,
        u.LastAccessDate,
        CASE 
            WHEN u.Location IS NULL THEN 'Location not specified' 
            ELSE u.Location 
        END AS UserLocation
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN UserPosts up ON u.Id = up.OwnerUserId
),
MostActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.Reputation,
        ua.BadgeCount,
        ua.HighestBadgeClass,
        ua.BadgeNames,
        COALESCE(ua.PostCount, 0) AS TotalPosts,
        COALESCE(ua.QuestionCount, 0) AS TotalQuestions,
        COALESCE(ua.AnswerCount, 0) AS TotalAnswers,
        COALESCE(ua.AverageScore, 0) AS AveragePostScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ua.PostCount, 0) DESC) AS UserRank
    FROM UserActivity ua
)
SELECT 
    mu.UserId,
    mu.Reputation,
    mu.BadgeCount,
    mu.HighestBadgeClass,
    mu.BadgeNames,
    mu.TotalPosts,
    mu.TotalQuestions,
    mu.TotalAnswers,
    mu.AveragePostScore,
    CASE 
        WHEN mu.TotalAnswers > mu.TotalQuestions THEN 'More Answers than Questions' 
        ELSE 'More Questions than Answers' 
    END AS PostDominance,
    CASE 
        WHEN mu.Reputation > 1000 THEN 'High Reputation' 
        ELSE 'Moderate Reputation' 
    END AS ReputationStatus
FROM MostActiveUsers mu
WHERE mu.UserRank <= 10
ORDER BY mu.AveragePostScore DESC;

