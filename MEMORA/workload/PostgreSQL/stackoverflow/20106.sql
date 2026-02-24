
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(V.Id) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS LatestVote
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
), 
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CASE WHEN PH.PostHistoryTypeId = 10 THEN CR.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON CAST(PH.Comment AS INTEGER) = CR.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)

SELECT 
    UVC.UserId,
    UVC.DisplayName,
    UVC.UpVotes,
    UVC.DownVotes,
    UVC.TotalVotes,
    PVS.PostId,
    PVS.Title,
    PVS.TotalUpVotes,
    PVS.TotalDownVotes,
    PVS.TotalVotes AS PostTotalVotes,
    CPR.CloseReasons
FROM 
    UserVoteCounts UVC
CROSS JOIN 
    PostVoteSummary PVS
LEFT JOIN 
    ClosedPostReasons CPR ON PVS.PostId = CPR.PostId
WHERE 
    UVC.TotalVotes > 5
    AND PVS.TotalUpVotes > PVS.TotalDownVotes
    AND (UVC.UpVotes IS NOT NULL OR UVC.DownVotes IS NOT NULL)
ORDER BY 
    UVC.VoteRank, PVS.TotalVotes DESC;
