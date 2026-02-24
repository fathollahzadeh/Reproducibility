
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges,
        SUM(CASE WHEN b.TagBased THEN 1 ELSE 0 END) AS TagBasedBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COALESCE(SUM(p.FavoriteCount), 0) AS FavoriteCount 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        r.Name AS PostHistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes r ON ph.PostHistoryTypeId = r.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '365 days'
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ub.TagBasedBadges,
    pa.CommentCount,
    pa.UpvoteCount,
    pa.DownvoteCount,
    pa.FavoriteCount,
    COUNT(DISTINCT ph.PostId) AS PostHistoryCount,
    COUNT(DISTINCT rp.Id) AS RecentPostsCount
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostActivity pa ON u.Id = pa.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON u.Id = ph.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Posts.Id = rp.Id
        LIMIT 1
    )
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ub.GoldBadges, ub.SilverBadges, 
    ub.BronzeBadges, ub.TagBasedBadges, pa.CommentCount, 
    pa.UpvoteCount, pa.DownvoteCount, pa.FavoriteCount
HAVING 
    COUNT(DISTINCT rp.Id) > 5 
    AND SUM(COALESCE(pa.UpvoteCount, 0) - COALESCE(pa.DownvoteCount, 0)) > 10
ORDER BY 
    u.Reputation DESC, PostHistoryCount DESC;
