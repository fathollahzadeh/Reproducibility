
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.OwnerUserId, -1) AS OwnerUserId,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS INT) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerUserId,
    COALESCE(ub.BadgeCount, 0) AS NumberOfBadges,
    rp.OwnerReputation,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    cr.CloseReasonNames,
    CASE 
        WHEN rp.RecentPostRank = 1 THEN 'Most Recent Post'
        ELSE CONCAT('Poster has ', rp.RecentPostRank, ' recent posts')
    END AS PostStatus,
    CASE 
        WHEN rp.OwnerReputation < 100 THEN 'Low Reputation' 
        WHEN rp.OwnerReputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
        ELSE 'High Reputation'
    END AS ReputationCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.RecentPostRank <= 3
ORDER BY 
    rp.CreationDate DESC;
