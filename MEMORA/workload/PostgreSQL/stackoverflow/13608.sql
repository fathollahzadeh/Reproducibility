WITH PostMetrics AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserMetrics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation,
        SUM(u.Views) AS TotalProfileViews
    FROM 
        Users u
),
VoteMetrics AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes
    FROM 
        Votes v
)

SELECT 
    pm.PostTypeId,
    pm.TotalPosts,
    pm.TotalViews,
    pm.TotalScore,
    pm.AverageScore,
    pm.UniqueAuthors,
    pm.TotalQuestions,
    pm.TotalAnswers,
    um.TotalUsers,
    um.AverageReputation,
    um.TotalProfileViews,
    vm.TotalVotes,
    vm.TotalUpVotes,
    vm.TotalDownVotes
FROM 
    PostMetrics pm,
    UserMetrics um,
    VoteMetrics vm
ORDER BY 
    pm.PostTypeId;