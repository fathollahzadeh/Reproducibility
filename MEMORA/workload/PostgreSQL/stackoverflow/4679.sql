
WITH UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ps.QuestionCount, 0) AS Questions,
        COALESCE(ps.AnswerCount, 0) AS Answers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.TotalViews, 0) DESC) AS Rank
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UI.UserId,
    UI.DisplayName,
    UI.Reputation,
    UI.Questions,
    UI.Answers,
    UI.TotalScore,
    UI.TotalViews,
    UI.BadgeCount,
    CASE 
        WHEN UI.BadgeCount > 5 THEN 'Expert'
        WHEN UI.BadgeCount BETWEEN 3 AND 5 THEN 'Intermediate'
        ELSE 'Beginner' 
    END AS ExpertiseLevel,
    COALESCE(pht.Name, 'No Activity') AS LastPostType,
    UI.Rank
FROM UserInteractions UI
LEFT JOIN (
    SELECT 
        OwnerUserId,
        MAX(CreationDate) AS LastPostDate,
        MAX(CASE 
            WHEN PostTypeId = 1 THEN 'Question'
            WHEN PostTypeId = 2 THEN 'Answer'
            ELSE 'Other' 
        END) AS Name
    FROM Posts
    GROUP BY OwnerUserId
) pht ON UI.UserId = pht.OwnerUserId
ORDER BY UI.Rank;
