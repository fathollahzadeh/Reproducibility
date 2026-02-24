
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
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN V.Id END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN V.Id END) AS DownvoteCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.Id END) AS CloseVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId, P.Title, P.CreationDate, P.AcceptedAnswerId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.Reputation,
        U.DisplayName,
        U.CreationDate,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = U.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Comments WHERE UserId = U.Id) AS TotalComments
    FROM 
        Users U
    WHERE 
        U.LastAccessDate >= DATE '2024-10-01' - INTERVAL '30 days'
)

SELECT 
    U.DisplayName AS ActiveUser,
    COALESCE(UB.BadgeCount, 0) AS Badges,
    COALESCE(UB.GoldBadges, 0) AS Gold,
    COALESCE(UB.SilverBadges, 0) AS Silver,
    COALESCE(UB.BronzeBadges, 0) AS Bronze,
    COUNT(DISTINCT PI.PostId) AS TotalPosts,
    SUM(PI.CommentCount) AS TotalComments,
    SUM(PI.UpvoteCount) AS TotalUpvotes,
    SUM(PI.DownvoteCount) AS TotalDownvotes,
    SUM(PI.CloseVotes) AS TotalCloseVotes
    
FROM 
    ActiveUsers U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostInfo PI ON U.Id = PI.OwnerUserId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.DisplayName, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges, U.Reputation
HAVING 
    COUNT(DISTINCT PI.PostId) > 5
ORDER BY 
    U.Reputation DESC, TotalPosts DESC
LIMIT 10;
