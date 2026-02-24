
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS RankByUpVotes
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.TotalViews,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.RankByViews,
    u.RankByUpVotes,
    CASE 
        WHEN u.RankByViews <= 10 THEN 'Top 10 by Views'
        ELSE 'Below Top 10 by Views' 
    END AS ViewsRanking,
    CASE 
        WHEN u.RankByUpVotes <= 10 THEN 'Top 10 by Upvotes'
        ELSE 'Below Top 10 by Upvotes' 
    END AS UpVotesRanking
FROM 
    TopUsers u
WHERE 
    u.QuestionCount > 5 AND u.TotalUpVotes > 10
ORDER BY 
    u.TotalViews DESC, u.TotalUpVotes DESC;
