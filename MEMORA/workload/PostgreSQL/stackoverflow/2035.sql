
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.LastActivityDate, U.DisplayName
), ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        PH.CreationDate AS ClosedDate,
        PH.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    INNER JOIN 
        PostHistory PH ON p.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10  
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.CreationDate,
    RP.LastActivityDate,
    RP.OwnerDisplayName,
    RP.CommentCount,
    CB.ClosedPostId,
    CB.ClosedDate,
    CB.ClosedBy,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CB ON RP.PostId = CB.ClosedPostId
LEFT JOIN 
    UserBadges UB ON RP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = UB.UserId)
WHERE 
    RP.RankByScore <= 5
ORDER BY 
    RP.Score DESC, RP.LastActivityDate DESC
FETCH FIRST 10 ROWS ONLY;
