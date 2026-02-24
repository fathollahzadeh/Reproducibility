
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        Contributors,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.QuestionCount,
    pt.AnswerCount,
    pt.AvgReputation,
    pt.Contributors,
    COUNT(ph.Id) AS EditHistoryCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    PopularTags pt
LEFT JOIN 
    PostHistory ph ON ph.PostId IN (
        SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', pt.TagName, '%')
    )
WHERE 
    pt.TagRank <= 10
GROUP BY 
    pt.TagName, pt.PostCount, pt.QuestionCount, pt.AnswerCount, pt.AvgReputation, pt.Contributors, pt.TagRank
ORDER BY 
    pt.TagRank;
