WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        P.Title,
        P.ViewCount,
        COUNT(A.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.CreationDate, P.Title, P.ViewCount
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostClosureStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PostId
),
HighPerformanceAnalytics AS (
    SELECT 
        UPS.PostId,
        U.DisplayName AS OwnerName,
        UPS.Score AS PostScore,
        UPS.ViewCount,
        CASE 
            WHEN U.Location IS NOT NULL THEN U.Location
            ELSE 'Location not specified'
        END AS UserLocation,
        COALESCE(UB.TotalBadges, 0) AS UserBadges,
        COALESCE(PCS.CloseCount, 0) AS CloseCount,
        COALESCE(PCS.ReopenCount, 0) AS ReopenCount,
        UPS.Title,
        UPS.CreationDate
    FROM 
        RecursivePostStats UPS
    JOIN 
        Users U ON UPS.OwnerUserId = U.Id
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostClosureStats PCS ON UPS.PostId = PCS.PostId
    WHERE 
        UPS.UserPostRank <= 5 
)
SELECT 
    HPA.OwnerName,
    HPA.Title,
    HPA.PostScore,
    HPA.ViewCount,
    HPA.UserLocation,
    HPA.UserBadges,
    HPA.CloseCount,
    HPA.ReopenCount
FROM 
    HighPerformanceAnalytics HPA
ORDER BY 
    HPA.PostScore DESC, HPA.ViewCount DESC
LIMIT 10;