
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentTotal,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
PostAgg AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentTotal,
        us.UserId,
        us.DisplayName,
        (us.GoldBadges + us.SilverBadges + us.BronzeBadges) AS TotalBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.Rank = 1
)
SELECT 
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.CommentTotal,
    pa.TotalBadges,
    COALESCE(ROUND((CAST(pa.Score AS decimal) / NULLIF(pa.ViewCount, 0)) * 100, 2), 0) AS EngagementRate
FROM 
    PostAgg pa
LEFT JOIN 
    PostHistory ph ON pa.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
WHERE 
    ph.Id IS NULL
ORDER BY 
    EngagementRate DESC
LIMIT 10;
