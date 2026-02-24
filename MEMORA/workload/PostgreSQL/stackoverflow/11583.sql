
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostTypeMetrics AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Id, pt.Name
),
VoteMetrics AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (1, 4) THEN 1 ELSE 0 END) AS AcceptedVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    um.UserId,
    um.Reputation,
    um.TotalPosts,
    um.Questions,
    um.Answers,
    um.TotalViews AS UserTotalViews,
    um.AcceptedAnswers,
    ptm.PostTypeName,
    ptm.PostCount,
    ptm.TotalViews AS PostTypeTotalViews,
    ptm.TotalScore AS PostTypeTotalScore,
    vm.UpVotes,
    vm.DownVotes,
    vm.AcceptedVotes
FROM 
    UserMetrics um
JOIN 
    PostTypeMetrics ptm ON (um.Questions > 0 OR um.Answers > 0)
JOIN 
    VoteMetrics vm ON um.UserId = vm.PostId
ORDER BY 
    um.Reputation DESC, um.TotalPosts DESC;
