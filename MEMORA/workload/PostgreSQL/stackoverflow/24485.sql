WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
), 
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), 
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), 
ClosedPostReasons AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS ClosePostCount,
        STRING_AGG(DISTINCT CT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment = CAST(CT.Id AS varchar)
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
), 
Engagement AS (
    SELECT 
        PS.OwnerUserId,
        PS.PostCount,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(CPR.ClosePostCount, 0) AS ClosePostCount,
        COALESCE(CPR.CloseReasons, 'None') AS CloseReasons,
        ROW_NUMBER() OVER (ORDER BY PS.TotalScore DESC) AS EngagementRank
    FROM 
        PostStats PS
    LEFT JOIN 
        UserBadges UB ON PS.OwnerUserId = UB.UserId
    LEFT JOIN 
        ClosedPostReasons CPR ON PS.OwnerUserId = CPR.UserId 
)
SELECT 
    RU.DisplayName,
    RU.UserRank,
    E.PostCount,
    E.BadgeCount,
    E.ClosePostCount,
    E.CloseReasons,
    E.EngagementRank,
    CASE 
        WHEN E.ClosePostCount > 0 THEN 
            'User has closed posts, evaluate engagement.'
        ELSE 
            'User has not closed any posts.'
    END AS EngagementStatus
FROM 
    RankedUsers RU
JOIN 
    Engagement E ON RU.UserId = E.OwnerUserId
WHERE 
    RU.UserRank <= 10
ORDER BY 
    E.EngagementRank;
