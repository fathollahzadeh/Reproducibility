
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score IS NOT NULL
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
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (12, 13)) AS DeleteRestoreCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
JoinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        phd.ClosedDate,
        phd.ReopenedDate,
        phd.DeleteRestoreCount,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
)
SELECT 
    jd.PostId,
    jd.Title,
    jd.CreationDate,
    jd.Score,
    COALESCE(jd.GoldBadges, 0) AS GoldBadges,
    COALESCE(jd.SilverBadges, 0) AS SilverBadges,
    COALESCE(jd.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN jd.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN jd.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = jd.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = jd.PostId AND v.VoteTypeId = 3) AS DownVotes,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    JoinedData jd
LEFT JOIN 
    Comments c ON c.PostId = jd.PostId
WHERE 
    jd.Rank <= 5
GROUP BY 
    jd.PostId, jd.Title, jd.CreationDate, jd.Score, jd.GoldBadges, jd.SilverBadges, jd.BronzeBadges, jd.ClosedDate, jd.ReopenedDate, jd.Rank
ORDER BY 
    jd.Score DESC, jd.CreationDate DESC;
