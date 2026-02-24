
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(*) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(PH.RevisionGUID, 'No Revision') AS LastRevision,
        COUNT(C) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT PH.PostHistoryTypeId) AS TotalHistoryTypes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, PH.RevisionGUID
),
TopUsers AS (
    SELECT 
        UserId,
        SUM(UpVotesCount) AS TotalUpVotes,
        SUM(DownVotesCount) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(UpVotesCount) DESC, SUM(DownVotesCount) ASC) AS VoteRank
    FROM 
        UserVoteSummary
    GROUP BY 
        UserId
)
SELECT 
    RPT.PostId,
    RPT.Title,
    RPT.CreationDate,
    RPT.LastRevision,
    RPT.CommentCount,
    RPT.TotalUpVotes,
    RPT.TotalDownVotes,
    U.DisplayName AS MostActiveUser,
    (CASE 
        WHEN U.Reputation IS NULL THEN 'Reputation Data Not Available'
        ELSE 'Reputation: ' || CAST(U.Reputation AS TEXT) 
    END) AS UserReputation
FROM 
    RecentPostStats RPT
LEFT JOIN 
    TopUsers TU ON RPT.TotalUpVotes >= 1
LEFT JOIN 
    Users U ON TU.UserId = U.Id
WHERE 
    RPT.CommentCount > 5
ORDER BY 
    RPT.TotalUpVotes DESC, RPT.CommentCount DESC
LIMIT 10;
