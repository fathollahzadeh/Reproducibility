
WITH UserActivity AS (
    SELECT U.Id AS UserId, 
           U.DisplayName,
           COUNT(P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           MAX(P.CreationDate) AS LastPostDate,
           DENSE_RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, PostCount, QuestionCount, AnswerCount, LastPostDate
    FROM UserActivity
    WHERE UserRank <= 10
),
RecentComments AS (
    SELECT C.UserId, 
           COUNT(C.Id) AS CommentCount,
           MAX(C.CreationDate) AS LastCommentDate
    FROM Comments C
    WHERE C.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY C.UserId
),
UserDetails AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation,
           COALESCE(R.CommentCount, 0) AS RecentCommentCount,
           COALESCE(R.LastCommentDate, DATE '1970-01-01') AS LastCommentDate
    FROM Users U
    LEFT JOIN RecentComments R ON U.Id = R.UserId
),
FinalResults AS (
    SELECT T.DisplayName,
           T.PostCount,
           T.QuestionCount,
           T.AnswerCount,
           T.LastPostDate,
           UD.Reputation,
           UD.RecentCommentCount,
           CASE 
               WHEN T.LastPostDate > UD.LastCommentDate THEN 'Active'
               WHEN T.LastPostDate < UD.LastCommentDate THEN 'Commenting More'
               ELSE 'Equally Active'
           END AS ActivityStatus
    FROM TopUsers T
    JOIN UserDetails UD ON T.UserId = UD.UserId
)
SELECT *,
       CONCAT(DisplayName, ' has ', PostCount, ' posts (', QuestionCount, ' questions and ', AnswerCount, ' answers) | Status: ', ActivityStatus) AS Summary
FROM FinalResults
ORDER BY PostCount DESC, DisplayName;
