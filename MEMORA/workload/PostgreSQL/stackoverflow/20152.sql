
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(V.Id) AS TotalVotesCount,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostId IS NOT NULL AND PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COUNT(DISTINCT PH.Id) AS EditHistoryCount,
        P.Score,
        CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS HasAcceptedAnswerFlag
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.Score, P.AcceptedAnswerId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPostsCreated,
        SUM(PM.CommentCount) AS TotalCommentsOnPosts,
        SUM(PM.CloseCount) AS TotalPostsClosed,
        SUM(PM.EditHistoryCount) AS TotalPostEdits,
        AVG(PM.Score) AS AvgPostScore,
        SUM(PM.HasAcceptedAnswerFlag) AS TotalAcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostMetrics PM ON PM.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UDS.UserId,
    UDS.DisplayName,
    UDS.TotalPostsCreated,
    UDS.TotalCommentsOnPosts,
    UDS.TotalPostsClosed,
    UDS.TotalPostEdits,
    UDS.AvgPostScore,
    UDS.TotalAcceptedAnswers,
    UVS.UpVotesCount,
    UVS.DownVotesCount,
    UVS.TotalVotesCount,
    UVS.VoteRank
FROM 
    UserPostStats UDS
JOIN 
    UserVoteStats UVS ON UDS.UserId = UVS.UserId
WHERE 
    UDS.TotalPostsCreated > 5
    AND UVS.TotalVotesCount > 10
ORDER BY 
    UDS.TotalPostsCreated DESC, 
    UVS.VoteRank ASC;
