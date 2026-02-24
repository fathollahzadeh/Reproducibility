
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id, p.Title
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        us.UserId,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COALESCE(cp.FirstClosedDate, NULL) AS PostClosedDate
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.ViewCount > 100 
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.RankScore <= 10  
)
SELECT 
    hsp.Title,
    hsp.Score,
    hsp.GoldBadges,
    hsp.SilverBadges,
    hsp.BronzeBadges,
    CASE 
      WHEN hsp.PostClosedDate IS NOT NULL THEN 'Closed'
      ELSE 'Open'
    END AS PostStatus,
    CASE 
      WHEN hsp.Score > 50 THEN 'Highly Engaged'
      WHEN hsp.Score BETWEEN 20 AND 50 THEN 'Moderately Engaged'
      ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    HighScoringPosts hsp
ORDER BY 
    hsp.Score DESC, 
    hsp.Title
LIMIT 20;
