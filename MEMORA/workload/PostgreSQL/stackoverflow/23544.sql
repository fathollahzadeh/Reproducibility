
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY P.OwnerUserId) AS TotalPosts,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
UserVoteSummary AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        P.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 MONTH' AND TIMESTAMP '2024-10-01 12:34:56'
    GROUP BY 
        V.UserId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END) AS LastReopenedDate,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 12) AS DeleteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UPS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UDS.DownVotes, 0) AS TotalDownVotes,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.TotalPosts,
    PH.LastClosedDate,
    PH.LastReopenedDate,
    PH.DeleteCount,
    CASE 
        WHEN PH.LastClosedDate IS NOT NULL AND (PH.LastReopenedDate IS NULL OR PH.LastClosedDate > PH.LastReopenedDate) 
        THEN 'Recently Closed' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    Users U
LEFT JOIN 
    UserVoteSummary UPS ON U.Id = UPS.UserId
LEFT JOIN 
    UserVoteSummary UDS ON U.Id = UDS.UserId
LEFT JOIN 
    RankedPosts RP ON U.Id = RP.OwnerUserId AND RP.ScoreRank <= 5
LEFT JOIN 
    PostHistoryDetails PH ON RP.PostId = PH.PostId
WHERE 
    U.Reputation >= 500
ORDER BY 
    U.Reputation DESC, RP.Score DESC
FETCH FIRST 20 ROWS ONLY;
