
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UB.BadgeCount,
    COALESCE(RP.RN, 0) AS RecentPostCount,  -- Adjusted to use RP.RN
    PV.UpVotes,
    PV.DownVotes,
    STRING_AGG(P.TAGS, ', ') AS TagsAggregated
FROM 
    Users U
JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RN = 1
LEFT JOIN 
    PostVoteCounts PV ON PV.PostId = (
        SELECT P.AcceptedAnswerId 
        FROM Posts P 
        WHERE P.OwnerUserId = U.Id 
        AND P.PostTypeId = 1 
        LIMIT 1
    )
LEFT JOIN 
    Posts P ON P.OwnerUserId = U.Id
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL)
GROUP BY 
    U.DisplayName, U.Reputation, UB.BadgeCount, RP.RN, PV.UpVotes, PV.DownVotes
HAVING 
    COUNT(P.Id) > 1 
ORDER BY 
    U.Reputation DESC NULLS LAST
LIMIT 100;
