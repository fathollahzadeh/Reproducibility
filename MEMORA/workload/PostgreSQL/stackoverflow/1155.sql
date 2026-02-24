WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount 
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT OwnerUserId,
           COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(ViewCount) AS TotalViews,
           SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
ClosedPosts AS (
    SELECT PH.PostId, PH.UserId, PH.CreationDate, PH.Comment,
           P.Title, P.CreationDate AS PostCreationDate
    FROM PostHistory PH
    INNER JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10 
)
SELECT U.DisplayName,
       COALESCE(UB.BadgeCount, 0) AS BadgeCount,
       COALESCE(PS.QuestionCount, 0) AS QuestionCount,
       COALESCE(PS.AnswerCount, 0) AS AnswerCount,
       COALESCE(PS.TotalViews, 0) AS TotalViews,
       COALESCE(PS.TotalScore, 0) AS TotalScore,
       COUNT(DISTINCT CP.PostId) AS ClosedPostCount,
       STRING_AGG(CP.Title, ', ') AS ClosedPostTitles
FROM Users U
LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN ClosedPosts CP ON U.Id = CP.UserId
WHERE U.Reputation > 1000 
GROUP BY U.Id, U.DisplayName, UB.BadgeCount, PS.QuestionCount, PS.AnswerCount, PS.TotalViews, PS.TotalScore
HAVING COUNT(DISTINCT CP.PostId) > 0
ORDER BY BadgeCount DESC, TotalScore DESC;