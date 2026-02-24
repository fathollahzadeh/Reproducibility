
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS AnswerCount,
        AVG(EXTRACT(EPOCH FROM (P.LastActivityDate - P.CreationDate)) / 3600.0) AS AvgResponseTime
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    GROUP BY U.Id, U.DisplayName
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId
),

TopPosts AS (
    SELECT 
        PS.*,
        U.DisplayName AS TopUser,
        U.Reputation AS UserReputation,
        COALESCE(UE.UpVotesCount, 0) - COALESCE(UE.DownVotesCount, 0) AS UserScore
    FROM PostStatistics PS
    LEFT JOIN Users U ON PS.AcceptedAnswerId = U.Id
    LEFT JOIN UserEngagement UE ON U.Id = UE.UserId
    WHERE PS.PostRank <= 10
)

SELECT 
    TP.PostId,
    TP.Title,
    TP.CommentCount,
    TP.UpVoteCount,
    TP.DownVoteCount,
    TP.TopUser,
    TP.UserReputation,
    TP.UserScore,
    CASE 
        WHEN TP.UserScore > 5 THEN 'Highly Engaged'
        WHEN TP.UserScore BETWEEN 0 AND 5 THEN 'Moderately Engaged'
        ELSE 'Needs Improvement'
    END AS EngagementLevel
FROM TopPosts TP
ORDER BY TP.UserScore DESC, TP.CommentCount DESC;
