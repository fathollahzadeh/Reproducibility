
WITH UserBadgeCounts AS (
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
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        MAX(P.CreationDate) AS LatestActivity,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        PH.UserId AS CloserId,
        PH.CreationDate AS CloseDate,
        PH.Comment AS Reason
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId = 10 
),
UsersWithClosedPosts AS (
    SELECT 
        UP.UserId,
        COUNT(CP.PostId) AS ClosedPostCount
    FROM 
        UserBadgeCounts UP
    LEFT JOIN 
        ClosedPosts CP ON UP.UserId = CP.CloserId
    GROUP BY 
        UP.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(UCC.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(PS.TotalBounty, 0) AS TotalBounty,
    COALESCE(PS.CommentCount, 0) AS CommentCount,
    PS.LatestActivity
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN 
    UsersWithClosedPosts UCC ON U.Id = UCC.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
WHERE 
    (U.Reputation > 100 OR U.Views > 5000)  
    AND (COALESCE(UBC.GoldBadges, 0) > 0 OR COALESCE(UCC.ClosedPostCount, 0) > 5) 
ORDER BY 
    U.Reputation DESC, 
    COALESCE(PS.CommentCount, 0) DESC NULLS LAST, 
    U.DisplayName;
