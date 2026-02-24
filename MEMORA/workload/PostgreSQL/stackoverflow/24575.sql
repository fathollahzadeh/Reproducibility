
WITH UserStats AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
           COUNT(DISTINCT P.Id) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 1) AS GoldBadges,
           (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 2) AS SilverBadges,
           (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 3) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ActiveUserPosts AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           P.Id AS PostId,
           P.CreationDate,
           P.Title,
           P.Score,
           P.ViewCount,
           (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.LastActivityDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
),
RankedPosts AS (
    SELECT A.UserId,
           A.DisplayName,
           A.PostId,
           A.Title,
           A.Score,
           A.ViewCount,
           A.CommentCount,
           ROW_NUMBER() OVER (PARTITION BY A.UserId ORDER BY A.Score DESC, A.ViewCount DESC) AS PostRank
    FROM ActiveUserPosts A
)
SELECT U.UserId,
       U.DisplayName,
       U.Reputation,
       U.Upvotes,
       U.Downvotes,
       U.TotalPosts,
       U.Questions,
       U.Answers,
       U.GoldBadges,
       U.SilverBadges,
       U.BronzeBadges,
       RP.PostId,
       RP.Title,
       RP.Score,
       RP.ViewCount,
       RP.CommentCount
FROM UserStats U
LEFT JOIN RankedPosts RP ON U.UserId = RP.UserId
WHERE RP.PostRank <= 3 OR RP.PostRank IS NULL
ORDER BY U.Reputation DESC,
         U.UserId,
         RP.Score DESC NULLS LAST;
