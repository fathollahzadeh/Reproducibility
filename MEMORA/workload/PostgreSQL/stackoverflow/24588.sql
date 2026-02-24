
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RankByDate,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.Score > 0 THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.DisplayName,
        rp.Score,
        rp.RankByScore,
        us.BadgeCount,
        us.TotalViews
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.RankByScore <= 5 
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.DisplayName,
        tp.Score,
        COALESCE(cp.ClosedCount, 0) AS ClosedCount,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = tp.PostId) THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus,
        CASE 
            WHEN tp.TotalViews > 1000 THEN 'Popular'
            ELSE 'Normal'
        END AS Popularity
    FROM 
        TopPosts tp
    LEFT JOIN 
        ClosedPosts cp ON tp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.DisplayName,
    ps.Score,
    ps.ClosedCount,
    ps.CommentStatus,
    ps.Popularity,
    CASE 
        WHEN ps.ClosedCount > 0 THEN 'This post has been closed.'
        ELSE 'This post is open for discussion.'
    END AS PostStatusDescription,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostStatistics ps
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = ps.PostId
    ) t ON TRUE
GROUP BY 
    ps.PostId,
    ps.Title,
    ps.DisplayName,
    ps.Score,
    ps.ClosedCount,
    ps.CommentStatus,
    ps.Popularity
ORDER BY 
    ps.Score DESC, 
    ps.ClosedCount DESC;
