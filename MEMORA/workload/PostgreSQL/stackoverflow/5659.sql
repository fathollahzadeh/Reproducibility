
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(H.Id) FROM PostHistory H WHERE H.PostId = P.Id AND H.PostHistoryTypeId IN (10, 11)) AS ClosureCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id 
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        MAX(B.Class) AS HighestBadgeClass
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.QuestionCount,
    U.AnswerCount,
    U.UpVotes,
    U.DownVotes,
    COALESCE(BS.BadgeNames, 'No Badges') AS BadgeNames,
    BS.HighestBadgeClass,
    PA.Title AS RecentPostTitle,
    PA.CreationDate AS RecentPostDate,
    PA.ViewCount AS RecentPostViews,
    PA.Score AS RecentPostScore,
    PA.CommentCount AS RecentPostComments,
    PA.ClosureCount AS RecentPostClosureCount
FROM UserStats U
LEFT JOIN PostActivity PA ON U.QuestionCount > 0
LEFT JOIN BadgeSummary BS ON U.UserId = BS.UserId
ORDER BY U.Reputation DESC, U.QuestionCount DESC, U.UpVotes DESC
LIMIT 100;
