
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN b.Date END) AS GoldBadgeDate,
        MAX(CASE WHEN b.Class = 2 THEN b.Date END) AS SilverBadgeDate,
        MAX(CASE WHEN b.Class = 3 THEN b.Date END) AS BronzeBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rb.BadgeCount AS UserBadgeCount,
    CASE 
        WHEN rb.GoldBadgeDate IS NOT NULL THEN 'Gold'
        WHEN rb.SilverBadgeDate IS NOT NULL THEN 'Silver'
        WHEN rb.BronzeBadgeDate IS NOT NULL THEN 'Bronze'
        ELSE 'No Badge'
    END AS UserBadgeStatus,
    pHD.HistoryTypes,
    pHD.LastChangeDate,
    ra.TotalVotes,
    ra.UpVotes,
    ra.DownVotes,
    COALESCE(ra.TotalVotes, 0) - COALESCE(ra.UpVotes, 0) - COALESCE(ra.DownVotes, 0) AS NeutralVotes
FROM 
    RankedPosts rp
JOIN 
    UsersWithBadges rb ON rp.OwnerUserId = rb.UserId
JOIN 
    PostHistoryDetails pHD ON rp.PostId = pHD.PostId
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.RankByScore <= 5 
    AND (pHD.LastChangeDate IS NULL OR pHD.LastChangeDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '180 days')
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
