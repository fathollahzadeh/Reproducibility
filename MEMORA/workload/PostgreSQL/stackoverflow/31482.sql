
WITH RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= CURRENT_DATE - INTERVAL '6 MONTH'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS HasGold,
        MAX(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS HasSilver,
        MAX(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS HasBronze
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    RP.Title,
    RP.CreationDate,
    RP.AnswerCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.Score,
    UB.BadgeCount,
    CASE 
        WHEN UB.HasGold = 1 THEN 'Gold Badge' 
        WHEN UB.HasSilver = 1 THEN 'Silver Badge' 
        WHEN UB.HasBronze = 1 THEN 'Bronze Badge' 
        ELSE 'No Badge' 
    END AS BadgeStatus
FROM 
    RecentPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    RP.RN = 1
ORDER BY 
    RP.UpVotes DESC, 
    RP.Score DESC,
    RP.CreationDate DESC;
