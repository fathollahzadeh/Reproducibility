WITH PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ps.UpVotes,
        ps.DownVotes,
        ps.TotalVotes,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(ub.GoldBadges, 0) AS UserGoldBadges,
        COALESCE(ub.SilverBadges, 0) AS UserSilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS UserBronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStats ps ON p.Id = ps.PostId
    LEFT JOIN 
        UserBadgeCounts ub ON p.OwnerUserId = ub.UserId
)
SELECT 
    pd.Id AS PostId,
    pd.Title,
    pd.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.TotalVotes,
    pd.UserBadgeCount,
    pd.UserGoldBadges,
    pd.UserSilverBadges,
    pd.UserBronzeBadges
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.OwnerUserId = u.Id
WHERE 
    pd.TotalVotes > 5 
ORDER BY 
    pd.TotalVotes DESC, 
    pd.CreationDate ASC
LIMIT 10;
