WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'  
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
RankingTags AS (
    SELECT 
        TagName,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        AvgUserReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalUpVotes - TotalDownVotes DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    rt.TagName,
    rt.PostCount,
    rt.AnswerCount,
    rt.QuestionCount,
    rt.TotalUpVotes,
    rt.TotalDownVotes,
    rt.AvgUserReputation,
    CASE 
        WHEN rt.Rank <= 10 THEN 'Top Tag'
        WHEN rt.Rank <= 20 THEN 'Mid Tag'
        ELSE 'Low Tag'
    END AS TagRankCategory
FROM 
    RankingTags rt
ORDER BY 
    rt.Rank;