
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(V.Id) AS VoteCount, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U 
    LEFT JOIN Votes V ON U.Id = V.UserId 
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.AnswerCount, 
        P.CommentCount, 
        P.Tags,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        Posts P 
    LEFT JOIN Votes V ON P.Id = V.PostId 
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AnswerCount, P.CommentCount, P.Tags
),
RankedPosts AS (
    SELECT 
        PM.*, 
        RANK() OVER (ORDER BY PM.TotalUpVotes DESC, PM.ViewCount DESC) AS PostRank
    FROM 
        PostMetrics PM
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    RP.PostId, 
    RP.Title, 
    RP.ViewCount, 
    RP.AnswerCount, 
    RP.CommentCount, 
    RP.TotalUpVotes, 
    RP.TotalDownVotes, 
    RP.CloseCount,
    CASE 
        WHEN RP.TotalUpVotes > 0 THEN CAST(RP.TotalUpVotes AS FLOAT) / NULLIF(RP.TotalUpVotes + RP.TotalDownVotes, 0) 
        ELSE 0 
    END AS UpVoteRatio
FROM 
    UserVoteStats U
JOIN 
    RankedPosts RP ON RP.TotalUpVotes > 0
WHERE 
    RP.PostRank <= 10 OR (U.VoteCount > 5 AND RP.CloseCount = 0)
ORDER BY 
    U.VoteCount DESC, 
    UpVoteRatio DESC;
