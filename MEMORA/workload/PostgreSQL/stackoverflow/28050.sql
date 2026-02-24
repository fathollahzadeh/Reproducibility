
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS Author,
        p.Tags,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagSummary AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS QuestionCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')))
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM 
        TagSummary
    WHERE 
        QuestionCount > 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        p.Title AS PostTitle,
        p.Score,
        p.Tags,
        PHT.Name AS ChangeType,
        ph.Text AS ChangeDescription
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
),
AggregatedChanges AS (
    SELECT 
        PostId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(DISTINCT ChangeType || ': ' || ChangeDescription, '; ') AS Changes
    FROM 
        RecentPostHistory
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.Tags,
    rp.Score,
    tt.TagName,
    ag.ChangeCount,
    ag.Changes
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%') 
LEFT JOIN 
    AggregatedChanges ag ON rp.PostId = ag.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    tt.QuestionCount DESC, rp.Score DESC;
