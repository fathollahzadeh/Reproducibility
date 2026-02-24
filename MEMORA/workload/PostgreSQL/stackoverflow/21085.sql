
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        (COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) - COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3)) AS NetScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE NULL END) AS ClosedByUser
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    pd.Title,
    pd.CommentCount,
    pd.Upvotes,
    pd.Downvotes,
    pd.NetScore,
    cp.LastClosedDate,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    (CASE WHEN cp.ClosedByUser IS NOT NULL THEN 'Closed' ELSE 'Active' END) AS PostStatus,
    CASE 
        WHEN pd.NetScore > 0 THEN 'Positive'
        WHEN pd.NetScore < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END AS ScoreCategory
FROM 
    UserStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
LEFT JOIN 
    PostDetails pd ON p.Id = pd.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    us.Reputation > 1000
    AND pd.CommentCount > 0
    AND pd.PostRank = 1
ORDER BY 
    us.Reputation DESC, pd.NetScore DESC
LIMIT 100;
