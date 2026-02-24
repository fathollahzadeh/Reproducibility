WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPosts
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.PostTypeId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosed
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.PostId
),
AcceptedAnswerCount AS (
    SELECT 
        P.AcceptedAnswerId,
        COUNT(P.Id) AS AnswerCount
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY P.AcceptedAnswerId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UP.ReputationRank,
    P.Title,
    ST.UpVotes,
    ST.DownVotes,
    ST.CommentCount,
    ST.RelatedPosts,
    CASE 
        WHEN CP.FirstClosed IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(AAC.AnswerCount, 0) AS AcceptedAnswers,
    CASE 
        WHEN P.Body IS NULL THEN 'No Content'
        ELSE SUBSTRING(P.Body, 1, 200) || '...' 
    END AS PreviewBody,
    CAST(P.CreationDate AS DATE) AS PostCreationDate,
    CONCAT('https://example.com/posts/', P.Id) AS PostUrl
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
JOIN UserReputation UP ON U.Id = UP.UserId
JOIN PostStats ST ON P.Id = ST.PostId
LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
LEFT JOIN AcceptedAnswerCount AAC ON P.AcceptedAnswerId = AAC.AcceptedAnswerId
WHERE P.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR')
AND P.PostTypeId = 1
AND U.Reputation > 100
ORDER BY U.Reputation DESC, P.Title
LIMIT 100;