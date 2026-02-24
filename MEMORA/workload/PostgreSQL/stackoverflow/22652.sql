
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.LatestPostDate, '1900-01-01') AS LatestPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId, 
        COUNT(H.Id) AS CloseVoteCount,
        MAX(H.CreationDate) AS LastCloseDate,
        STRING_AGG(DISTINCT CT.Name, ', ') AS CloseReasons
    FROM 
        Posts P
    JOIN 
        PostHistory H ON P.Id = H.PostId AND H.PostHistoryTypeId IN (10, 11) 
    LEFT JOIN 
        CloseReasonTypes CT ON (H.Comment IS NOT NULL AND CAST(H.Comment AS INTEGER) = CT.Id)
    GROUP BY 
        P.Id
),
CombinedStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalBadges,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.LatestPostDate,
        CP.CloseVoteCount,
        CP.LastCloseDate,
        CP.CloseReasons
    FROM 
        UserActivity UA
    LEFT JOIN 
        ClosedPosts CP ON UA.UserId = CP.PostId
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    LatestPostDate,
    CloseVoteCount,
    LastCloseDate,
    CASE 
        WHEN TotalPosts = 0 THEN 'No Activity'
        WHEN CloseVoteCount > 0 THEN 'Posts Closed'
        ELSE 'Active'
    END AS UserStatus,
    CASE 
        WHEN CloseReasons IS NULL THEN 'No Reasons'
        ELSE CloseReasons
    END AS ClosuresReasons
FROM 
    CombinedStats
WHERE 
    (TotalPosts > 5 OR TotalBadges > 2)
ORDER BY 
    TotalPosts DESC, TotalBadges DESC;
