WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY Tag
),
RecentEdits AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Comment AS EditComment,
        ph.Text AS NewValue,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
),
EditorStats AS (
    SELECT 
        Editor,
        COUNT(DISTINCT PostId) AS TotalEditedPosts,
        MIN(EditDate) AS FirstEditDate,
        MAX(EditDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM RecentEdits
    WHERE EditRank = 1 
    GROUP BY Editor
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
)
SELECT 
    e.Editor,
    e.TotalEditedPosts,
    e.FirstEditDate,
    e.LastEditDate,
    e.EditCount,
    tt.Tag,
    tt.PostCount
FROM EditorStats e
JOIN TopTags tt ON e.EditCount > 5 
WHERE tt.TagRank <= 10 
ORDER BY e.EditCount DESC, tt.PostCount DESC;