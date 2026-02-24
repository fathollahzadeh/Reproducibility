
WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM Votes V
    GROUP BY V.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT RP.PostId) AS RecentPostCount,
    AVG(COALESCE(PVC.UpVotes, 0) - COALESCE(PVC.DownVotes, 0)) AS AveragePostScore,
    STRING_AGG(DISTINCT RP.Title, '; ') AS RecentPostTitles
FROM Users U
LEFT JOIN UserBadgeStats UBS ON U.Id = UBS.UserId
LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.PostRank <= 5
LEFT JOIN PostVoteCounts PVC ON RP.PostId = PVC.PostId
WHERE U.Reputation > 1000
GROUP BY U.Id, U.DisplayName, U.Reputation, UBS.GoldBadges, UBS.SilverBadges, UBS.BronzeBadges
ORDER BY U.Reputation DESC, RecentPostCount DESC
LIMIT 10;
