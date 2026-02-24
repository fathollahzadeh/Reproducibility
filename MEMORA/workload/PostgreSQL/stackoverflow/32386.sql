
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        BadgeCounts bc ON U.Id = bc.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.OwnerDisplayName,
    CR.CloseReason,
    UA.DisplayName AS UserName,
    UA.Reputation,
    UA.BadgeCount,
    UA.ReputationRank,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = RP.PostId) AS CommentCount
FROM 
    RankedPosts RP
LEFT JOIN 
    CloseReasons CR ON RP.PostId = CR.PostId
JOIN 
    UserActivity UA ON UA.Id IN (
        SELECT 
            A.OwnerUserId 
        FROM 
            Posts A 
        WHERE 
            A.PostTypeId = 2 
            AND A.AcceptedAnswerId = RP.PostId
    )
WHERE 
    RP.RankByScore <= 3 
ORDER BY 
    RP.Score DESC, 
    UA.Reputation DESC;
