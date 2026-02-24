WITH RECURSIVE UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.PostTypeId,
        php.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentAction
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes php ON ph.PostHistoryTypeId = php.Id
    WHERE 
        php.Name IN ('Post Closed', 'Post Reopened', 'Edit Title', 'Edit Body')
        AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
AggregatedPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS TotalLinks,
        STRING_AGG(CONCAT(pl.RelatedPostId, ': ', l.Name), ', ') AS RelatedPosts
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes l ON pl.LinkTypeId = l.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    upr.UserId,
    upr.DisplayName,
    upr.TotalPosts,
    upr.TotalComments,
    upr.TotalViews,
    upr.TotalScore,
    upr.Rank,
    rph.Title,
    rph.HistoryType,
    rph.CreationDate AS LastActionDate,
    apl.TotalLinks,
    apl.RelatedPosts
FROM 
    UserPostActivity upr
LEFT JOIN 
    RecentPostHistory rph ON upr.UserId = rph.UserId
LEFT JOIN 
    AggregatedPostLinks apl ON rph.PostId = apl.PostId
WHERE 
    upr.Rank <= 10  
ORDER BY 
    upr.TotalScore DESC,
    rph.CreationDate DESC
LIMIT 100;