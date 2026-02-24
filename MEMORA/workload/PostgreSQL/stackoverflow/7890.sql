
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswersToQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalAnswersToQuestions,
        TotalUpvotes,
        TotalDownvotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalUpvotes DESC) AS UpvoteRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalAnswersToQuestions,
    TotalUpvotes,
    TotalDownvotes,
    PostRank,
    UpvoteRank,
    CASE 
        WHEN PostRank = 1 AND UpvoteRank = 1 THEN 'Top Contributor'
        WHEN PostRank <= 10 THEN 'Top Posts Contributor'
        WHEN UpvoteRank <= 10 THEN 'Top Voted Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorLevel
FROM 
    TopUsers
WHERE 
    TotalPosts > 10
ORDER BY 
    PostRank, UpvoteRank;
