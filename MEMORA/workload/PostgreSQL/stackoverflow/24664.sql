WITH UserBadgeCounts AS (
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
PostScore AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId IN (2, 3) THEN v.UserId END) AS DistinctVoters
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id
),
FancyPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        ps.UpVotes,
        ps.DownVotes,
        COALESCE(BadgeCounts.BadgeCount, 0) AS BadgeCount,
        COALESCE(RA.LastActivityDate, '1900-01-01') AS LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostScore ps ON p.Id = ps.PostId
    LEFT JOIN 
        UserBadgeCounts BadgeCounts ON p.OwnerUserId = BadgeCounts.UserId
    LEFT JOIN 
        RecentActivity RA ON p.OwnerUserId = RA.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND (ps.UpVotes - ps.DownVotes) > 10
        AND (p.Tags IS NOT NULL AND p.Tags <> '')
)
SELECT 
    fp.Title,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    fp.BadgeCount,
    fp.LastActivityDate,
    CASE 
        WHEN fp.UserPostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    FancyPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.BadgeCount DESC, 
    fp.LastActivityDate DESC;