
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation AS Reputation,
    TU.BadgeCount AS TotalBadges,
    PU.Title AS PopularPost,
    PU.ViewCount AS PopularityViewCount,
    PU.Score AS PopularPostScore,
    UPS.TotalPosts AS UserTotalPosts,
    UPS.AcceptedAnswers AS UserAcceptedAnswers,
    UPS.TotalVotes AS UserTotalVotes
FROM 
    TopUsers TU
JOIN 
    PopularPosts PU ON PU.PopularityRank <= 10
JOIN 
    UserPostStats UPS ON UPS.UserId = TU.UserId
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, PU.ViewCount DESC;
