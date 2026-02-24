
WITH UserTagCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.TagName) AS DistinctTagCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    ) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        DistinctTagCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC, TotalScore DESC) AS Rank
    FROM 
        UserTagCounts
),
ActivePostHistories AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId AS EditorId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text,
        ph.PostHistoryTypeId
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
)
SELECT 
    ru.DisplayName,
    ru.DistinctTagCount,
    ru.TotalViews,
    ru.TotalScore,
    COUNT(DISTINCT aph.PostId) AS EditedPostCount,
    MAX(aph.EditDate) AS LastEditDate,
    STRING_AGG(DISTINCT aph.Title, ', ') AS EditedPostTitles
FROM 
    RankedUsers ru
LEFT JOIN 
    ActivePostHistories aph ON ru.UserId = aph.EditorId
GROUP BY 
    ru.UserId, ru.DisplayName, ru.DistinctTagCount, ru.TotalViews, ru.TotalScore, ru.Rank
HAVING 
    ru.DistinctTagCount > 0
ORDER BY 
    ru.Rank
LIMIT 10;
