WITH RecentVotes AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.Id
), 
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
), 
PostEditHistory AS (
    SELECT 
        Ph.PostId,
        COUNT(*) AS EditCount,
        MAX(Ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        Ph.PostId
)

SELECT 
    P.Title,
    P.Body,
    R.UpVotes,
    R.DownVotes,
    R.TotalVotes,
    U.DisplayName AS PostOwner,
    U.Reputation AS OwnerReputation,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PE.EditCount,
    PE.LastEditDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    RecentVotes R ON P.Id = R.PostId
JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostEditHistory PE ON P.Id = PE.PostId
WHERE 
    P.PostTypeId = 1 
    AND U.Reputation > 100 
    AND R.TotalVotes > 0 
    AND (R.UpVotes - R.DownVotes) > 10 
ORDER BY 
    R.TotalVotes DESC, 
    U.Reputation DESC
LIMIT 50;