
WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
), UserContributions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), TagPerformance AS (
    SELECT 
        tu.Tag,
        SUM(uc.QuestionsAsked) AS TotalQuestions,
        SUM(uc.TotalUpvotes) AS TotalUpvotes,
        SUM(uc.TotalDownvotes) AS TotalDownvotes,
        SUM(uc.AcceptedAnswers) AS AcceptedAnswers
    FROM 
        TagUsage tu
    JOIN 
        Posts p ON p.Tags LIKE '%' || tu.Tag || '%'
    JOIN 
        UserContributions uc ON p.OwnerUserId = uc.UserId
    GROUP BY 
        tu.Tag
), FinalBenchmark AS (
    SELECT 
        Tag, 
        TotalQuestions,
        TotalUpvotes,
        TotalDownvotes,
        AcceptedAnswers,
        CASE 
            WHEN TotalQuestions > 0 THEN 
                (CAST(TotalUpvotes AS FLOAT) / TotalQuestions) - (CAST(TotalDownvotes AS FLOAT) / TotalQuestions)
            ELSE 
                0
        END AS UpvoteNetRate
    FROM 
        TagPerformance
)

SELECT 
    Tag,
    TotalQuestions,
    TotalUpvotes,
    TotalDownvotes,
    AcceptedAnswers,
    UpvoteNetRate
FROM 
    FinalBenchmark
ORDER BY 
    UpvoteNetRate DESC
LIMIT 10;
