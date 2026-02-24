WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        (SELECT COUNT(*)
         FROM Comments C
         WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*)
         FROM Votes V
         WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*)
         FROM Votes V
         WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.CommentCount,
    R.UpvoteCount,
    R.DownvoteCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(PH.HistoryTypes, 'No History') AS HistoryTypes,
    COALESCE(PH.EditCount, 0) AS EditCount
FROM 
    RankedPosts R
JOIN 
    Users U ON R.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
LEFT JOIN 
    PostHistorySummary PH ON R.PostId = PH.PostId
WHERE 
    R.PostRank = 1
ORDER BY 
    R.Score DESC
LIMIT 100;