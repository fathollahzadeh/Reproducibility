
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate < '2024-10-01 12:34:56' AND
        P.Score IS NOT NULL 
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
),
CombinedData AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        U.GoldBadges,
        RP.Score,
        RP.UpVotes,
        RP.DownVotes,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        COALESCE(CP.LastClosedDate, '1900-01-01') AS LastClosedDate
    FROM 
        RankedPosts RP
    JOIN 
        UserStats U ON RP.PostId = U.UserId
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
    WHERE 
        RP.PostRank <= 5 
)
SELECT 
    Title,
    CreationDate,
    OwnerDisplayName,
    Score,
    UpVotes,
    DownVotes,
    CloseCount,
    LastClosedDate,
    CASE 
        WHEN CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    CombinedData
ORDER BY 
    Score DESC, Title;
