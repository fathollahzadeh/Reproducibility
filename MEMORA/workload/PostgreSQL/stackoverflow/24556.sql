
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RecentRank,
        DENSE_RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

RecentActivity AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS UserComments
    FROM 
        Comments C
    JOIN 
        Posts P ON C.PostId = P.Id
    WHERE 
        C.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        C.PostId
),

PostCloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS int) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),

UserBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Class,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    GROUP BY 
        U.Id, B.Class
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.PostTypeId,
    RP.ViewCount,
    RP.CreationDate,
    RP.Score,
    RA.CommentCount,
    RA.UserComments,
    PCR.CloseReasons,
    UB.BadgeCount,
    UB.BadgeNames
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentActivity RA ON RP.PostId = RA.PostId
LEFT JOIN 
    PostCloseReasons PCR ON RP.PostId = PCR.PostId
LEFT JOIN 
    UserBadges UB ON RP.PostId = UB.UserId
WHERE 
    RP.RecentRank <= 10 
    AND RP.ScoreRank > 5 
ORDER BY 
    RP.ViewCount DESC, 
    RP.Score DESC;