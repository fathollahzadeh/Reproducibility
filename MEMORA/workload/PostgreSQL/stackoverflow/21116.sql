WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '30 days')
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryVotes AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS Owner,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(ub.BadgeNames, 'None') AS GoldBadges,
    COALESCE(pv.CloseVotes, 0) AS CloseVoteCount,
    CASE 
        WHEN rp.Upvotes - rp.Downvotes > 0 THEN 'Positive'
        WHEN rp.Upvotes - rp.Downvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN rp.CreationDate <= (cast('2024-10-01' as date) - INTERVAL '15 days') THEN 'Old'
        ELSE 'New'
    END AS PostAge
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryVotes pv ON rp.Id = pv.PostId
WHERE 
    rp.PostRank <= 10 
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;