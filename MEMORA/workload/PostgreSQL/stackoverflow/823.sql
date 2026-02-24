WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.Score IS NOT NULL
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    LEFT JOIN 
        CloseReasonTypes C ON PH.Comment = C.Id::text
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT V.PostId) AS UpVotesGiven,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId = 2  
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate,
    RP.OwnerName,
    COALESCE(CR.CloseReason, 'Not Closed') AS CloseStatus,
    UA.UpVotesGiven,
    UA.CommentsMade,
    UA.GoldBadges
FROM 
    RankedPosts RP
LEFT JOIN 
    CloseReasons CR ON RP.PostId = CR.PostId
LEFT JOIN 
    UserActivity UA ON RP.OwnerName = UA.UserId::text
WHERE 
    RP.RankByScore <= 5 
ORDER BY 
    RP.Score DESC, RP.PostId ASC;