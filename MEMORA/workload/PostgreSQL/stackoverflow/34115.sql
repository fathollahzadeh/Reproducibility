
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        STRING_AGG(ph.Comment, ', ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserDisplayName, ph.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pd.HistoryDate,
        pd.UserDisplayName,
        pd.Comments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ub.UserId)
    LEFT JOIN 
        PostHistoryDetails pd ON rp.PostId = pd.PostId
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    COALESCE(fp.GoldBadges, 0) AS GoldBadges,
    COALESCE(fp.SilverBadges, 0) AS SilverBadges,
    COALESCE(fp.BronzeBadges, 0) AS BronzeBadges,
    MAX(fp.HistoryDate) AS LatestHistoryDate,
    STRING_AGG(DISTINCT fp.Comments, ' | ') AS AllComments
FROM 
    FilteredPosts fp
GROUP BY 
    fp.PostId, 
    fp.Title, 
    fp.Score, 
    fp.ViewCount, 
    fp.GoldBadges, 
    fp.SilverBadges, 
    fp.BronzeBadges
ORDER BY 
    fp.Score DESC, 
    COUNT(fp.Comments) DESC;
