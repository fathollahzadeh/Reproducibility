
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 1) AS GoldBadges,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 2) AS SilverBadges,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 3) AS BronzeBadges
    FROM 
        Users U
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND P.Score > 0
        AND P.PostTypeId = 1
),
RecentActivity AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.VoteCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PP.Title,
    PP.Score,
    PP.AnswerCount,
    PP.ViewCount,
    R.ActivityRank,
    R.Comment,
    R.CreationDate AS RecentActivityDate
FROM 
    UserStats U
LEFT JOIN 
    PopularPosts PP ON PP.Rank <= 10
LEFT JOIN 
    RecentActivity R ON R.UserId = U.UserId AND R.ActivityRank = 1
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    PP.Score DESC NULLS LAST,
    R.CreationDate DESC;
