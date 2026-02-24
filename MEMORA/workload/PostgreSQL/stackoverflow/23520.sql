
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.CreationDate, p.AcceptedAnswerId, p.Score
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
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.Reputation,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.UserPostRank,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent Post'
        WHEN rp.UserPostRank <= 5 THEN 'Recent Activity'
        ELSE 'Older Posts'
    END AS PostStatus,
    CASE 
        WHEN rp.UpVotes > rp.DownVotes THEN 'Positive Engagement'
        WHEN rp.UpVotes < rp.DownVotes THEN 'Negative Feedback'
        ELSE 'Neutral'
    END AS EngagementStatus
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.UserId = rp.OwnerUserId
WHERE 
    tp.ReputationRank <= 50
ORDER BY 
    tp.Reputation DESC, rp.CreationDate DESC
LIMIT 10 OFFSET 0;
