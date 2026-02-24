WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        PS.PostCount,
        PS.PositivePosts,
        PS.NegativePosts,
        PS.AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        *, 
        CASE 
            WHEN Reputation > 10000 THEN 'Elite User'
            WHEN Reputation BETWEEN 5000 AND 10000 THEN 'Experienced User'
            ELSE 'Novice User' 
        END AS UserTier
    FROM UserPostSummary
)
SELECT 
    U.*,
    COALESCE(P.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(V.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN U.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM TopUsers U
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPostCount
    FROM Posts P
    WHERE P.Id IN (
        SELECT PH.PostId 
        FROM PostHistory PH 
        WHERE PH.PostHistoryTypeId = 10 
    )
    GROUP BY P.OwnerUserId
) P ON U.UserId = P.OwnerUserId
LEFT JOIN (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes
    FROM Votes V
    GROUP BY V.UserId
) V ON U.UserId = V.UserId
WHERE U.Reputation IS NOT NULL 
ORDER BY U.Reputation DESC, U.DisplayName;