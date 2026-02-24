
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
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
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
),
PostMetrics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.CommentCount,
        PD.UpVotes,
        PD.DownVotes,
        COALESCE(UR.Reputation, 0) AS OwnerReputation,
        COALESCE(UR.BadgeCount, 0) AS OwnerBadgeCount,
        COALESCE(UR.GoldBadges, 0) AS OwnerGoldBadges,
        COALESCE(UR.SilverBadges, 0) AS OwnerSilverBadges,
        COALESCE(UR.BronzeBadges, 0) AS OwnerBronzeBadges
    FROM PostDetails PD
    LEFT JOIN UserReputation UR ON PD.OwnerUserId = UR.UserId
    WHERE PD.RowNum = 1
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    CommentCount,
    UpVotes,
    DownVotes,
    OwnerReputation,
    OwnerBadgeCount,
    OwnerGoldBadges,
    OwnerSilverBadges,
    OwnerBronzeBadges
FROM PostMetrics
ORDER BY Score DESC, CreationDate DESC
FETCH FIRST 10 ROWS ONLY;
