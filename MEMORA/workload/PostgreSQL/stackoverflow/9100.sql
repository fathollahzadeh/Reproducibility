WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, UB.TotalBadges
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    ORDER BY U.Reputation DESC, UB.TotalBadges DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostStats AS (
    SELECT U.Id, U.DisplayName, PS.TotalPosts, PS.TotalQuestions, PS.TotalAnswers, PS.TotalViews
    FROM Users U
    JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE U.Id IN (SELECT Id FROM TopUsers)
)
SELECT U.DisplayName, U.Reputation, U.TotalBadges,
       UPS.TotalPosts, UPS.TotalQuestions, UPS.TotalAnswers, UPS.TotalViews
FROM UserBadges UB
JOIN UserPostStats UPS ON UB.UserId = UPS.Id
JOIN TopUsers U ON U.Id = UPS.Id
ORDER BY U.Reputation DESC;
