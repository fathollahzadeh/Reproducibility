
WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        1 AS Depth
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation + (COALESCE(SUM(V.BountyAmount), 0) / 10) AS Reputation,
        U.CreationDate,
        UR.Depth + 1
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    JOIN 
        UserReputation UR ON U.Id = UR.Id
    WHERE 
        UR.Depth < 3
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, UR.Depth
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(EXTRACT(EPOCH FROM (P.LastActivityDate - P.CreationDate))) AS AvgOpenDuration
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title
),

FinalStatistics AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.AnswerCount,
        PS.UpVoteCount - PS.DownVoteCount AS NetVoteCount,
        U.DisplayName,
        UR.Reputation AS UserReputation
    FROM 
        PostStatistics PS
    JOIN 
        Users U ON PS.PostId = U.Id
    LEFT JOIN 
        UserReputation UR ON U.Id = UR.Id
)

SELECT 
    F.Title,
    F.CommentCount,
    F.AnswerCount,
    F.NetVoteCount,
    F.UserReputation
FROM 
    FinalStatistics F
WHERE 
    F.UserReputation IS NOT NULL
ORDER BY 
    F.NetVoteCount DESC,
    F.AnswerCount DESC
FETCH FIRST 10 ROWS ONLY;
