
WITH TagFrequencies AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    WHERE PostTypeId = 1  
    GROUP BY TagName
),
TopTags AS (
    SELECT
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM TagFrequencies
),
PopularUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId IN (1, 2) 
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM PopularUsers
),
RecentActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Comment AS EditComment
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    ORDER BY ph.CreationDate DESC
)
SELECT
    t.TagName,
    t.TagCount,
    u.DisplayName AS PopularUser,
    u.TotalViews,
    u.TotalScore,
    r.PostId,
    r.Title AS RecentPostTitle,
    r.CreationDate AS PostCreationDate,
    r.EditDate AS LastEditDate,
    r.Editor AS LastEditor,
    r.EditComment
FROM TopTags t
JOIN TopUsers u ON u.Rank <= 10  
JOIN RecentActivity r ON r.EditDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
WHERE t.Rank <= 10  
ORDER BY t.TagCount DESC, u.TotalViews DESC, r.EditDate DESC;
