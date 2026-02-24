
WITH RECURSIVE PopularPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 AND p.Score > 10

    UNION ALL

    SELECT
        pp.Id,
        pp.Title,
        pp.CreationDate,
        pp.Score + p.Score AS AccumulatedScore,
        pp.ViewCount + p.ViewCount AS AccumulatedViews,
        pp.OwnerUserId,
        Level + 1
    FROM
        Posts pp
    INNER JOIN PopularPosts p ON pp.ParentId = p.Id
    WHERE
        pp.PostTypeId = 2
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title
),
TopPostStats AS (
    SELECT
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes - ps.DownVotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY ps.CommentCount DESC, ps.UpVotes DESC) AS Rank
    FROM 
        PostStats ps
)

SELECT 
    pp.Id,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    tps.CommentCount,
    tps.NetVotes,
    CASE 
        WHEN tps.Rank <= 10 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostClassification,
    u.DisplayName AS OwnerName,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = pp.OwnerUserId) AS TotalPostsByOwner
FROM 
    PopularPosts pp
JOIN 
    TopPostStats tps ON pp.Id = tps.PostId
JOIN 
    Users u ON pp.OwnerUserId = u.Id
ORDER BY 
    pp.ViewCount DESC, pp.Score DESC
LIMIT 100;
