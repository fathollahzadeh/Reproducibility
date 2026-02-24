
WITH UserReputation AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COUNT(B.Id) AS BadgeCount,
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
MostActivePosts AS (
    SELECT P.OwnerUserId,
           COUNT(P.Id) AS PostCount,
           SUM(P.ViewCount) AS TotalViews,
           AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
PostDetails AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.Score,
           P.ViewCount,
           COALESCE(PH.Comment, 'No history') AS LastComment,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank,
           P.OwnerUserId
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT ur.UserId,
       ur.DisplayName,
       ur.Reputation,
       ur.BadgeCount,
       ur.GoldBadges,
       ur.SilverBadges,
       ur.BronzeBadges,
       ap.PostCount,
       ap.TotalViews,
       ap.AverageScore,
       pd.PostId,
       pd.Title,
       pd.CreationDate,
       pd.Score,
       pd.ViewCount,
       pd.LastComment
FROM UserReputation ur
JOIN MostActivePosts ap ON ur.UserId = ap.OwnerUserId
LEFT JOIN PostDetails pd ON ur.UserId = pd.OwnerUserId AND pd.RecentPostRank = 1
WHERE ur.Reputation > (SELECT AVG(Reputation) FROM Users) 
AND pd.Score IS NOT NULL
ORDER BY ur.Reputation DESC, ap.TotalViews DESC;
