
WITH RankedPosts AS (
    SELECT P.Id AS PostId, 
           P.OwnerUserId, 
           P.Score, 
           P.Title,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerRank
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    AND P.PostTypeId = 1 
),
UserReputation AS (
    SELECT U.Id AS UserId, 
           U.Reputation, 
           U.DisplayName, 
           COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
           COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
           COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT PH.PostId, 
           PH.CreationDate, 
           MAX(PH.CreationDate) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MostRecentCloseDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
),
PostDetails AS (
    SELECT RP.PostId,
           RP.Title,
           UR.DisplayName,
           UR.Reputation,
           RP.Score,
           C.MostRecentCloseDate,
           CASE 
                WHEN C.MostRecentCloseDate IS NOT NULL THEN 'Closed'
                ELSE 'Active' 
           END AS PostStatus
    FROM RankedPosts RP
    JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
    LEFT JOIN ClosedPosts C ON RP.PostId = C.PostId
),
FinalResults AS (
    SELECT PD.PostId, 
           PD.Title, 
           PD.DisplayName, 
           PD.Reputation, 
           PD.Score, 
           PD.MostRecentCloseDate, 
           PD.PostStatus, 
           COUNT(CMT.Id) AS CommentCount,
           AVG(V.BountyAmount) AS AverageBounty 
    FROM PostDetails PD
    LEFT JOIN Comments CMT ON PD.PostId = CMT.PostId
    LEFT JOIN Votes V ON PD.PostId = V.PostId AND V.VoteTypeId = 8 
    GROUP BY PD.PostId, PD.Title, PD.DisplayName, PD.Reputation, PD.Score, PD.MostRecentCloseDate, PD.PostStatus
)
SELECT PostId, 
       Title, 
       DisplayName, 
       Reputation, 
       Score, 
       PostStatus, 
       CommentCount, 
       COALESCE(AverageBounty, 0) AS AverageBounty,
       CASE 
           WHEN Reputation >= 1000 THEN 'High Reputation'
           WHEN Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
           ELSE 'Low Reputation' 
       END AS ReputationTier
FROM FinalResults
WHERE CommentCount > 5
ORDER BY Score DESC, Reputation DESC;
