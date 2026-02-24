WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, LastAccessDate, 
           (SELECT COUNT(*) FROM Badges WHERE UserId = Users.Id) AS BadgeCount,
           (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS PostCount,
           (SELECT COUNT(*) FROM Comments WHERE UserId = Users.Id) AS CommentCount
    FROM Users
    WHERE Reputation > 1000
),

PostStatistics AS (
    SELECT P.OwnerUserId,
           COUNT(P.Id) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(P.Score) AS TotalScore,
           SUM(P.ViewCount) AS TotalViews,
           AVG(P.Score) AS AvgScore,
           AVG(P.ViewCount) AS AvgViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),

FinalReport AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           Stats.TotalPosts,
           Stats.QuestionCount,
           Stats.AnswerCount,
           Stats.TotalScore,
           Stats.TotalViews,
           Stats.AvgScore,
           Stats.AvgViews,
           U.BadgeCount
    FROM UserReputation U
    LEFT JOIN PostStatistics Stats ON U.Id = Stats.OwnerUserId
)

SELECT * 
FROM FinalReport
ORDER BY Reputation DESC, TotalPosts DESC
LIMIT 100;
