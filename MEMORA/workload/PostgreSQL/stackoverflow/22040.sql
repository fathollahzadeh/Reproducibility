
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), 
UserPostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS WikiPosts
    FROM Posts P
    GROUP BY P.OwnerUserId
),
VotesAggregated AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT V.PostId) AS UniquePostsVoted
    FROM Votes V
    GROUP BY V.UserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UPS.TotalPosts, 0) AS TotalPosts,
        COALESCE(VA.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(VA.TotalDownVotes, 0) AS TotalDownVotes,
        U.Reputation
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN UserPostStats UPS ON U.Id = UPS.OwnerUserId
    LEFT JOIN VotesAggregated VA ON U.Id = VA.UserId
    WHERE U.Reputation > 1000 OR COALESCE(UB.BadgeCount, 0) > 5
)
SELECT 
    TU.DisplayName,
    TU.BadgeCount,
    TU.TotalPosts,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    ROUND(COALESCE((CAST(TU.TotalUpVotes AS FLOAT) / NULLIF(TU.TotalPosts, 0)) * 100, 0), 2) AS UpvotePercentage,
    (
        SELECT STRING_AGG(DISTINCT P.Title, ', ') 
        FROM Posts P 
        WHERE P.OwnerUserId = TU.Id 
        AND P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    ) AS RecentPostTitles,
    (
        SELECT COUNT(*) 
        FROM Comments C 
        WHERE C.UserId = TU.Id
    ) AS TotalComments
FROM TopUsers TU
WHERE TU.TotalPosts > 0
ORDER BY TU.Reputation DESC, TU.BadgeCount DESC
FETCH FIRST 10 ROWS ONLY;
