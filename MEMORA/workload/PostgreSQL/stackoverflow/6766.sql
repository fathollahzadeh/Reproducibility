
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN V.VoteTypeId = 1 THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        COUNT(P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        U.Reputation
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' 
    AND P.PostTypeId = 1
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerDisplayName,
        PD.Score,
        PD.CommentCount,
        PD.AnswerCount,
        US.TotalUpVotes,
        US.TotalDownVotes,
        US.TotalAcceptedAnswers,
        ROW_NUMBER() OVER (ORDER BY PD.Score DESC) AS PostRank
    FROM PostDetails PD
    JOIN UserScore US ON PD.OwnerDisplayName = US.DisplayName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.Score,
    RP.CommentCount,
    RP.AnswerCount,
    RP.TotalUpVotes,
    RP.TotalDownVotes,
    RP.TotalAcceptedAnswers,
    RP.PostRank
FROM RankedPosts RP
WHERE RP.PostRank <= 10
ORDER BY RP.Score DESC;
