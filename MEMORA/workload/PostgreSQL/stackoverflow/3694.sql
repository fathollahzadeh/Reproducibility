WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CorrelatedPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        DENSE_RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CommentRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
        AND PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
)
SELECT 
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.AvgViewCount, 0) AS AvgViewCount,
    CASE 
        WHEN CPH.Comment IS NOT NULL THEN CPH.Comment 
        ELSE 'No recent comments on post history' 
    END AS RecentComment
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    (SELECT 
         PostId, 
         UserId, 
         Comment 
     FROM 
         CorrelatedPostHistory 
     WHERE 
         CommentRank = 1) CPH ON CPH.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = U.Id AND AcceptedAnswerId IS NOT NULL LIMIT 1)
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC;