
WITH RECURSIVE UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        p.Title AS PostTitle,
        pt.Name AS PostTypeName,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRow
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalViewCount,
    ue.TotalPosts,
    ue.TotalVotes,
    php.PostTitle,
    php.UserDisplayName AS EditorName,
    php.CreationDate AS EditDate,
    php.PostTypeName,
    CASE 
        WHEN php.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN php.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN php.PostHistoryTypeId = 12 THEN 'Deleted'
        ELSE 'Other Actions'
    END AS ActionType
FROM 
    UserEngagement ue
LEFT JOIN 
    RecentPostHistory php ON php.HistoryRow = 1
WHERE 
    ue.TotalPosts > 5 AND 
    ue.TotalViewCount > 1000 AND 
    php.PostTypeName = 'Question'
ORDER BY 
    ue.TotalViewCount DESC, 
    ue.TotalPosts DESC;
