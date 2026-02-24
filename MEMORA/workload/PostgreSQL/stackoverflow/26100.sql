
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        COUNT(a.Id) AS AnswerCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, pt.Name, u.DisplayName, u.Reputation, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        PostType,
        OwnerName,
        OwnerReputation,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 
),
PostSummaries AS (
    SELECT 
        f.OwnerName,
        f.OwnerReputation,
        COUNT(f.PostId) AS TotalQuestions,
        SUM(f.AnswerCount) AS TotalAnswers,
        SUM(f.UpVotes) AS TotalUpVotes,
        SUM(f.DownVotes) AS TotalDownVotes
    FROM 
        FilteredPosts f
    GROUP BY 
        f.OwnerName, f.OwnerReputation
)
SELECT 
    ps.OwnerName, 
    ps.OwnerReputation,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    CASE 
        WHEN ps.TotalQuestions > 0 THEN ROUND(CAST(ps.TotalAnswers AS numeric) / ps.TotalQuestions, 2)
        ELSE 0 
    END AS AverageAnswersPerQuestion,
    CASE 
        WHEN ps.TotalUpVotes + ps.TotalDownVotes > 0 THEN ROUND(CAST(ps.TotalUpVotes AS numeric) / (ps.TotalUpVotes + ps.TotalDownVotes), 2)
        ELSE 0 
    END AS UpvotePercentage
FROM 
    PostSummaries ps
ORDER BY 
    ps.TotalUpVotes DESC
LIMIT 10;
