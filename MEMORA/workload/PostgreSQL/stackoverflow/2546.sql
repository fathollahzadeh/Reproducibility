
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
),
AggregatedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    U.DisplayName AS PostOwner,
    UGold.GoldBadges,
    USilver.SilverBadges,
    UBronze.BronzeBadges,
    A.TotalBounty,
    A.TotalViews,
    A.AverageScore,
    CP.CloseReason
FROM 
    RankedPosts R
JOIN 
    Users U ON R.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UGold ON U.Id = UGold.UserId
LEFT JOIN 
    UserBadges USilver ON U.Id = USilver.UserId
LEFT JOIN 
    UserBadges UBronze ON U.Id = UBronze.UserId
LEFT JOIN 
    AggregatedStats A ON U.Id = A.UserId
LEFT JOIN 
    ClosedPosts CP ON R.PostId = CP.PostId
WHERE 
    R.PostRank = 1
ORDER BY 
    R.CreationDate DESC
LIMIT 100;
