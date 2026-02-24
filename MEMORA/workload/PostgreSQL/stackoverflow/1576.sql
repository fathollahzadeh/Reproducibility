WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users U 
    LEFT JOIN 
        Votes V ON U.Id = V.UserId 
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 11) AS ReopenCount
    FROM 
        Posts P 
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CloseCount,
        PS.ReopenCount,
        ROW_NUMBER() OVER (ORDER BY PS.CloseCount DESC, PS.ReopenCount ASC) AS PostRank 
    FROM 
        ClosedPostStats PS
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    RP.Title,
    RP.PostRank,
    CASE 
        WHEN RP.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    UserVoteCounts U
INNER JOIN 
    RankedPosts RP ON U.UserId = RP.PostId
WHERE 
    U.TotalVotes > 5
ORDER BY 
    U.TotalVotes DESC, RP.PostRank;