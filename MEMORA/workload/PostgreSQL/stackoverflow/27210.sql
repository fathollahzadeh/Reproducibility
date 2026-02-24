
WITH TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
),
TagDetails AS (
    SELECT 
        tt.TagId,
        tt.TagName,
        tt.PostCount,
        tt.QuestionCount,
        tt.AnswerCount,
        tt.AvgReputation,
        COALESCE(pht.RecentEdit, NULL) AS RecentEdit
    FROM 
        TopTags tt
    LEFT JOIN (
        SELECT 
            ph.PostId,
            MAX(ph.CreationDate) AS RecentEdit
        FROM 
            PostHistory ph
        GROUP BY 
            ph.PostId
    ) pht ON pht.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || tt.TagName || '%')
    WHERE 
        tt.TagRank <= 10
)
SELECT 
    td.TagName,
    td.PostCount,
    td.QuestionCount,
    td.AnswerCount,
    td.AvgReputation,
    td.RecentEdit
FROM 
    TagDetails td
ORDER BY 
    td.PostCount DESC;
