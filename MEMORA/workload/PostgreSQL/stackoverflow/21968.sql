
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(B.UserId, -1) AS OwnerId,
        COALESCE(B.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(B.BadgeNames, 'No Badges') AS UserBadges
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        UserBadges B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, B.UserId, B.BadgeCount, B.BadgeNames
),
RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (PARTITION BY PD.OwnerId ORDER BY PD.Score DESC) AS PostRank,
        RANK() OVER (ORDER BY PD.ViewCount DESC) AS GlobalViewRank
    FROM 
        PostDetails PD
),
TopPosts AS (
    SELECT 
        RP.*
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank = 1
        AND RP.GlobalViewRank <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.CommentCount,
    TP.UserBadgeCount,
    TP.UserBadges,
    CASE 
        WHEN TP.UserBadgeCount > 2 THEN 'Active User'
        WHEN TP.UserBadgeCount IS NULL THEN 'New User'
        ELSE 'Moderate User'
    END AS UserStatus
FROM 
    TopPosts TP
LEFT JOIN 
    VoteTypes VT ON EXISTS (SELECT 1 FROM Votes V WHERE V.PostId = TP.PostId AND V.VoteTypeId = VT.Id)
WHERE 
    TP.Score > 0
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC
LIMIT 50 OFFSET 0;
