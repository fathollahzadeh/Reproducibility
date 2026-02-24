WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.ViewCount > 0 
      AND P.Score IS NOT NULL
),
RecentPostDetails AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        U.DisplayName,
        U.Reputation,
        UBC.BadgeCount,
        UBC.GoldBadges,
        UBC.SilverBadges,
        UBC.BronzeBadges
    FROM PostDetail PD
    JOIN Users U ON PD.OwnerUserId = U.Id
    JOIN UserBadgeCount UBC ON U.Id = UBC.UserId
    WHERE PD.PostRank = 1
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseEventCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
),
RankedPosts AS (
    SELECT 
        RPD.*,
        COALESCE(CPH.CloseEventCount, 0) AS CloseCount,
        CASE 
            WHEN RPD.Score IS NULL THEN 'No Score'
            WHEN RPD.Score = 0 THEN 'Neutral'
            WHEN RPD.Score > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreStatus
    FROM RecentPostDetails RPD
    LEFT JOIN ClosedPostHistory CPH ON RPD.PostId = CPH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.DisplayName AS Owner,
    RP.Reputation,
    RP.BadgeCount,
    RP.GoldBadges,
    RP.SilverBadges,
    RP.BronzeBadges,
    RP.CloseCount,
    RP.ScoreStatus
FROM RankedPosts RP
WHERE RP.Reputation > (
        SELECT AVG(Reputation)
        FROM Users
    )
ORDER BY RP.CreationDate DESC
LIMIT 10
OFFSET 5;