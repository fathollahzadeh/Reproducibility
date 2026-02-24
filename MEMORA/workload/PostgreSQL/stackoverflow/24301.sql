WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id
), 
PopularPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        RankByScore,
        CommentCount,
        LastVoteDate,
        CASE 
            WHEN RankByScore = 1 THEN 'Top'
            WHEN RankByScore BETWEEN 2 AND 5 THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        RankedPosts
    WHERE 
        ViewCount > (
            SELECT AVG(ViewCount) 
            FROM RankedPosts
        )
), 
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.UserId AS ClosedBy, 
        ph.CreationDate, 
        ph.Comment AS CloseReason, 
        pt.Name AS PostTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON p.Id = ph.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pht.Name = 'Post Closed' 
        AND ph.CreationDate < cast('2024-10-01' as date) - INTERVAL '1 month'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    pp.PostId,
    pp.Title AS PostTitle,
    pp.ViewCount,
    pp.Popularity,
    cp.ClosedBy,
    cp.CreationDate AS CloseDate,
    cp.CloseReason,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    PopularPosts pp
LEFT JOIN 
    ClosedPosts cp ON pp.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON pp.PostId = (
        SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId
    )
WHERE 
    (pp.Popularity = 'Top' OR cp.CloseReason IS NOT NULL)
    AND (pp.CommentCount IS NULL OR pp.CommentCount > 5)
ORDER BY 
    pp.ViewCount DESC, pp.PostId
LIMIT 100;