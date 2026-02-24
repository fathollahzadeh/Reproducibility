WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
PostScoreRanked AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank,
        COALESCE(COUNT(C.CommentId), 0) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentId 
         FROM Comments
         GROUP BY PostId) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalPosts,
    U.AvgReputation,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ScoreRank,
    PS.TotalComments,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.CloseReasons, 'None') AS CloseReasons
FROM 
    UserVoteSummary U
JOIN 
    PostScoreRanked PS ON U.TotalPosts > 5
LEFT JOIN 
    ClosedPosts CP ON PS.PostId = CP.PostId
ORDER BY 
    U.TotalUpVotes DESC, PS.Score DESC
LIMIT 50;