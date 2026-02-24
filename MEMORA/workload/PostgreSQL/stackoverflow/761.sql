WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
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
    u.DisplayName,
    COUNT(DISTINCT rp.Id) AS QuestionCount,
    SUM(pvc.UpVotes) AS TotalUpVotes,
    SUM(pvc.DownVotes) AS TotalDownVotes,
    CASE 
        WHEN ub.GoldBadges IS NULL THEN 0 ELSE ub.GoldBadges 
    END AS GoldBadges,
    CASE 
        WHEN ub.SilverBadges IS NULL THEN 0 ELSE ub.SilverBadges 
    END AS SilverBadges,
    CASE 
        WHEN ub.BronzeBadges IS NULL THEN 0 ELSE ub.BronzeBadges 
    END AS BronzeBadges,
    MAX(rp.CreationDate) AS LatestPostDate
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostVoteCounts pvc ON rp.Id = pvc.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
HAVING 
    COUNT(DISTINCT rp.Id) > 5
ORDER BY 
    TotalUpVotes DESC, QuestionCount DESC
LIMIT 10;
