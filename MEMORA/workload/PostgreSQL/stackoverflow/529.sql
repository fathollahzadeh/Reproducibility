WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
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
MostVotedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        ub.BadgeCount,
        pvc.UpVotes,
        pvc.DownVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(pvc.UpVotes - pvc.DownVotes, 0) DESC, rp.CreationDate DESC) AS MostVotedRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostVoteCounts pvc ON rp.Id = pvc.PostId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    mvp.Title,
    mvp.CreationDate,
    mvp.BadgeCount,
    mvp.UpVotes,
    mvp.DownVotes,
    CASE 
        WHEN mvp.BadgeCount IS NULL THEN 'No Badges' 
        ELSE 'Has Badges' 
    END AS BadgeStatus
FROM 
    MostVotedPosts mvp
WHERE 
    mvp.MostVotedRank <= 10
ORDER BY 
    mvp.UpVotes DESC, mvp.CreationDate DESC;