WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
PostStatistics AS (
    SELECT 
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Title
),
TopPosts AS (
    SELECT 
        Title, 
        CommentCount,
        UpVotes,
        DownVotes,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC, UpVotes DESC) AS Rank
    FROM 
        PostStatistics
    WHERE
        CommentCount > 0
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.TotalViews,
    CASE 
        WHEN tp.Rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS RankingCategory
FROM 
    PostHierarchy ph
LEFT JOIN 
    TopPosts tp ON ph.Title = tp.Title
ORDER BY 
    ph.Level, tp.TotalViews DESC;