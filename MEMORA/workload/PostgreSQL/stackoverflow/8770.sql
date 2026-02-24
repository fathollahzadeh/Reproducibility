WITH RankedPosts AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostStats AS (
    SELECT 
        t.Author,
        COUNT(*) AS TotalPosts,
        SUM(t.Score) AS TotalScore,
        SUM(t.ViewCount) AS TotalViews
    FROM 
        TopPosts t
    GROUP BY 
        t.Author
)
SELECT 
    ps.Author,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    CASE 
        WHEN ps.TotalPosts > 5 THEN 'Prolific Contributor'
        WHEN ps.TotalScore > 100 THEN 'High Scorer'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    PostStats ps
WHERE 
    ps.TotalViews > 50
ORDER BY 
    ps.TotalScore DESC, ps.TotalViews DESC;