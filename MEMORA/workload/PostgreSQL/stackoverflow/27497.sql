
WITH TagAnalytics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ContributingUsers
    FROM 
        Tags
    JOIN 
        Posts p ON p.Tags LIKE '%' || Tags.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        Tags.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(th.PostCount, 0) AS TotalTags,
        COALESCE(th.TotalViews, 0) AS TagViews,
        COALESCE(th.TotalScore, 0) AS TagScores,
        COALESCE(th.AvgUserReputation, 0) AS AvgUserRep,
        COALESCE(th.ContributingUsers, 'None') AS Contributors,
        COALESCE(phs.HistoryCount, 0) AS EditCount,
        COALESCE(phs.Editors, 'No Edits') AS LastEditors
    FROM 
        Posts p
    LEFT JOIN 
        TagAnalytics th ON p.Tags LIKE '%' || th.TagName || '%'
    LEFT JOIN 
        PostHistoryStats phs ON p.Id = phs.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.AnswerCount,
    pm.TotalTags,
    pm.TagViews,
    pm.TagScores,
    pm.AvgUserRep,
    pm.Contributors,
    pm.EditCount,
    pm.LastEditors
FROM 
    PostMetrics pm
WHERE 
    pm.ViewCount > 100
ORDER BY 
    pm.TagScores DESC, pm.ViewCount DESC
LIMIT 10;
