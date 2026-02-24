
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS VoteRank
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
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(MAX(PH.CreationDate), P.CreationDate) AS LastUpdateDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '6 months' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount
),
CombinedMetrics AS (
    SELECT 
        PM.PostId,
        PM.Title,
        PM.CreationDate,
        PM.Score,
        PM.ViewCount,
        PM.AnswerCount,
        PM.CommentCount,
        U.UserId,
        U.DisplayName AS UserDisplayName,
        U.UpVotes,
        U.DownVotes,
        U.TotalVotes,
        PM.LastUpdateDate
    FROM 
        PostMetrics PM
    JOIN 
        UserVoteStats U ON PM.PostId = (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId ORDER BY P.CreationDate DESC LIMIT 1)
    WHERE 
        U.TotalVotes > 0
)
SELECT 
    CM.*,
    CASE 
        WHEN CM.AnswerCount = 0 THEN 'No Answers'
        WHEN CM.AnswerCount > 0 AND CM.Score < 0 THEN 'Unpopular'
        ELSE 'Popular'
    END AS PostPopularity,
    (EXTRACT(EPOCH FROM CM.LastUpdateDate) - EXTRACT(EPOCH FROM CM.CreationDate)) / 60 AS MinutesSinceLastUpdate
FROM 
    CombinedMetrics CM
ORDER BY 
    CM.UpVotes DESC, CM.ViewCount DESC;
