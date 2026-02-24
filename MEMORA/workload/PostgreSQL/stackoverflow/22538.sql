
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserVoteStats AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(UVS.UpVotes, 0) AS UserUpVotes,
    COALESCE(UVS.DownVotes, 0) AS UserDownVotes,
    RP.Rank,
    RP.TotalPosts,
    CASE 
        WHEN RP.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostType,
    CASE 
        WHEN RP.ViewCount IS NULL THEN 'No Views Recorded'
        WHEN RP.ViewCount > 1000 THEN 'Highly Viewed'
        ELSE 'Regular Views'
    END AS ViewCountDescription
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges UB ON RP.OwnerUserId = UB.UserId
LEFT JOIN 
    UserVoteStats UVS ON RP.OwnerUserId = UVS.UserId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;
