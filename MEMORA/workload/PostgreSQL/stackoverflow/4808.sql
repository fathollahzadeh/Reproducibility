WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM Badges B
    GROUP BY B.UserId
), PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(Cm.Id), 0) AS CommentCount,
        COALESCE(MAX(PH.CreationDate), P.CreationDate) AS LastActivityDate
    FROM Posts P
    LEFT JOIN Comments Cm ON P.Id = Cm.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount
), RankedPosts AS (
    SELECT 
        PA.*,
        ROW_NUMBER() OVER (ORDER BY PA.ViewCount DESC, PA.LastActivityDate DESC) AS Rank
    FROM PostActivity PA
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.UpvoteCount,
    U.DownvoteCount,
    U.PostCount,
    COALESCE(BC.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(BC.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(BC.BronzeBadgeCount, 0) AS BronzeBadgeCount,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.CommentCount,
    RP.Rank
FROM UserStats U
LEFT JOIN BadgeCounts BC ON U.UserId = BC.UserId
LEFT JOIN RankedPosts RP ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, RP.Rank ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
