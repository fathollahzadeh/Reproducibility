WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(C) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.AcceptedAnswerId
),
HighReputationUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users)
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CAST(CR.Name AS VARCHAR), ', ') AS Reasons,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    UDS.UserId,
    UDS.DisplayName AS UserName,
    UDS.Reputation,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CommentCount,
    PS.UpVotes - PS.DownVotes AS NetVotes,
    CR.Reasons AS ClosingReasons,
    PS.Rank
FROM 
    UserVoteSummary UDS
LEFT JOIN 
    PostStatistics PS ON UDS.UserId = PS.AcceptedAnswerId
LEFT JOIN 
    ClosedPostReasons CR ON PS.PostId = CR.PostId
WHERE 
    UDS.Reputation > 1000
    AND PS.CommentCount IS NOT NULL
ORDER BY 
    UDS.Reputation DESC, 
    PS.Rank ASC
LIMIT 100;