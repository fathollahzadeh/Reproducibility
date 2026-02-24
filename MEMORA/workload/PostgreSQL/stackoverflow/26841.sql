WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(COALESCE(vs.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(vs.DownVotes, 0)) AS TotalDownVotes,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        (SELECT 
            p.Id,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Posts p
        LEFT JOIN 
            Votes v ON v.PostId = p.Id
        GROUP BY 
            p.Id) vs ON vs.Id = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
),
RankedTags AS (
    SELECT 
        TagName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalViews,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalViews DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        QuestionCount > 0  
)
SELECT 
    rt.TagName,
    rt.QuestionCount,
    rt.AnswerCount,
    rt.CommentCount,
    rt.TotalUpVotes,
    rt.TotalDownVotes,
    rt.TotalViews
FROM 
    RankedTags rt
WHERE 
    rt.TagRank <= 10  
ORDER BY 
    rt.TagRank;