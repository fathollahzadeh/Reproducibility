
WITH UserBadges AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(B.Id) AS BadgeCount, 
           MAX(B.Date) AS LastBadgeDate 
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           BadgeCount, 
           LastBadgeDate 
    FROM UserBadges
    WHERE BadgeCount > 0
    ORDER BY BadgeCount DESC 
    LIMIT 10
),
PostStats AS (
    SELECT P.OwnerUserId, 
           COUNT(P.Id) AS PostCount, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
           SUM(COALESCE(P.ViewCount, 0)) AS TotalViews 
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserPostStats AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           PS.PostCount, 
           PS.QuestionCount, 
           PS.AnswerCount, 
           PS.TotalViews 
    FROM Users U 
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT U.UserId, 
       U.DisplayName, 
       U.BadgeCount, 
       U.LastBadgeDate, 
       UPS.PostCount, 
       UPS.QuestionCount, 
       UPS.AnswerCount, 
       UPS.TotalViews 
FROM TopUsers U 
LEFT JOIN UserPostStats UPS ON U.UserId = UPS.UserId
ORDER BY U.BadgeCount DESC, UPS.TotalViews DESC;
