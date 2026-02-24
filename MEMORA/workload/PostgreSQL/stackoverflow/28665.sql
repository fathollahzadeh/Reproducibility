
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1  
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(*) AS QuestionAnswered,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId = 2  
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalScore DESC
    LIMIT 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        P.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes P ON ph.PostHistoryTypeId = P.Id
    WHERE ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days' 
    ORDER BY ph.CreationDate DESC
    LIMIT 10
)

SELECT 
    t.TagName,
    t.PostCount,
    u.UserName,
    u.QuestionAnswered,
    u.TotalScore,
    r.CreationDate,
    r.PostHistoryType
FROM TopTags t
JOIN TopUsers u ON u.QuestionAnswered >= (SELECT MAX(PostCount) FROM TopTags)
JOIN RecentPostHistory r ON r.PostId IN (
    SELECT Id FROM Posts WHERE Tags ILIKE '%' || t.TagName || '%'
)
ORDER BY t.PostCount DESC, u.TotalScore DESC;
