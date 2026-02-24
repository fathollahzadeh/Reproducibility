WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.OwnerDisplayName, ', ') AS Contributors,
        MAX(p.CreationDate) AS LastPostDate,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        Contributors,
        LastPostDate,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        Contributors,
        LastPostDate,
        QuestionCount,
        AnswerCount
    FROM 
        TopTags
    WHERE 
        Rank <= 10
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.Contributors,
    pt.LastPostDate,
    pt.QuestionCount,
    pt.AnswerCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || pt.TagName || '%')) AS TotalVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags LIKE '%' || pt.TagName || '%')) AS TotalBadgeHolders
FROM 
    PopularTags pt
ORDER BY 
    pt.PostCount DESC;
