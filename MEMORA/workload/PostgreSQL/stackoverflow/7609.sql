WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
BadgeStats AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount, 
        MAX(B.Class) AS HighestBadgeClass
    FROM Badges B
    GROUP BY B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        MAX(P.Score) AS MaxPostScore,
        AVG(P.ViewCount) AS AvgPostViews
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.HighestBadgeClass, 0) AS HighestBadgeClass,
    COALESCE(PS.CommentCount, 0) AS CommentCount,
    COALESCE(PS.MaxPostScore, 0) AS MaxPostScore,
    COALESCE(PS.AvgPostViews, 0) AS AvgPostViews
FROM UserStats US
JOIN Users U ON U.Id = US.UserId
LEFT JOIN BadgeStats BS ON U.Id = BS.UserId
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, US.PostCount DESC
LIMIT 50;
