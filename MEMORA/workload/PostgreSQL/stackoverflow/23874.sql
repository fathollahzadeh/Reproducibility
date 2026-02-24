WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        DENSE_RANK() OVER (ORDER BY COALESCE(ph.UserId, -1)) AS UserRank 
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 YEAR' 
        AND p.ViewCount IS NOT NULL
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.RankByViews,
        rp.UserRank,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.RankByViews <= 10
),
FilteredPosts AS (
    SELECT 
        trp.*,
        COALESCE(v.ReceivedVotes, 0) AS TotalVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = trp.PostId) AS CommentCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN (
        SELECT 
            p.Id AS PostId,
            COUNT(v.Id) AS ReceivedVotes
        FROM 
            Posts p
        LEFT JOIN 
            Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 6) 
        GROUP BY 
            p.Id
    ) v ON trp.PostId = v.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.TotalVotes,
    fp.CommentCount,
    fp.UserRank,
    CASE 
        WHEN fp.UserRank = 1 THEN 'This Post is the Most Engaging!'
        ELSE 'Engaging Post'
    END AS EngagementMessage
FROM 
    FilteredPosts fp
WHERE 
    fp.TotalVotes > 0 OR fp.CommentCount > 0
ORDER BY 
    fp.TotalVotes DESC, 
    fp.ViewCount DESC;