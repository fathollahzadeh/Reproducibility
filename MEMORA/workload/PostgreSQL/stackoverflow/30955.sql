
WITH RECURSIVE UserRanks AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),

RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, U.DisplayName
),

AggregatedBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UR.Rank AS UserRank,
    COALESCE(AB.GoldBadges, 0) AS GoldBadges,
    COALESCE(AB.SilverBadges, 0) AS SilverBadges,
    COALESCE(AB.BronzeBadges, 0) AS BronzeBadges,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostCreationDate,
    RP.CommentCount,
    RP.VoteCount,
    RP.UpVotes,
    RP.DownVotes
FROM 
    Users U
JOIN 
    UserRanks UR ON U.Id = UR.UserId
LEFT JOIN 
    AggregatedBadges AB ON U.Id = AB.UserId
LEFT JOIN 
    RecentPostActivity RP ON U.DisplayName = RP.OwnerDisplayName
WHERE 
    (UR.Rank <= 10 OR RP.RecentPostRank <= 5)
ORDER BY 
    U.Reputation DESC, RP.LastActivityDate DESC;
