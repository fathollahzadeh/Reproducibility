WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        MAX(PH.CreationDate) AS LastActionDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        PS.CloseCount,
        PS.ReopenCount,
        PS.DeleteUndeleteCount,
        ROW_NUMBER() OVER (ORDER BY P.LastActivityDate DESC) AS RecentRanking
    FROM 
        Posts P
    LEFT JOIN 
        RecentPostHistory PS ON P.Id = PS.PostId
    WHERE 
        P.Score > 0
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.CloseCount,
        PS.ReopenCount,
        PS.DeleteUndeleteCount,
        RANK() OVER (ORDER BY PS.CloseCount DESC, PS.ReopenCount ASC) AS CloseRank
    FROM 
        PostStats PS
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.LastAccessDate,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CloseCount,
    RP.ReopenCount,
    RP.DeleteUndeleteCount,
    UVC.TotalVotes,
    CASE 
        WHEN UVC.UpVotes > UVC.DownVotes THEN 'Positive'
        ELSE 'Negative'
    END AS VoteSentiment
FROM 
    Users U
JOIN 
    UserVoteCounts UVC ON U.Id = UVC.UserId
JOIN 
    RankedPosts RP ON RP.CloseRank <= 10
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY 
    U.Reputation DESC, 
    RP.CloseCount DESC;