
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        AcceptedAnswers,
        UpVotes,
        DownVotes,
        CommentsCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentsCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
    ORDER BY 
        VoteCount DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.AcceptedAnswers,
    tu.UpVotes,
    tu.DownVotes,
    tu.CommentsCount,
    tq.Title AS TopQuestionTitle,
    tq.ViewCount AS TopQuestionViews,
    tq.Score AS TopQuestionScore
FROM 
    TopUsers tu
CROSS JOIN 
    TopQuestions tq
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalPosts DESC;
