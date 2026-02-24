WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
UserPostLinkStats AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedPostCount
    FROM PostLinks PL
    GROUP BY PL.PostId
)
SELECT 
    UR.DisplayName,
    COALESCE(UP.TotalPosts, 0) AS TotalPosts,
    COALESCE(UP.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(UP.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(UP.TotalViews, 0) AS TotalViews,
    COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(UPL.RelatedPostCount, 0) AS PostLinkedCount,
    UR.ReputationRank,
    CASE 
        WHEN UR.Reputation >= 1000 THEN 'High Reputation'
        WHEN UR.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserReputation UR
LEFT JOIN PostStats UP ON UR.UserId = UP.OwnerUserId
LEFT JOIN UserBadges UB ON UR.UserId = UB.UserId
LEFT JOIN UserPostLinkStats UPL ON UP.TotalPosts > 0 AND UPL.PostId = UP.OwnerUserId
WHERE UR.Reputation > 0
ORDER BY UR.Reputation DESC;
