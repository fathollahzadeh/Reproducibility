
WITH RECURSIVE UserReputationCTE AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName,
           ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
PostsWithScores AS (
    SELECT P.Id, P.Title, P.OwnerUserId, P.Score, 
           COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.Score, P.AcceptedAnswerId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate,
           (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
           (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id AND PH.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')) AS EditCount
    FROM Posts P
    WHERE P.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '60 days')
)
SELECT U.DisplayName, U.Reputation, U.Rank,
       PP.Title, PP.CreationDate, PP.CommentCount, 
       PP.EditCount, PS.Score, 
       PS.UpVoteCount, PS.DownVoteCount,
       CASE 
           WHEN PS.AcceptedAnswerId > 0 THEN 'Accepted Answer'
           ELSE 'Not Accepted'
       END AS AnswerStatus
FROM UserReputationCTE U
LEFT JOIN PostsWithScores PS ON U.UserId = PS.OwnerUserId
LEFT JOIN RecentPosts PP ON PS.Id = PP.Id
WHERE U.Reputation > 100
ORDER BY U.Rank, PP.CreationDate DESC
LIMIT 10;
