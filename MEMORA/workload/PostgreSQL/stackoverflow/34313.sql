WITH RECURSIVE TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Ranking
    FROM Users
), UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        MAX(B.Class) AS HighestBadgeClass,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS PopularityRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 MONTH'
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.Score
), UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.Score) AS AveragePostScore,
        SUM(COALESCE(UPV.VoteCount, 0)) AS TotalUpVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (SELECT 
                    PostId, 
                    COUNT(*) AS VoteCount 
               FROM Votes 
               WHERE VoteTypeId = 2 
               GROUP BY PostId) UPV ON P.Id = UPV.PostId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    UB.TotalBadges,
    UB.HighestBadgeClass,
    COALESCE(UP.PostsCreated, 0) AS PostsCount,
    COALESCE(UP.TotalScore, 0) AS TotalPostScore,
    COALESCE(UP.AveragePostScore, 0) AS AvgPostScore,
    COALESCE(UP.TotalUpVotes, 0) AS TotalUpVotes,
    PP.Title AS PopularPostTitle,
    PP.Score as PopularPostScore
FROM TopUsers TU
LEFT JOIN UserBadges UB ON TU.Id = UB.UserId
LEFT JOIN UserPostStats UP ON TU.Id = UP.UserId
LEFT JOIN PopularPosts PP ON TU.Id = PP.OwnerUserId AND PP.PopularityRank <= 5
WHERE TU.Ranking <= 10
ORDER BY TU.Reputation DESC, UB.TotalBadges DESC;