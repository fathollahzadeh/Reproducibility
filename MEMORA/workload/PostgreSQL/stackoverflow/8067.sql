
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), AverageStats AS (
    SELECT 
        AVG(TotalPosts) AS AvgTotalPosts,
        AVG(TotalQuestions) AS AvgTotalQuestions,
        AVG(TotalAnswers) AS AvgTotalAnswers,
        AVG(TotalTagWikis) AS AvgTotalTagWikis,
        AVG(TotalViews) AS AvgTotalViews,
        AVG(TotalUpvotes) AS AvgTotalUpvotes,
        AVG(TotalDownvotes) AS AvgTotalDownvotes
    FROM 
        UserPostStats
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalTagWikis,
    ups.TotalViews,
    ups.TotalUpvotes,
    ups.TotalDownvotes,
    (ups.TotalPosts - a.AvgTotalPosts) AS PostsDifference,
    (ups.TotalQuestions - a.AvgTotalQuestions) AS QuestionsDifference,
    (ups.TotalAnswers - a.AvgTotalAnswers) AS AnswersDifference,
    (ups.TotalTagWikis - a.AvgTotalTagWikis) AS TagWikisDifference,
    (ups.TotalViews - a.AvgTotalViews) AS ViewsDifference,
    (ups.TotalUpvotes - a.AvgTotalUpvotes) AS UpvotesDifference,
    (ups.TotalDownvotes - a.AvgTotalDownvotes) AS DownvotesDifference
FROM 
    UserPostStats ups
CROSS JOIN 
    AverageStats a
ORDER BY 
    ups.TotalPosts DESC
LIMIT 10;
