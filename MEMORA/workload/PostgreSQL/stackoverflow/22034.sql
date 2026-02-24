
WITH UserVoteSummary AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.Score,
           COALESCE(P.ViewCount, 0) AS ViewCount,
           COALESCE(P.AnswerCount, 0) AS AnswerCount,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           MAX(B.Date) AS LastBadgeDate,
           P.CreationDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CreationDate
),
OverallStatistics AS (
    SELECT U.UserId,
           U.DisplayName,
           U.UpVotes,
           U.DownVotes,
           SUM(PS.Score) AS TotalScore,
           SUM(PS.ViewCount) AS TotalViews,
           SUM(PS.AnswerCount) AS TotalAnswers,
           SUM(PS.CommentCount) AS TotalComments,
           COUNT(PS.PostId) AS TotalPosts
    FROM UserVoteSummary U
    LEFT JOIN PostStatistics PS ON U.UserId = PS.PostId
    GROUP BY U.UserId, U.DisplayName, U.UpVotes, U.DownVotes
)
SELECT O.DisplayName AS UserName,
       O.UpVotes,
       O.DownVotes,
       O.TotalScore,
       O.TotalViews,
       O.TotalAnswers,
       O.TotalComments,
       O.TotalPosts,
       CASE 
           WHEN O.TotalPosts = 0 THEN 'No Posts'
           WHEN O.TotalScore > 100 THEN 'Highly Active'
           ELSE 'Moderate Activity'
       END AS ActivityLevel,
       RANK() OVER (ORDER BY O.TotalScore DESC) AS ScoreRank
FROM OverallStatistics O
WHERE O.TotalViews IS NOT NULL AND O.TotalScore IS NOT NULL
ORDER BY O.TotalPosts DESC, O.TotalScore DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
